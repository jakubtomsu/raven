#+build windows
package raven_audio

import "base:intrinsics"
import "../base"

import "wasapi"
import "core:sys/windows"
import "core:math"

BACKEND_WASAPI :: "WASAPI"

when BACKEND == BACKEND_WASAPI {

    _State :: struct {
        thread:             windows.HANDLE,
        audio_client:       ^wasapi.IAudioClient,
        render_client:      ^wasapi.IAudioRenderClient,
        buffer_event:       windows.HANDLE,
        buffer_frame_num:   u32,
    }

    _Sound :: struct {}
    _Resource :: struct {}

    _shutdown :: proc() {}

    @(require_results)
    _init :: proc() -> bool {
        _wasapi_check(windows.CoInitializeEx(nil, .MULTITHREADED))

        enumerator: ^wasapi.IMMDeviceEnumerator
        _wasapi_check(windows.CoCreateInstance(
            wasapi.CLSID_MMDeviceEnumerator,
            nil,
            windows.CLSCTX_ALL,
            wasapi.IID_IMMDeviceEnumerator,
            (^rawptr)(&enumerator),
        ))

        device: ^wasapi.IMMDevice
        _wasapi_check(enumerator->GetDefaultAudioEndpoint(.Render, .Console, &device))

        _wasapi_check(device->Activate(wasapi.IID_IAudioClient, windows.CLSCTX_ALL, nil, cast(^rawptr)&_state.audio_client))

        device_format: ^wasapi.WAVEFORMATEX
        _wasapi_check(_state.audio_client->GetMixFormat(&device_format))

        // windows.CoTaskMemFree(device_format)
        SAMPLE_RATE :: 44100

        assert(device_format.wFormatTag == .EXTENSIBLE)

        format := (cast(^wasapi.WAVEFORMATEXTENSIBLE)device_format)^

        format.Samples.wValidBitsPerSample = 32
        format.dwChannelMask = {.FRONT_LEFT, .FRONT_RIGHT}
        format.SubFormat = wasapi.KSDATAFORMAT_SUBTYPE_IEEE_FLOAT

        _state.sample_rate = u32(format.Format.nSamplesPerSec)

        buffer_duration: wasapi.REFERENCE_TIME = 1000000 / 10 // 100ms
        _wasapi_check(_state.audio_client->Initialize(
            .SHARED,
            u32(wasapi.AUDCLNT_FLAG.STREAM_EVENTCALLBACK),
            buffer_duration,
            0,
            cast(^wasapi.WAVEFORMATEX)&format,
            nil,
        ))

        _state.buffer_event = windows.CreateEventW(nil, false, false, nil)
        _wasapi_check(_state.audio_client->SetEventHandle(_state.buffer_event))

        _wasapi_check(_state.audio_client->GetService(wasapi.IID_IAudioRenderClient, cast(^rawptr)&_state.render_client))

        _wasapi_check(_state.audio_client->GetBufferSize(&_state.buffer_frame_num))
        _wasapi_check(_state.audio_client->Start())

        _state.thread = windows.CreateThread(
            lpThreadAttributes    = nil,
            dwStackSize           = 0,
            lpStartAddress        = _wasapi_thread_routine,
            lpParameter           = nil,
            dwCreationFlags       = 0,
            lpThreadId            = nil,
        )


        if _state.thread == nil {
            base.log_err("Failed to create thread.")
            return false
        }

        windows.SetThreadDescription(_state.thread, "Audio Thread")

        return true
    }

    _wasapi_thread_routine :: proc "system" (_: rawptr) -> windows.DWORD {
        context = _state.init_context

        phase: f32

        for _state.running {
            assert(_state != nil)

            windows.WaitForSingleObject(_state.buffer_event, windows.INFINITE)

            padding: u32
            _wasapi_check(_state.audio_client->GetCurrentPadding(&padding))
            frames_available := _state.buffer_frame_num - padding

            if frames_available == 0 {
                continue
            }

            data_ptr: [^]byte
            _wasapi_check(_state.render_client->GetBuffer(frames_available, &data_ptr))

            sample_buf := (cast([^]f32)data_ptr)[:frames_available]
            mixer_proc := intrinsics.atomic_load(&_state.mixer_proc)

            mixer_proc(sample_buf, sample_rate = int(_state.sample_rate))

            _wasapi_check(_state.render_client->ReleaseBuffer(frames_available, 0))
        }

        return 0
    }

    _wasapi_check :: proc(hr: windows.HRESULT, expr := #caller_expression, loc := #caller_location) {
        if !windows.SUCCEEDED(hr) {
            base.log_err("WASAPI Error: %v (%x)", transmute(wasapi.Result)hr, transmute(u32)hr)
            assert(false, message = expr, loc = loc)
        }
    }
}