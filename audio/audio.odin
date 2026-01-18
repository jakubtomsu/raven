#+vet explicit-allocators shadowing unused
package raven_audio

import "core:log"
import "base:intrinsics"
import "base:runtime"

// TODO: read audio thread timer


BACKEND :: #config(AUDIO_BACKEND, BACKEND_DEFAULT)

BACKEND_DUMMY :: "Dummy"
BACKEND_MINIAUDIO :: "miniaudio"

when ODIN_OS == .JS {
    BACKEND_DEFAULT :: BACKEND_DUMMY
} else {
    BACKEND_DEFAULT :: BACKEND_MINIAUDIO
}

MAX_GROUPS :: #config(AUDIO_MAX_GROUPS, 16)
MAX_SOUNDS :: #config(AUDIO_MAX_SOUNDS, 1024)

// TODO: custom generators

#assert(MAX_GROUPS < 64)

SOUND_SET_WIDTH :: 64

Handle_Index :: u16
Handle_Gen :: u8

// Zero value means invalid handle
Handle :: struct {
    index:  u16,
    gen:    u8,
}

Sound_Handle :: distinct Handle
Group_Handle :: distinct Handle

_state: ^State

State :: struct #align(64) {
    using native:   _State,

    groups:         [MAX_GROUPS]Group,
    groups_used:    bit_set[0..<64],

    sounds:         [MAX_SOUNDS]Sound,
    // TODO: two-level bit set
    sounds_used:    [MAX_SOUNDS / SOUND_SET_WIDTH]bit_set[0..<SOUND_SET_WIDTH],
    sound_recycle:  i32,
}

