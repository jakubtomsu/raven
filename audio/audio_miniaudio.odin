#+vet explicit-allocators shadowing unused
package raven_audio

import "core:log"

// https://miniaud.io/docs/manual/index.html
import ma "vendor:miniaudio"

_State :: struct {
    engine: ma.engine,
}

_Sound :: struct {
    sound: ma.sound,
}

_Group :: struct {
    group: ma.sound_group,
}

_Delay_Filter :: struct {
    delay:  ma.delay_node,
}

_init :: proc() {
    config := ma.engine_config_init()
    config.listenerCount = 1
    // config.sampleRate

    res := ma.engine_init(&config, &_state.engine)
    if res != .SUCCESS {
        return
    }
}

_shutdown :: proc() {
    ma.engine_stop(&_state.engine)
    ma.engine_uninit(&_state.engine)
}

_set_listener_transform :: proc(pos: [3]f32, forw: [3]f32, vel: [3]f32 = 0) {
    ma.engine_listener_set_position(&_state.engine, 0, pos.x, pos.y, pos.z)
    ma.engine_listener_set_direction(&_state.engine, 0, forw.x, forw.y, forw.z)
    ma.engine_listener_set_velocity(&_state.engine, 0, vel.x, vel.y, vel.z)
}

// MARK: Sound

_load_sound_data :: proc(name: string, data: []byte, stereo: bool, sample_rate: u32) {
    sample_rate := sample_rate

    manager := ma.engine_get_resource_manager(&_state.engine)

    if sample_rate == 0 {
        sample_rate = ma.engine_get_sample_rate(&_state.engine)
    }

    channels: u32 = stereo ? 2 : 1

    res := ma.resource_manager_register_decoded_data(
        manager,
        pName = clone_to_cstring(name, context.temp_allocator),
        pData = raw_data(data),
        frameCount = u64(len(data)),
        format = .f32,
        channels = channels,
        sampleRate = sample_rate,
    )

    if res != .SUCCESS {
        log.errorf("miniaudio error: {}", res)
        return
    }
}

_play_sound :: proc(sound: ^Sound, name: string, loop: bool, group_handle: Group_Handle) -> bool {
    ma_group: ^ma.sound_group
    if group, group_ok := get_group(group_handle); group_ok {
        ma_group = &group.group
    }

    res := ma.sound_init_from_file(
        &_state.engine,
        clone_to_cstring(name, context.temp_allocator),
        {.DECODE, .ASYNC},
        pGroup = ma_group,
        pDoneFence = nil,
        pSound = &sound.sound,
    )

    if res != .SUCCESS {
        log.errorf("miniaudio error: {}", res)
        return false
    }

    ma.sound_set_looping(&sound.sound, b32(loop))

    return true
}

_is_sound_playing :: proc(sound: ^Sound) -> bool {
    return bool(ma.sound_is_playing(&sound.sound) && !ma.sound_at_end(&sound.sound))
}

_is_sound_finished :: proc(sound: ^Sound) -> bool {
    return bool(ma.sound_at_end(&sound.sound))
}

_get_sound_progress :: proc(sound: ^Sound) -> f32 {
    res: f32
    ma.sound_get_cursor_in_seconds(&sound.sound, &res)
    return res
}

_destroy_sound :: proc(sound: ^Sound) {
    ma.sound_uninit(&sound.sound)
}

_start_sound :: proc(sound: ^Sound) {
    ma.sound_start(&sound.sound)
}

_pause_sound :: proc(sound: ^Sound) {
    ma.sound_stop(&sound.sound)
}

_set_sound_volume :: proc(sound: ^Sound, factor: f32) {
    ma.sound_set_volume(&sound.sound, factor)
}

_set_sound_pan :: proc(sound: ^Sound, pan: f32, mode: Pan_Mode) {
    ma.sound_set_pan_mode(&sound.sound, _miniaudio_pan_mode(mode))
    ma.sound_set_pan(&sound.sound, pan)
}

_set_sound_pitch :: proc(sound: ^Sound, pitch: f32) {
    ma.sound_set_pitch(&sound.sound, pitch)
}

_set_sound_spatialization :: proc(sound: ^Sound, enabled: bool) {
    ma.sound_set_spatialization_enabled(&sound.sound, b32(enabled))
}

_set_sound_position :: proc(sound: ^Sound, pos: [3]f32) {
    ma.sound_set_position(&sound.sound, pos.x, pos.y, pos.z)
}

_set_sound_direction :: proc(sound: ^Sound, dir: [3]f32) {
    ma.sound_set_direction(&sound.sound, dir.x, dir.y, dir.z)
}

_set_sound_velocity :: proc(sound: ^Sound, vel: [3]f32) {
    ma.sound_set_velocity(&sound.sound, vel.x, vel.y, vel.z)
}



// MARK: Group

_create_group :: proc(group: ^Group, parent_handle: Group_Handle, delay: f32) {
    parent_group: ^ma.sound_group
    if g, ok := get_group(parent_handle); ok {
        parent_group = &g.group
    }

    channels := ma.engine_get_channels(&_state.engine)
    sample_rate := ma.engine_get_sample_rate(&_state.engine)

    if delay > 0 {
        config := ma.delay_node_config_init(channels, sample_rate, u32(f32(sample_rate) * delay), decay = 0.5)

        res := ma.delay_node_init(
            ma.engine_get_node_graph(&_state.engine),
            &config,
            pAllocationCallbacks = nil,
            pDelayNode = &group.delay.delay,
        )

        if res != .SUCCESS {
            return
        }

        ma.node_attach_output_bus(
            cast(^ma.node)&group.delay.delay,
            0,
            ma.engine_get_endpoint(&_state.engine),
            0,
        )

        group.filters += {.Delay}
    }

    ma.sound_group_init(&_state.engine, {}, pParentGroup = parent_group, pGroup = &group.group)

    if .Delay in group.filters {
        ma.node_attach_output_bus(
            cast(^ma.node)&group.group,
            0,
            cast(^ma.node)&group.delay.delay,
            0,
        )
    }

    ma.sound_group_start(&group.group)
}

_destroy_group :: proc(group: ^Group) {
    ma.sound_group_uninit(&group.group)
}

_set_group_volume :: proc(group: ^Group, factor: f32) {
    ma.sound_group_set_volume(&group.group, factor)
}

_set_group_pan :: proc(group: ^Group, pan: f32, mode: Pan_Mode) {
    ma.sound_group_set_pan_mode(&group.group, _miniaudio_pan_mode(mode))
    ma.sound_group_set_pan(&group.group, pan)
}

_set_group_pitch :: proc(group: ^Group, pitch: f32) {
    ma.sound_group_set_pitch(&group.group, pitch)
}

_set_group_spatialization :: proc(group: ^Group, enabled: bool) {
    ma.sound_group_set_spatialization_enabled(&group.group, b32(enabled))
}

_set_group_delay_decay :: proc(group: ^Group, decay: f32) {
    ma.delay_node_set_decay(&group.delay.delay, decay)
}

_set_group_delay_wet :: proc(group: ^Group, wet: f32) {
    ma.delay_node_set_wet(&group.delay.delay, wet)
}

_set_group_delay_dry :: proc(group: ^Group, dry: f32) {
    ma.delay_node_set_dry(&group.delay.delay, dry)
}




// MARK: Etc

_miniaudio_pan_mode :: proc(pan_mode: Pan_Mode) -> ma.pan_mode {
    switch pan_mode {
    case .Pan: return .pan
    case .Balance: return .balance
    }
    assert(false)
    return .pan
}