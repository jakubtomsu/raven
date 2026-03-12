#+vet explicit-allocators shadowing
package raven_audio

// TODO: this package could be completely self contained, no base dependency.

import "core:math"
import "../base"
import "base:intrinsics"
import "base:runtime"
import "wav"
// import "qoa"

// TODO: sound fading
// TODO: sound trim range for dynamically chopping big sounds
// one pole filter

BACKEND :: #config(AUDIO_BACKEND, BACKEND_DEFAULT)

when ODIN_OS == .Windows {
    BACKEND_DEFAULT :: BACKEND_WASAPI
} else {
    BACKEND_DEFAULT :: BACKEND_NONE
}

SINGLE_THREAD :: #config(AUDIO_SINGLE_THREAD, false)

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
    frame_rate:         u32,

    master_mixer_proc:  Generator_Proc,

    listener_curr:      Listener,
    listener_prev:      Listener, // Audio thread access only

    resources_free:     SPSC(MAX_RESOURCES, Handle_Index),
    resources_state:    [MAX_RESOURCES]Slot_State,
    resources_gen:      [MAX_RESOURCES]Handle_Gen,
    resources:          [MAX_RESOURCES]Resource,

    sounds_free:        SPSC(MAX_SOUNDS, Handle_Index),
    sounds_state:       [MAX_SOUNDS]Slot_State,
    sounds_gen:         [MAX_SOUNDS]Handle_Gen,
    sounds:             [MAX_SOUNDS]Sound,
}

Generator_Proc :: #type proc(frames: [][2]f32, sample_rate: int)

// Atomic
Slot_State :: enum u32 {
    Free = 0,
    Used,
    Request_Free, // Always handled by audio thread
}

// Represents the sample data.
Resource :: struct {
    data:           []byte,
    samples:        []byte,
    data_format:    Resource_Format,
    sample_format:  Resource_Format,
    flags:          bit_set[Resource_Flag],
    frame_num:      u32,
    frame_rate:     u32, // hz
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
    frame:          f64,
    end_frame:      u32,
    resource:       Resource_Handle,
    flags:          bit_set[Sound_Flag],
    playing:        bool,

    volume:         Param(f32),
    pan:            Param(f32),
    pitch:          Param(f32),
    pos:            Param([3]f32),
}

Sound_Flag :: enum u8 {
    Loop,
    Spatial,
}

Param :: struct($T: typeid) {
    target: T, // Game thread
    curr:   T, // Audio thread
    delta:  f32, // Game thread
}

Listener :: struct {
    pos:    [3]f32,
    forw:   [3]f32,
    right:  [3]f32,
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

    _state.init_context = context
    _state.running = true

    for i in 1..<MAX_SOUNDS {
        spsc_push(&_state.sounds_free, Handle_Index(i))
    }

    for i in 1..<MAX_RESOURCES {
        spsc_push(&_state.resources_free, Handle_Index(i))
    }

    set_master_mixer(default_master_mixer)

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
    if SINGLE_THREAD {
        _update_output_buffer()
    }
}

set_master_mixer :: proc(mixer: Generator_Proc) {
    intrinsics.atomic_store(&_state.master_mixer_proc, mixer)
}

set_listener :: proc(
    pos:   [3]f32,
    forw:  [3]f32 = {0, 0, 1},
    right: [3]f32 = {1, 0, 0},
) {
    // This write isn't atomic as a whole, which could possibly result in small glitches
    // during very fast movement.
    intrinsics.atomic_store_explicit(&_state.listener_curr.pos.x, pos.x, .Release)
    intrinsics.atomic_store_explicit(&_state.listener_curr.pos.y, pos.y, .Release)
    intrinsics.atomic_store_explicit(&_state.listener_curr.pos.z, pos.z, .Release)
    intrinsics.atomic_store_explicit(&_state.listener_curr.forw.x, forw.x, .Release)
    intrinsics.atomic_store_explicit(&_state.listener_curr.forw.y, forw.y, .Release)
    intrinsics.atomic_store_explicit(&_state.listener_curr.forw.z, forw.z, .Release)
    intrinsics.atomic_store_explicit(&_state.listener_curr.right.x, right.x, .Release)
    intrinsics.atomic_store_explicit(&_state.listener_curr.right.y, right.y, .Release)
    intrinsics.atomic_store_explicit(&_state.listener_curr.right.z, right.z, .Release)
}


