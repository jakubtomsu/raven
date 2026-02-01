// Dummy backend for testing.
// Everything *must compile* on all targets.
// All procedures must be a no-op.
package raven_audio

when BACKEND == BACKEND_NONE {
    _State :: struct {}
    _Sound :: struct {}
    _Resource :: struct {}
    _Group :: struct {}
    _Delay_Filter :: struct {}

    @(require_results) _init :: proc() -> bool { return true }
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
}