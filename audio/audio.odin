#+vet explicit-allocators shadowing
package raven_audio

import "../base"
import "base:intrinsics"
import "base:runtime"
import "wav"
// import "qoa"

// TODO: sound fading
// TODO: sound trim range for dynamically chopping big sounds

BACKEND :: #config(AUDIO_BACKEND, BACKEND_DEFAULT)

when ODIN_OS == .Windows {
    BACKEND_DEFAULT :: BACKEND_WASAPI
} else {
    BACKEND_DEFAULT :: BACKEND_NONE
}

MAX_SOUNDS :: #config(AUDIO_MAX_SOUNDS, 1024)
MAX_RESOURCES :: #config(AUDIO_MAX_RESOURCE, 512)

Handle_Index :: u16
Handle_Gen :: u8

// Zero value means invalid handle
Handle :: struct {
    index:  u16,
    gen:    u8,
}

Resource_Handle :: distinct Handle
Sound_Handle :: distinct Handle

_state: ^State

State :: struct #align(64) {
    using native:       _State,
    running:            bool,
    init_context:       runtime.Context,
    sample_rate:        u32,

    mixer_proc:         Generator_Proc,

    resources_used:     base.Bit_Pool(MAX_RESOURCES),
    resources_gen:      [MAX_RESOURCES]Handle_Gen,
    resources:          [MAX_RESOURCES]Resource,

    sounds_used:        base.Bit_Pool(MAX_SOUNDS),
    sounds_gen:         [MAX_SOUNDS]Handle_Gen,
    sounds:             [MAX_SOUNDS]Sound,
}

Generator_Proc :: #type proc(buf: []f32, sample_rate: int)

// Represents the sample data.
Resource :: struct {
    data:           []byte,
    samples:        []byte,
    data_format:    Resource_Format,
    sample_format:  Resource_Format,
    flags:          bit_set[Resource_Flag],
    sample_rate:    u32, // hz
}

Resource_Flag :: enum u8 {
    Mono,
}

Resource_Format :: enum u8 {
    Invalid = 0,
    Raw_F32,
    Raw_I16,
    Raw_U8,
    WAV,
}

Sound :: struct {
    time:           f64,
    data_offset:    u32,
    resource:       Resource_Handle,
    flags:          bit_set[Sound_Flag],
    params:         [Sound_Param]Param_Data,
}

Sound_Flag :: enum u8 {
    Loop,
}

Sound_Param :: enum u8 {
    Volume,
    Pitch,
}

Param_Data :: struct {
    val:    f32,
    target: f32,
    smooth: f32,
}

Listener :: struct {
    param_val:      [Listener_Param]#simd[4]f32,
    param_target:   [Listener_Param]#simd[4]f32,
    param_smooth:   [Listener_Param]#simd[4]f32,
}

Listener_Param :: enum u8 {
    Pos,
    Vel,
    Ear,
}

// MARK: Core

set_state_ptr :: proc(state: ^State) {
    _state = state
}

get_state_ptr :: proc() -> (state: ^State) {
    return _state
}

init :: proc(state: ^State) -> bool {
    if _state != nil {
        return true
    }

    _state = state

    base.bit_pool_set_1(&_state.resources_used, 0)
    base.bit_pool_set_1(&_state.sounds_used, 0)

    _state.init_context = context
    _state.running = true

    set_mixer(default_mixer_generator_proc)

    if !_init() {
        return false
    }

    return true
}

shutdown :: proc() {
    if _state == nil {
        return
    }

    _shutdown()

    _state = nil
}

// Call every frame from the main thread.
// Low overhead, audio is in another thread.
update :: proc() {
}

set_mixer :: proc(mixer: Generator_Proc) {
    intrinsics.atomic_store(&_state.mixer_proc, mixer)
}


// MARK: Sounds

create_resource :: proc(
    format:         Resource_Format,
    data:           []byte,
    flags:          bit_set[Resource_Flag] = {},
    sample_rate:    u32 = 0,
) -> (result: Resource_Handle, ok: bool) {
    assert(format != .Invalid)

    index := base.bit_pool_find_0(_state.resources_used) or_return

    result = {
        index = Handle_Index(index),
        gen = _state.resources_gen[index],
    }

    resource := &_state.resources[index]
    resource^ = {
        data = data,
        data_format = format,
        sample_rate = sample_rate,
        flags = flags,
    }

    switch format {
    case .Invalid:
        assert(false)
        return

    case .Raw_F32, .Raw_I16, .Raw_U8:
        assert(sample_rate != 0)

        resource.sample_format = format
        resource.samples = data

    case .WAV:
        header, samples, header_ok := wav.decode(data, context.allocator)
        if !header_ok {
            return {}, false
        }

        resource.sample_format = .Raw_F32
        resource.samples = to_bytes(samples)
        resource.sample_rate = header.format.sample_rate

        base.log_dump(header)

        switch header.format.num_channels {
        case 1: resource.flags += {.Mono}
        case 2: resource.flags -= {.Mono}
        case:
            assert(false, "WAV files which don't have 1 or 2 channels aren't supported.")
            return {}, false
        }
    }

    base.log_dump(resource)

    assert(resource.sample_rate != 0)
    assert(resource.data_format != .Invalid)

    base.bit_pool_set_1(&_state.resources_used, index)

    return result, true
}

