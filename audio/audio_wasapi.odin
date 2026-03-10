#+build windows
package raven_audio

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
    _Group :: struct {}
    _Delay_Filter :: struct {}

    _shutdown :: proc() {}

    @(require_results) _get_global_time :: proc() -> u64 { return 0 }
    @(require_results) _get_output_sample_rate :: proc() -> u32 { return 0 }
    _set_listener_transform :: proc(pos: [3]f32, forw: [3]f32, vel: [3]f32) {}

    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    // MARK: Sound
    //

    @(require_results) _init_resource_decoded :: proc(resource: ^Resource, handle: Resource_Handle, data: []byte, format: Sample_Format, stereo: bool, sample_rate: u32) -> bool { return true }
    @(require_results) _init_resource_encoded :: proc(resource: ^Resource, handle: Resource_Handle,  data: []byte) -> bool { return true }
    @(require_results) _init_sound :: proc(sound: ^Sound, resource_handle: Resource_Handle, async_decode: bool, group_handle: Group_Handle) -> bool { return true }
    @(require_results) _is_sound_playing :: proc(sound: ^Sound) -> bool { return true }
    @(require_results) _is_sound_finished :: proc(sound: ^Sound) -> bool { return true }
    @(require_results) _get_sound_time :: proc(sound: ^Sound, units: Units) -> f32 { return 10000.0 }
    _destroy_sound :: proc(sound: ^Sound) {}
    _set_sound_volume :: proc(sound: ^Sound, factor: f32) {}
    _set_sound_pan :: proc(sound: ^Sound, pan: f32, mode: Pan_Mode) {}
    _set_sound_pitch :: proc(sound: ^Sound, pitch: f32) {}
    _set_sound_spatialization :: proc(sound: ^Sound, enabled: bool) {}
    _set_sound_position :: proc(sound: ^Sound, pos: [3]f32) {}
    _set_sound_direction :: proc(sound: ^Sound, dir: [3]f32) {}
    _set_sound_velocity :: proc(sound: ^Sound, vel: [3]f32) {}
    _set_sound_playing :: proc(sound: ^Sound, play: bool) {}
    _set_sound_looping :: proc(sound: ^Sound, val: bool) {}
    _set_sound_start_delay :: proc(sound: ^Sound, val: f32, units: Units) {}


    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    // MARK: Group
    //

    _init_group :: proc(group: ^Group, parent_handle: Group_Handle, delay: f32) {}
    _destroy_group :: proc(group: ^Group) {}
    _set_group_volume :: proc(group: ^Group, factor: f32) {}
    _set_group_pan :: proc(group: ^Group, pan: f32, mode: Pan_Mode) {}
    _set_group_pitch :: proc(group: ^Group, pitch: f32) {}
    _set_group_spatialization :: proc(group: ^Group, enabled: bool) {}
    _set_group_delay_decay :: proc(group: ^Group, decay: f32) {}
    _set_group_delay_wet :: proc(group: ^Group, wet: f32) {}
    _set_group_delay_dry :: proc(group: ^Group, dry: f32) {}

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

        return true
    }

    _wasapi_thread_routine :: proc "system" (_: rawptr) -> windows.DWORD {
        context = _state.init_context

        base.log_info("Audio Thread")

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

            samples := cast([^]f32)data_ptr

            for i in 0..<frames_available {
                sample := f32(math.sin(phase))
                samples[i * 2 + 0] = sample
                samples[i * 2 + 1] = sample
                phase += 2.0 * 3.1415 * 440.0 / 48000.0
                if phase > 2.0 * 3.1415 do phase -= 2.0 * 3.1415
            }

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