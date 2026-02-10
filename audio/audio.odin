#+vet explicit-allocators shadowing unused
package raven_audio

import "../base"
import "base:intrinsics"
import "base:runtime"

// TODO: sound fading
// TODO: sound trim range for dynamically chopping big sounds

BACKEND :: #config(AUDIO_BACKEND, BACKEND_DEFAULT)

BACKEND_NONE :: "None"
BACKEND_MINIAUDIO :: "miniaudio"

when ODIN_OS == .JS {
    // TODO: js audio
    BACKEND_DEFAULT :: BACKEND_NONE
} else {
    BACKEND_DEFAULT :: BACKEND_MINIAUDIO
}

MAX_GROUPS :: #config(AUDIO_MAX_GROUPS, 16)
MAX_SOUNDS :: #config(AUDIO_MAX_SOUNDS, 1024)
MAX_RESOURCES :: #config(AUDIO_MAX_RESOURCE, 512)

// TODO: custom generators

#assert(MAX_GROUPS < 64)

Handle_Index :: u16
Handle_Gen :: u8

// Zero value means invalid handle
Handle :: struct {
    index:  u16,
    gen:    u8,
}

Resource_Handle :: distinct Handle
Sound_Handle :: distinct Handle
Group_Handle :: distinct Handle

_state: ^State

State :: struct #align(64) {
    using native:       _State,

    groups_used:        bit_set[0..<64],
    groups:             [MAX_GROUPS]Group,

    resources_used:     base.Bit_Pool(MAX_RESOURCES),
    resources_gen:      [MAX_RESOURCES]Handle_Gen,
    resources:          [MAX_RESOURCES]Resource,

    sounds_used:        base.Bit_Pool(MAX_SOUNDS),
    sounds_gen:         [MAX_SOUNDS]Handle_Gen,
    sounds:             [MAX_SOUNDS]Sound,
    sound_recycle:      i32,
}


// Represents the sample data.
Resource :: struct {
    using native:   _Resource,
}

Sound :: struct {
    using native:   _Sound,
    resource:       Resource_Handle,
}

Group :: struct {
    using native:   _Group,
    gen:            u8,
    filters:        bit_set[Filter_Kind],
    delay:          Delay_Filter,
}

Filter_Kind :: enum u8 {
    Delay,
}

Delay_Filter :: struct {
    using native:   _Delay_Filter,
}

Pan_Mode :: enum u8 {
    Balance = 0, // Does not blend one side with the other. Technically just a balance.
    Pan, // A true pan. The sound from one side will "move" to the other side and blend with it.
}

Sample_Format :: enum u8 {
    F32,
    I32,
    I16,
    U8,
}

