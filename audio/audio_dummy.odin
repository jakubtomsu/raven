// Dummy backend for testing.
// Everything *must compile* on all targets and ALSO RUN.
package raven_audio

when BACKEND == BACKEND_DUMMY {
    _State :: struct {}
    _Sound :: struct {}
    _Group :: struct {}
    _Delay_Filter :: struct {}


    _init :: proc() {}
    _shutdown :: proc() {}

    _set_listener_transform :: proc(pos: [3]f32, forw: [3]f32, vel: [3]f32) {}

    // MARK: Sound

    _load_sound_data :: proc(name: string, data: []byte, stereo: bool, sample_rate: u32) {}

    _play_sound :: proc(sound: ^Sound, name: string, loop: bool, group_handle: Group_Handle) -> bool { return {} }
    _is_sound_playing :: proc(sound: ^Sound) -> bool { return {} }
    _is_sound_finished :: proc(sound: ^Sound) -> bool { return {} }
    _get_sound_progress :: proc(sound: ^Sound) -> f32 { return {} }

    _destroy_sound :: proc(sound: ^Sound) {}
    _start_sound :: proc(sound: ^Sound) {}
    _pause_sound :: proc(sound: ^Sound) {}
    _set_sound_volume :: proc(sound: ^Sound, factor: f32) {}
    _set_sound_pan :: proc(sound: ^Sound, pan: f32, mode: Pan_Mode) {}
    _set_sound_pitch :: proc(sound: ^Sound, pitch: f32) {}
    _set_sound_spatialization :: proc(sound: ^Sound, enabled: bool) {}
    _set_sound_position :: proc(sound: ^Sound, pos: [3]f32) {}
    _set_sound_direction :: proc(sound: ^Sound, dir: [3]f32) {}
    _set_sound_velocity :: proc(sound: ^Sound, vel: [3]f32) {}


    // MARK: Group

    _create_group :: proc(group: ^Group, parent_handle: Group_Handle, delay: f32) {}
    _destroy_group :: proc(group: ^Group) {}
    _set_group_volume :: proc(group: ^Group, factor: f32) {}
    _set_group_pan :: proc(group: ^Group, pan: f32, mode: Pan_Mode) {}
    _set_group_pitch :: proc(group: ^Group, pitch: f32) {}
    _set_group_spatialization :: proc(group: ^Group, enabled: bool) {}
    _set_group_delay_decay :: proc(group: ^Group, decay: f32) {}
    _set_group_delay_wet :: proc(group: ^Group, wet: f32) {}
    _set_group_delay_dry :: proc(group: ^Group, dry: f32) {}
}