// NOTE: created sound is stopped by default
create_sound :: proc(
    resource_handle:    Resource_Handle,
    flags:              bit_set[Sound_Flag] = {},
) -> (result: Sound_Handle, ok: bool) {
    index := base.bit_pool_find_0(_state.sounds_used) or_return

    _, res_ok := get_internal_resource(resource_handle)
    assert(res_ok)

    sound := &_state.sounds[index]
    sound^ = {
        resource = resource_handle,
        data_offset = 0,
        flags = flags,
    }

    result = {
        index = Handle_Index(index),
        gen = _state.sounds_gen[index],
    }

    base.bit_pool_set_1(&_state.sounds_used, index)

    return result, true
}

destroy_sound :: proc(handle: Sound_Handle) -> bool {
    assert(base.bit_pool_check_1(_state.sounds_used, handle.index))
    base.bit_pool_set_0(&_state.sounds_used, handle.index)
    _state.sounds_gen[handle.index] += 1
    return true
}


get_internal_resource :: proc(handle: Resource_Handle) -> (^Resource, bool) {
    if handle.index <= 0 || handle.index >= MAX_RESOURCES {
        return nil, false
    }

    resource := &_state.resources[handle.index]
    if _state.resources_gen[handle.index] != handle.gen {
        return nil, false
    }

    return resource, true
}

get_internal_sound :: proc(handle: Sound_Handle) -> (^Sound, bool) {
    if handle.index <= 0 || handle.index >= MAX_SOUNDS {
        return nil, false
    }

    sound := &_state.sounds[handle.index]
    if _state.sounds_gen[handle.index] != handle.gen {
        return nil, false
    }

    return sound, true
}


// MARK: Internal

default_mixer_generator_proc :: proc(buf: []f32, sample_rate: int) {
    assert(len(buf) % 2 == 0)

    for sound_index in 1..<MAX_SOUNDS {
        if !base.bit_pool_check_1(_state.sounds_used, sound_index) {
            continue
        }

        sound := &_state.sounds[sound_index]

        resource, resource_ok := get_internal_resource(sound.resource)
        assert(resource_ok)

        num_channels := .Mono in resource.flags ? 1 : 2

        time := sound.time
        delta := f64(resource.sample_rate) / f64(sample_rate)

        num_frames := len(buf)

        switch resource.sample_format {
        case .Invalid, .WAV:
            assert(false)

        case .Raw_F32:
            data := reinterpret_bytes(f32, resource.samples)

            num_frames = min(len(buf), len(data) - (int(time) + len(buf) * (int(delta) + 1)))

            if u32(sample_rate) > resource.sample_rate {
                // Upsample - Interpolate.
                // TODO: sinc interpolation

                assert(delta < 1)

                for i in 0..<num_frames {
                    t := time + delta * f64(i)
                    frame := int(time)
                    fract := f32(time - f64(frame))
                    val0 := data[(frame + 0)]
                    val1 := data[(frame + 1)]
                    val := val0 * (1 - fract) + val1 * fract
                    buf[i / 2 + 0] += val
                    buf[i / 2 + 1] += val
                    time += delta
                }

            } else if u32(sample_rate) < resource.sample_rate {
                // Downsample
                // Dumb impl has aliasing issues.
                // TODO: lowpass?

                assert(delta > 1)

                for i in 0..<num_frames {
                    frame := int(time + delta * f64(i))
                    buf[i] += data[frame]
                }

            } else {
                // Fast direct path

                for i in 0..<num_frames {
                    buf[i] += data[i]
                }
                time += delta * f64(len(buf))
            }

        case .Raw_I16:

        case .Raw_U8:
        }

        sound.time = time
    }
}


@(require_results)
reinterpret_bytes :: proc "contextless" ($T: typeid, bytes: []byte) -> []T {
    n := len(bytes) / size_of(T)
    assert_contextless(n * size_of(T) == len(bytes))
    return ([^]T)(raw_data(bytes))[:n]
}

@(require_results)
to_bytes :: proc "contextless" (data: []$T) -> []byte {
    return (cast([^]byte)raw_data(data))[:size_of(T) * len(data)]
}