Sound :: struct {
    using native:   _Sound,
    gen:            u8,
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



// MARK: Core

set_state_ptr :: proc(state: ^State) {
    _state = state
}

get_state_ptr :: proc() -> (state: ^State) {
    return _state
}

init :: proc(state: ^State) {
    if _state != nil {
        return
    }

    _state = state

    _state.groups_used += {0}
    _state.sounds_used[0] += {0}

    _init()
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
    recycle_old_sounds()
}

// Called every update.
recycle_old_sounds :: proc() {
    recycle_set := _state.sounds_used[_state.sound_recycle]

    for i in 0..<SOUND_SET_WIDTH {
        if i not_in recycle_set {
            continue
        }

        index := _state.sound_recycle * SOUND_SET_WIDTH + i32(i)

        sound := &_state.sounds[index]

        if _is_sound_finished(sound) {
            log.info("auto destroying sound")
            _destroy_sound(sound)
            recycle_set -= {i}
        }
    }

    _state.sounds_used[_state.sound_recycle] = recycle_set

    _state.sound_recycle = (_state.sound_recycle + 1) %% (MAX_SOUNDS / SOUND_SET_WIDTH)
}

find_unused_sound_index :: proc() -> (slot: int, bit: int, ok: bool) {
    for i in 0..< MAX_SOUNDS / SOUND_SET_WIDTH {
        set := transmute(u64)_state.sounds_used[i]
        first_unused := intrinsics.count_trailing_zeros(~set)
        if first_unused == 64 {
            continue
        }
        return i, int(first_unused), true
    }
    return 0, 0, false
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

unpack_sound_index :: proc(index: int) -> (int, int) {
    return index / SOUND_SET_WIDTH, index % SOUND_SET_WIDTH
}

get_sound :: proc(handle: Sound_Handle) -> (^Sound, bool) {
    if handle.index <= 0 || handle.index >= MAX_SOUNDS {
        return nil, false
    }

    sound := &_state.sounds[handle.index]
    if sound.gen != handle.gen {
        return nil, false
    }

    return sound, true
}

play_sound :: proc(
    name:           string,
    start           := true,
    loop            := false,
    start_delay:    f32 = 0,
    start_fade:     f32 = 0,
    end_fade:       f32 = 0,
    chop:           [2]f32 = {0, 1},
    volume:         f32 = 1,
    pitch:          f32 = 1,
    position:       [3]f32 = 0,
    group:          Group_Handle = {},
) -> Sound_Handle {
    slot_index, bit_index, ok := find_unused_sound_index()
    if !ok {
        log.error("failed to play sound")
        return {}
    }

    index := slot_index * SOUND_SET_WIDTH + bit_index
    sound := &_state.sounds[index]
    gen := sound.gen
    sound^ = {}
    sound.gen = gen

    if !_play_sound(sound, name = name, loop = loop, group_handle = group) {
        return {}
    }

    if start {
        _start_sound(sound)
    }

    if pitch != 1 {
        _set_sound_pitch(sound, pitch)
    }

    if volume != 1 {
        _set_sound_volume(sound, pitch)
    }

    if position != {} {
        _set_sound_position(sound, position)
    }

    _state.sounds_used[slot_index] += {int(bit_index)}

    return {
        index = Handle_Index(index),
        gen = gen,
    }
}

destroy_sound :: proc(handle: Sound_Handle) {
    if sound, ok := get_sound(handle); ok {
        _destroy_sound(sound)

        slot, bit := unpack_sound_index(int(handle.index))
        sound.gen += 1
        _state.sounds_used[slot] -= {int(bit)}
    }
}

is_sound_playing :: proc(handle: Sound_Handle) -> bool {
    if sound, ok := get_sound(handle); ok {
        return _is_sound_playing(sound)
    }
    return false
}

is_sound_finished :: proc(handle: Sound_Handle) -> bool {
    if sound, ok := get_sound(handle); ok {
        return _is_sound_finished(sound)
    }
    return false
}

get_sound_progress :: proc(handle: Sound_Handle) -> f32 {
    if sound, ok := get_sound(handle); ok {
        return _get_sound_progress(sound)
    }
    return 0
}

start_sound :: proc(handle: Sound_Handle) {
    if sound, ok := get_sound(handle); ok {
        _start_sound(sound)
    }
}

pause_sound :: proc(handle: Sound_Handle) {
    if sound, ok := get_sound(handle); ok {
        _pause_sound(sound)
    }
}

set_sound_volume :: proc(handle: Sound_Handle, factor: f32) {
    if sound, ok := get_sound(handle); ok {
        _set_sound_volume(sound, factor)
    }
}

set_sound_pan :: proc(handle: Sound_Handle, pan: f32, mode: Pan_Mode = .Balance) {
    if sound, ok := get_sound(handle); ok {
        _set_sound_pan(sound, pan, mode)
    }
}

set_sound_pitch :: proc(handle: Sound_Handle, pitch: f32) {
    if sound, ok := get_sound(handle); ok {
        _set_sound_pitch(sound, pitch)
    }
}

set_sound_spatialization :: proc(handle: Sound_Handle, enabled: bool) {
    if sound, ok := get_sound(handle); ok {
        _set_sound_spatialization(sound, enabled)
    }
}

set_sound_position :: proc(handle: Sound_Handle, pos: [3]f32) {
    if sound, ok := get_sound(handle); ok {
        _set_sound_position(sound, pos)
    }
}

set_sound_direction :: proc(handle: Sound_Handle, dir: [3]f32) {
    if sound, ok := get_sound(handle); ok {
        _set_sound_direction(sound, dir)
    }
}

set_sound_velocity :: proc(handle: Sound_Handle, vel: [3]f32) {
    if sound, ok := get_sound(handle); ok {
        _set_sound_velocity(sound, vel)
    }
}




// MARK: Group

get_group :: proc(handle: Group_Handle) -> (result: ^Group, ok: bool) {
    if handle.index <= 0 || handle.index >= MAX_GROUPS {
        return nil, false
    }

    group := &_state.groups[handle.index]
    if group.gen != handle.gen {
        return nil, false
    }

    return group, true
}

create_group :: proc(parent_handle: Group_Handle = {}, delay: f32 = 0) -> Group_Handle {
    index, ok := find_unused_group_index()
    if !ok {
        return {}
    }

    group := &_state.groups[index]
    gen := group.gen
    group^ = {}
    group.gen = gen

    _create_group(group, parent_handle, delay)
    _state.groups_used += {index}

    return {
        index = Handle_Index(index),
        gen = gen,
    }
}

destroy_group :: proc(handle: Group_Handle) {
    if group, ok := get_group(handle); ok {
        _destroy_group(group)
        group.gen += 1
        _state.groups_used -= {int(handle.index)}
    }
}

set_group_volume :: proc(handle: Group_Handle, factor: f32) {
    if group, ok := get_group(handle); ok {
        _set_group_volume(group, factor)
    }
}

set_group_pan :: proc(handle: Group_Handle, pan: f32, mode: Pan_Mode = .Pan) {
    if group, ok := get_group(handle); ok {
        _set_group_pan(group, pan, mode)
    }
}

set_group_pitch :: proc(handle: Group_Handle, pitch: f32) {
    if group, ok := get_group(handle); ok {
        _set_group_pitch(group, pitch)
    }
}

set_group_spatialization :: proc(handle: Group_Handle, enabled: bool) {
    if group, ok := get_group(handle); ok {
        _set_group_spatialization(group, enabled)
    }
}

set_group_delay_decay :: proc(handle: Group_Handle, decay: f32) {
    if group, ok := get_group(handle); ok && .Delay in group.filters {
        _set_group_delay_decay(group, decay)
    }
}

// wet = the prorcessed signal
set_group_delay_wet :: proc(handle: Group_Handle, wet: f32) {
    if group, ok := get_group(handle); ok && .Delay in group.filters {
        _set_group_delay_wet(group, wet)
    }
}

// dry = no postprocess on the signal
set_group_delay_dry :: proc(handle: Group_Handle, dry: f32) {
    if group, ok := get_group(handle); ok && .Delay in group.filters {
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