// MARK: Sounds

create_resource :: proc(
    format:         Resource_Format,
    data:           []byte,
    flags:          bit_set[Resource_Flag] = {},
    frame_rate:    u32 = 0,
) -> (result: Resource_Handle, ok: bool) {
    assert(format != .Invalid)

    index, index_ok := spsc_pop(&_state.resources_free)
    if !index_ok {
        base.log_err("No free sound resource slots")
        return {}, false
    }

    assert(intrinsics.atomic_load(&_state.resources_state[index]) == .Free)

    result = {
        index = index,
        gen = _state.resources_gen[index],
    }

    resource := &_state.resources[index]
    resource^ = {
        data = data,
        data_format = format,
        frame_rate = frame_rate,
        flags = flags,
    }

    num_channels: u32 = .Mono in flags ? 1 : 2

    switch format {
    case .Invalid:
        assert(false)
        return

    case .Raw_F32:
        assert(frame_rate != 0)
        assert(len(data) % size_of(f32) == 0)
        resource.sample_format = format
        resource.samples = data
        resource.frame_num = u32(len(data) / size_of(f32)) / num_channels

    case .Raw_I16:
        assert(frame_rate != 0)
        assert(len(data) % size_of(f32) == 0)
        resource.sample_format = format
        resource.samples = data
        resource.frame_num = u32(len(data) / size_of(i16)) / num_channels

    case .Raw_U8:
        assert(frame_rate != 0)
        assert(len(data) % size_of(f32) == 0)
        resource.sample_format = format
        resource.samples = data
        resource.frame_num = u32(len(data) / size_of(u8)) / num_channels

    case .WAV:
        header, samples, header_ok := wav.decode(data, context.allocator)
        if !header_ok {
            return {}, false
        }

        resource.sample_format = .Raw_F32
        resource.samples = to_bytes(samples)
        resource.frame_rate = header.format.sample_rate
        resource.frame_num = u32(len(samples)) / u32(header.format.num_channels)

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

    assert(resource.frame_rate != 0)
    assert(resource.data_format != .Invalid)

    intrinsics.atomic_store(&_state.resources_state[index], .Used)

    return result, true
}

// NOTE: created sound is stopped by default
create_sound :: proc(
    resource_handle:    Resource_Handle,
    flags:              bit_set[Sound_Flag] = {},
    pitch:              f32 = 1.0,
    pan:                f32 = 0,
    volume:             f32 = 1,
) -> (result: Sound_Handle, ok: bool) {
    index, index_ok := spsc_pop(&_state.sounds_free)
    if !index_ok {
        base.log_err("No free sound slots")
        return {}, false
    }

    assert(intrinsics.atomic_load(&_state.sounds_state[index]) == .Free)

    res, res_ok := _get_resource(resource_handle)
    assert(res_ok)

    result = {
        index = index,
        gen = _state.sounds_gen[index],
    }

    sound := &_state.sounds[index]
    sound^ = {
        resource = resource_handle,
        flags = flags,
        pitch = {target = pitch, curr = pitch, delta = 1},
        end_frame = res.frame_num,
        volume = {target = volume, curr = volume, delta = 1},
        pan = {target = pan, curr = pan, delta = 1},
    }

    intrinsics.atomic_store(&_state.sounds_state[index], .Used)

    return result, true
}

destroy_resource :: proc(handle: Resource_Handle) -> bool {
    if !is_resource_valid(handle) {
        return false
    }
    intrinsics.atomic_store(&_state.resources_state[handle.index], .Request_Free)
    return true
}

destroy_sound :: proc(handle: Sound_Handle) -> bool {
    if !is_sound_valid(handle) {
        return false
    }
    intrinsics.atomic_store(&_state.sounds_state[handle.index], .Request_Free)
    return true
}

get_sound_time :: proc(handle: Sound_Handle) -> f32 {
    sound, ok := _get_sound(handle)
    if !ok {
        return 0
    }
    return f32(sound.frame)
}


is_sound_playing :: proc(handle: Sound_Handle) -> bool {
    sound, ok := _get_sound(handle)
    if !ok {
        return false
    }
    return true
}

is_resource_valid :: proc(handle: Resource_Handle) -> bool {
    if handle.index <= 0 || handle.index >= MAX_RESOURCES {
        return false
    }

    if _state.resources_gen[handle.index] != handle.gen {
        return false
    }

    if intrinsics.atomic_load(&_state.resources_state[handle.index]) != .Used {
        return false
    }

    return true
}

is_sound_valid :: proc(handle: Sound_Handle) -> bool {
    if handle.index <= 0 || handle.index >= MAX_SOUNDS {
        return false
    }

    if _state.sounds_gen[handle.index] != handle.gen {
        return false
    }

    if intrinsics.atomic_load(&_state.sounds_state[handle.index]) != .Used {
        return false
    }

    return true
}

_get_resource :: proc(handle: Resource_Handle) -> (^Resource, bool) {
    if !is_resource_valid(handle) {
        return nil, false
    }
    return &_state.resources[handle.index], true
}

_get_sound :: proc(handle: Sound_Handle) -> (^Sound, bool) {
    if !is_sound_valid(handle) {
        return nil, false
    }
    return &_state.sounds[handle.index], true
}


// MARK: Internal

LANES :: 16
SCRATCH_BUFFER_SIZE :: 1024 * 2

default_master_mixer :: proc(frame_buf: [][2]f32, frame_rate: int) {
    base.log_info("Mix")

    _scratch: [SCRATCH_BUFFER_SIZE][2]f32
    scratch := _scratch[:len(frame_buf)]

    listener_prev := _state.listener_prev

    listener_pos := [3]f32{
        intrinsics.atomic_load_explicit(&_state.listener_curr.pos.x, .Acquire),
        intrinsics.atomic_load_explicit(&_state.listener_curr.pos.y, .Acquire),
        intrinsics.atomic_load_explicit(&_state.listener_curr.pos.z, .Acquire),
    }

    listener_forw := [3]f32{
        intrinsics.atomic_load_explicit(&_state.listener_curr.forw.x, .Acquire),
        intrinsics.atomic_load_explicit(&_state.listener_curr.forw.y, .Acquire),
        intrinsics.atomic_load_explicit(&_state.listener_curr.forw.z, .Acquire),
    }

    listener_right := [3]f32{
        intrinsics.atomic_load_explicit(&_state.listener_curr.right.x, .Acquire),
        intrinsics.atomic_load_explicit(&_state.listener_curr.right.y, .Acquire),
        intrinsics.atomic_load_explicit(&_state.listener_curr.right.z, .Acquire),
    }

    _state.listener_prev = {
        pos = listener_pos,
        forw = listener_forw,
        right = listener_right,
    }


    sound_loop: for sound_index in 1..<MAX_SOUNDS {
        switch intrinsics.atomic_load_explicit(&_state.sounds_state[sound_index], .Acquire) {
        case .Request_Free:
            _free_sound(sound_index)
            continue sound_loop
        case .Free:
            continue sound_loop

        case .Used:
        }

        sound := &_state.sounds[sound_index]

        resource, resource_ok := _get_resource(sound.resource)
        assert(resource_ok)

        destroy := false

        // Dynamic pitch
        // Doppler pitch
        // Lowpass muddy filter (one pole)
        // Delay, Convolution?
        // Cone filter spatialization
        // Panning

        // - fill scratch with base signal & pitch
        // - apply filters one by one
        // - final mix (pan, volume)

        // num_buf_frames := len(frame_buf)
        // smooth_delta := f32(num_buf_frames) / f32(frame_rate)
        // volume := intrinsics.atomic_load(&sound.params[.Volume].curr)
        // volume_target := intrinsics.atomic_load(&sound.params[.Volume].target)
        // volume_delta := smooth_delta * intrinsics.atomic_load(&sound.params[.Volume].delta)
        // intrinsics.atomic_store(&sound.params[.Volume].curr, volume)

        delta_seconds := f32(resource.frame_rate) / f32(frame_rate)

        pitch_range := update_param(&sound.pitch, delta_seconds)
        volume_range := update_param(&sound.volume, delta_seconds)
        pan_range := update_param(&sound.pan, delta_seconds)

        end_time := sample_base_signal(
            frame_buf = scratch,
            sample_bytes = resource.samples,
            sample_format = resource.sample_format,
            mono = .Mono in resource.flags,
            time = sound.frame,
            delta_range = pitch_range * delta_seconds,
            loop = .Loop in sound.flags,
        )

        sound.frame = end_time

        if .Loop not_in sound.flags && int(sound.frame) > int(resource.frame_num) {
            destroy = true
        }

        inv_frames := 1.0 / f32(len(frame_buf))

        for frame, i in scratch {
            block_t := f32(i) * inv_frames
            volume := lerp(volume_range[0], volume_range[1], block_t)
            pan := lerp(pan_range[0], pan_range[1], block_t)

            val := frame

            val *= volume

            // Pan/Balance:
            // -1 = hard left, L=1, R=0
            // 0 = center, L^2 + R^2 = ~1
            // 1 = hard right, L=0, R=1
            //
            // Polynomial approximation
            // https://www.desmos.com/calculator/rrnaswgquf

            pan_half := pan * 0.5
            val.x *= 1.0 - (pan_half + 0.5) * (pan_half + 0.5)
            val.y *= 1.0 - (pan_half - 0.5) * (pan_half - 0.5)
            val *= 1.0 / 1.06066017178 // sqrt(1.125)

            frame_buf[i] += val
        }

        if destroy {
            _free_sound(sound_index)
        }
    }

    return

    _free_sound :: proc(sound_index: int) {
        intrinsics.atomic_store(&_state.sounds_state[sound_index], .Free)
        spsc_push(&_state.sounds_free, Handle_Index(sound_index))
    }
}

// Interpolated, Stereo/Mono
sample_base_signal :: proc(
    frame_buf:      [][2]f32,
    sample_bytes:   []byte,
    sample_format:  Resource_Format,
    mono:           bool,
    time:           f64,
    delta_range:    [2]f32,
    loop:           bool,
) -> f64 {
    time := time

    inv_frames := 1.0 / f32(len(frame_buf))

    switch sample_format {
    case .Invalid, .WAV:
        assert(false)

    case .Raw_F32:
        samples := reinterpret_bytes(f32, sample_bytes)
        if mono {
            time = _sample_signal(f32, Mono = true, samples = samples, frame_buf = frame_buf, time = time, delta_range = delta_range, loop = loop)
        } else {
            time = _sample_signal(f32, Mono = false, samples = samples, frame_buf = frame_buf, time = time, delta_range = delta_range, loop = loop)
        }

    case .Raw_I16:
        samples := reinterpret_bytes(i16, sample_bytes)
        if mono {
            time = _sample_signal(i16, Mono = true, samples = samples, frame_buf = frame_buf, time = time, delta_range = delta_range, loop = loop)
        } else {
            time = _sample_signal(i16, Mono = false, samples = samples, frame_buf = frame_buf, time = time, delta_range = delta_range, loop = loop)
        }

    case .Raw_U8:
        samples := reinterpret_bytes(u8, sample_bytes)
        if mono {
            time = _sample_signal(u8, Mono = true, samples = samples, frame_buf = frame_buf, time = time, delta_range = delta_range, loop = loop)
        } else {
            time = _sample_signal(u8, Mono = false, samples = samples, frame_buf = frame_buf, time = time, delta_range = delta_range, loop = loop)
        }
    }

    return time

    // TODO: accelerated method when sample rates match exactly and delta == 1
    _sample_signal :: proc(
        $T:             typeid,
        $Mono:          bool,
        samples:        []T,
        frame_buf:      [][2]f32,
        time:           f64,
        delta_range:    [2]f32,
        loop:           bool,
    ) -> f64 {
        time := time

        num_frames := len(samples)
        if !Mono {
            num_frames /= 2
        }

        inv_frames := 1.0 / f32(len(frame_buf))

        for i in 0..<len(frame_buf) {
            block_t := f32(i) * inv_frames

            frame_index := int(time)

            if loop {
                frame_index %= num_frames
            } else {
                frame_index = min(frame_index, num_frames - 3)
            }

            frame_t := f32(time - f64(frame_index))

            when Mono {
                mono := unpack_mono_samples(cast([^]T)&samples[frame_index])
                stereo := transmute([2][2]f32)mono.xyxy
            } else {
                interleaved_stereo := unpack_stereo_samples(cast([^]T)&samples[frame_index * 2])
                stereo := transmute([2][2]f32)swizzle(interleaved_stereo, 0, 2, 1, 3)
            }

            val := lerp(stereo[0], stereo[1], frame_t)
            delta := lerp(delta_range[0], delta_range[1], block_t)

            frame_buf[i] += val
            time += f64(delta)
        }

        return time
    }
}

update_param :: proc(param: ^Param($T), delta: f32) -> (result: [2]T) {
    target := intrinsics.atomic_load_explicit(&param.target, .Acquire)
    param_delta := intrinsics.atomic_load_explicit(&param.delta, .Acquire)

    result = {
        param.curr,
        move_towards(param.curr, target, param_delta * delta),
    }

    param.curr = result[1]

    return result
}

unpack_sample_u8 :: proc(v: u8) -> f32 {
    return (f32(v) - 128.0) * (1.0 / 255.0)
}

unpack_sample_i16 :: proc(v: i16) -> f32 {
    return f32(v) * (1.0 / 32768.0)
}

unpack_sample_f32 :: proc(v: f32) -> f32 {
    return v
}

unpack_mono_samples :: proc {
    unpack_mono_samples_f32,
    unpack_mono_samples_i16,
    unpack_mono_samples_u8,
}

unpack_mono_samples_f32 :: proc(data: [^]f32) -> [2]f32 {
    return (cast(^[2]f32)data)^
}

unpack_mono_samples_i16 :: proc(data: [^]i16) -> [2]f32 {
    return {f32(data[0]), f32(data[1])} * (1.0 / 32768.0)
}

unpack_mono_samples_u8 :: proc(data: [^]u8) -> [2]f32 {
    return ({f32(data[0]), f32(data[1])} - 128.0) * (1.0 / 255.0)
}

unpack_stereo_samples :: proc {
    unpack_stereo_samples_f32,
    unpack_stereo_samples_i16,
    unpack_stereo_samples_u8,
}

unpack_stereo_samples_f32 :: proc(data: [^]f32) -> #simd[4]f32 {
    return (cast(^#simd[4]f32)data)^
}

unpack_stereo_samples_i16 :: proc(data: [^]i16) -> #simd[4]f32 {
    packed := (cast(^#simd[4]i16)data)^
    return cast(#simd[4]f32)packed * (1.0 / 32768.0)
}

unpack_stereo_samples_u8 :: proc(data: [^]u8) -> #simd[4]f32 {
    packed := (cast(^#simd[4]u8)data)^
    return (cast(#simd[4]f32)packed - 128.0) * (1.0 / 255.0)
}

unpack_sample :: proc {
    unpack_sample_u8,
    unpack_sample_i16,
    unpack_sample_f32,
}

@(require_results)
lerp :: proc "contextless" (a, b: $T, t: f32) -> T {
    return a * (1 - t) + b * t
}

@(require_results)
dot :: proc "contextless" (a, b: [3]f32) -> f32 {
    ab := a * b
    return ab.x + ab.y + ab.z
}

@(require_results)
cross :: proc "contextless" (a, b: [3]f32) -> (c: [3]f32) {
    return a.yzx*b.zxy - b.yzx*a.zxy
}

@(require_results)
normalize :: proc "contextless" (v: [3]f32) -> [3]f32 {
    vv := v * v
    length := intrinsics.sqrt(vv.x + vv.y + vv.z)
    if length <= 1e-6 {
        return 0
    }
    return v / length
}

move_towards :: proc {
    move_towards_f32,
    move_towards_vec3,
}

@(require_results)
move_towards_f32 :: proc "contextless" (val: f32, target: f32, delta: f32) -> f32 {
    diff := target - val
    if abs(diff) < delta {
        return target
    }
    return val + (diff > 0 ? delta : -delta)
}

@(require_results)
move_towards_vec3 :: proc "contextless" (val: [3]f32, target: [3]f32, delta: f32) -> [3]f32 {
    diff := target - val
    len2 := dot(diff, diff)
    if len2 < delta * delta {
        return target
    }
    dir := diff / intrinsics.sqrt(len2)
    return val + dir * delta
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