Units :: enum u8 {
    Seconds,
    Percentage,
    Samples,
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

    _state.groups_used += {0}
    base.bit_pool_set_1(&_state.resources_used, 0)
    base.bit_pool_set_1(&_state.sounds_used, 0)

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

// Sample audio-thread time in nanoseconds
get_global_time :: proc() -> u64 {
    return _get_global_time()
}

get_output_sample_rate :: proc() -> u32 {
    return _get_output_sample_rate()
}

// Call every frame from the main thread.
// Low overhead, audio is in another thread.
update :: proc() {
    recycle_old_sounds()
}

// Called every update.
recycle_old_sounds :: proc() {
    recycle_set := transmute(bit_set[0..<64])_state.sounds_used.l1[_state.sound_recycle]

    for i in 0..<64 {
        if i not_in recycle_set {
            continue
        }

        index := _state.sound_recycle * 64 + i32(i)
        if index == 0 {
            continue
        }

        sound := &_state.sounds[index]

        handle := Sound_Handle{
            Handle_Index(index),
            _state.sounds_gen[index],
        }

        if _is_sound_finished(sound) {
            // base.log(.Info, "Recycling sound %v", handle)
            destr_ok := destroy_sound(handle)
            assert(destr_ok)
        }
    }

    _state.sound_recycle = (_state.sound_recycle + 1) %% len(_state.sounds_used.l1)
}

find_unused_group_index :: proc() -> (bit: int, ok: bool) {
    set := transmute(u64)_state.groups_used
    first_unused := intrinsics.count_trailing_zeros(~set)
    if first_unused == 64 {
        return 0, false
    }
    return int(first_unused), true
}



// MARK: Sounds

create_resource_encoded :: proc(data: []byte) -> (result: Resource_Handle, ok: bool) {
    index := base.bit_pool_find_0(_state.resources_used) or_return

    result = {
        index = Handle_Index(index),
        gen = _state.resources_gen[index],
    }

    resource := &_state.resources[index]
    resource^ = {}

    _init_resource_encoded(resource, result, data) or_return

    base.bit_pool_set_1(&_state.resources_used, index)

    return result, true
}

create_resource_decoded :: proc(data: []byte, format: Sample_Format, stereo: bool, sample_rate: u32) -> (result: Resource_Handle, ok: bool) {
    index := base.bit_pool_find_0(_state.resources_used) or_return

    result = {
        index = Handle_Index(index),
        gen = _state.resources_gen[index],
    }

    resource := &_state.resources[index]
    resource^ = {}

    _init_resource_decoded(resource, result, data = data, format = format, stereo = stereo, sample_rate = sample_rate) or_return

    base.bit_pool_set_1(&_state.resources_used, index)

    return result, true
}

create_sound :: proc(resource_handle: Resource_Handle, group_handle: Group_Handle = {}, async_decode := false) -> (result: Sound_Handle, ok: bool) {
    index := base.bit_pool_find_0(_state.sounds_used) or_return

    _, res_ok := get_internal_resource(resource_handle)
    assert(res_ok)

    sound := &_state.sounds[index]
    sound^ = {}

    _init_sound(sound, resource_handle, group_handle = group_handle, async_decode = async_decode) or_return

    sound.resource = resource_handle

    result = {
        index = Handle_Index(index),
        gen = _state.sounds_gen[index],
    }

    base.bit_pool_set_1(&_state.sounds_used, index)

    return result, true
}

destroy_sound :: proc(handle: Sound_Handle) -> bool {
    sound := get_internal_sound(handle) or_return
    assert(base.bit_pool_check_1(_state.sounds_used, handle.index))
    _destroy_sound(sound)
    base.bit_pool_set_0(&_state.sounds_used, handle.index)
    _state.sounds_gen[handle.index] += 1
    return true
}

is_sound_playing :: proc(handle: Sound_Handle) -> bool {
    if sound, ok := get_internal_sound(handle); ok {
        return _is_sound_playing(sound)
    }
    return false
}

is_sound_finished :: proc(handle: Sound_Handle) -> bool {
    if sound, ok := get_internal_sound(handle); ok {
        return _is_sound_finished(sound)
    }
    return false
}

get_sound_time :: proc(handle: Sound_Handle, units: Units = .Seconds) -> f32 {
    if sound, ok := get_internal_sound(handle); ok {
        return _get_sound_time(sound, units)
    }
    return 0
}

set_sound_playing :: proc(handle: Sound_Handle, val: bool) {
    if sound, ok := get_internal_sound(handle); ok {
        _set_sound_playing(sound, val)
    } else {
        assert(false)
    }
}

set_sound_looping :: proc(handle: Sound_Handle, val: bool) {
    if sound, ok := get_internal_sound(handle); ok {
        _set_sound_looping(sound, val)
    }
}

set_sound_start_delay :: proc(handle: Sound_Handle, val: f32, units: Units = .Seconds) {
    if sound, ok := get_internal_sound(handle); ok {
        _set_sound_start_delay(sound, val, units)
    }
}

set_sound_volume :: proc(handle: Sound_Handle, factor: f32) {
    if sound, ok := get_internal_sound(handle); ok {
        _set_sound_volume(sound, factor)
    }
}

set_sound_pan :: proc(handle: Sound_Handle, pan: f32, mode: Pan_Mode = .Balance) {
    if sound, ok := get_internal_sound(handle); ok {
        _set_sound_pan(sound, pan, mode)
    }
}

set_sound_pitch :: proc(handle: Sound_Handle, pitch: f32) {
    if sound, ok := get_internal_sound(handle); ok {
        _set_sound_pitch(sound, pitch)
    }
}

set_sound_spatialization :: proc(handle: Sound_Handle, enabled: bool) {
    if sound, ok := get_internal_sound(handle); ok {
        _set_sound_spatialization(sound, enabled)
    }
}

set_sound_position :: proc(handle: Sound_Handle, pos: [3]f32) {
    if sound, ok := get_internal_sound(handle); ok {
        _set_sound_position(sound, pos)
    }
}

set_sound_direction :: proc(handle: Sound_Handle, dir: [3]f32) {
    if sound, ok := get_internal_sound(handle); ok {
        _set_sound_direction(sound, dir)
    }
}

set_sound_velocity :: proc(handle: Sound_Handle, vel: [3]f32) {
    if sound, ok := get_internal_sound(handle); ok {
        _set_sound_velocity(sound, vel)
    }
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

get_internal_group :: proc(handle: Group_Handle) -> (result: ^Group, ok: bool) {
    if handle.index <= 0 || handle.index >= MAX_GROUPS {
        return nil, false
    }

    group := &_state.groups[handle.index]
    if group.gen != handle.gen {
        return nil, false
    }

    return group, true
}



// MARK: Group

create_group :: proc(parent_handle: Group_Handle = {}, delay: f32 = 0) -> Group_Handle {
    index, ok := find_unused_group_index()
    if !ok {
        return {}
    }

    group := &_state.groups[index]
    gen := group.gen
    group^ = {}
    group.gen = gen

    _init_group(group, parent_handle, delay)
    _state.groups_used += {index}

    return {
        index = Handle_Index(index),
        gen = gen,
    }
}

destroy_group :: proc(handle: Group_Handle) {
    if group, ok := get_internal_group(handle); ok {
        _destroy_group(group)
        group.gen += 1
        _state.groups_used -= {int(handle.index)}
    }
}

set_group_volume :: proc(handle: Group_Handle, factor: f32) {
    if group, ok := get_internal_group(handle); ok {
        _set_group_volume(group, factor)
    }
}

set_group_pan :: proc(handle: Group_Handle, pan: f32, mode: Pan_Mode = .Pan) {
    if group, ok := get_internal_group(handle); ok {
        _set_group_pan(group, pan, mode)
    }
}

set_group_pitch :: proc(handle: Group_Handle, pitch: f32) {
    if group, ok := get_internal_group(handle); ok {
        _set_group_pitch(group, pitch)
    }
}

set_group_spatialization :: proc(handle: Group_Handle, enabled: bool) {
    if group, ok := get_internal_group(handle); ok {
        _set_group_spatialization(group, enabled)
    }
}

set_group_delay_decay :: proc(handle: Group_Handle, decay: f32) {
    if group, ok := get_internal_group(handle); ok && .Delay in group.filters {
        _set_group_delay_decay(group, decay)
    }
}

// wet = the prorcessed signal
set_group_delay_wet :: proc(handle: Group_Handle, wet: f32) {
    if group, ok := get_internal_group(handle); ok && .Delay in group.filters {
        _set_group_delay_wet(group, wet)
    }
}

// dry = no postprocess on the signal
set_group_delay_dry :: proc(handle: Group_Handle, dry: f32) {
    if group, ok := get_internal_group(handle); ok && .Delay in group.filters {
        _set_group_delay_dry(group, dry)
    }
}




// MARK: Utils

// Clones a string and appends a null-byte to make it a cstring
clone_to_cstring :: proc(s: string, allocator := context.allocator, loc := #caller_location) ->
    (res: cstring, err: runtime.Allocator_Error) #optional_allocator_error
{
    c := make([]byte, len(s)+1, allocator, loc) or_return
    copy(c, s)
    c[len(s)] = 0
    return cstring(&c[0]), nil
}