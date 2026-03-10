#+build windows
package raven_audio

import "../base"

import "wasapi"
import "core:sys/windows"

BACKEND_WASAPI :: "WASAPI"

when BACKEND == BACKEND_WASAPI {

    _State :: struct {
        thread:         windows.HANDLE,
        audio_client:   ^wasapi.IAudioClient,
        render_client:  ^wasapi.IRenderClient,
        buffer_event:   windows.HANDLE,
    }

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

        _wasapi_check(device->Activate(wasapi.IID_IAudioClient, windows.CLSCTX_ALL, nil, cast(^rawptr)(&_state.audio_client)))

        device_format: ^wasapi.WAVEFORMATEX
        _wasapi_check(_state.audio_client->GetMixFormat(&device_format))

        windows.CoTaskMemFree(device_format)

        // Define f32 Stereo Format
        wfx: wasapi.WAVEFORMATEXTENSIBLE
        wfx.Format.wFormatTag      = .EXTENSIBLE
        wfx.Format.nChannels       = 2
        wfx.Format.nSamplesPerSec  = SAMPLE_RATE
        wfx.Format.wBitsPerSample  = 32
        wfx.Format.nBlockAlign     = (wfx.Format.nChannels * wfx.Format.wBitsPerSample) / 8
        wfx.Format.nAvgBytesPerSec = wfx.Format.nSamplesPerSec * u32(wfx.Format.nBlockAlign)
        wfx.Format.cbSize          = size_of(wasapi.WAVEFORMATEXTENSIBLE) - size_of(wasapi.WAVEFORMATEX)

        wfx.Samples.wValidBitsPerSample = 32
        wfx.dwChannelMask               = {.FRONT_LEFT, .FRONT_RIGHT}
        wfx.SubFormat                   = wasapi.KSDATAFORMAT_SUBTYPE_IEEE_FLOAT

        buffer_duration: wasapi.REFERENCE_TIME = 10000000 / 10 // 100ms
        _wasapi_check(_state.audio_client->Initialize(
            .SHARED,
            u32(wasapi.AUDCLNT_FLAG.STREAM_EVENTCALLBACK),
            buffer_duration,
            0,
            cast(^wasapi.WAVEFORMATEX)&wfx,
            nil,
        ))

        _state.buffer_event = windows.CreateEventW(nil, false, false, nil)
        _wasapi_check(_state.audio_client->SetEventHandle(_state.buffer_event))

        render_client: ^wasapi.IAudioRenderClient
        _wasapi_check(_state.audio_client->GetService(wasapi.IID_IAudioRenderClient, (^rawptr)(&render_client)))

        buffer_frame_count: u32
        _wasapi_check(_state.audio_client->GetBufferSize(&buffer_frame_count))
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

        return true
    }

    _wasapi_thread_routine :: proc "system" (param: rawptr) -> windows.DWORD {
        for _state.running {
            // Wait for WASAPI to tell us it needs more data
            windows.WaitForSingleObject(_state.buffer_event, windows.INFINITE)

            padding: u32
            _wasapi_check(_state.audio_client->GetCurrentPadding(&padding))
            frames_available := buffer_frame_count - padding

            if frames_available == 0 {
                continue
            }

            data_ptr: [^]byte
            _wasapi_check(_state.render_client->GetBuffer(frames_available, &data_ptr))

            samples := cast([^]f32)data_ptr

            for i in 0..<frames_available {
                // sample := f32(math.sin(phase))
                // samples[i * 2]     = sample // Left
                // samples[i * 2 + 1] = sample // Right
                // phase += 2.0 * PI * FREQ / SAMPLE_RATE
                // if phase > 2.0 * PI do phase -= 2.0 * PI
            }

            _wasapi_check(render_client->ReleaseBuffer(frames_available, 0))
        }

        return 0
    }

    _wasapi_check :: proc(hr: windows.HRESULT, expr := #caller_expression, loc := #caller_location) {
        if !windows.SUCCEEDED(hr) {
            base.log_err("WASAPI Error: %x", transmute(u32)hr)
            assert(false, message = expr, loc = loc)
        }
    }
}