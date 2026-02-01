#+build !js
#+vet explicit-allocators shadowing unused
package raven_audio

import "core:log"
// https://miniaud.io/docs/manual/index.html
import ma "vendor:miniaudio"

_ :: ma
_ :: log

when BACKEND == BACKEND_MINIAUDIO {

    _State :: struct {
        engine:     ma.engine,
        manager:    ma.resource_manager,
    }

    _Sound :: struct {
        sound: ma.sound,
    }

    _Resource :: struct {

    }

    _Group :: struct {
        group: ma.sound_group,
    }

    _Delay_Filter :: struct {
        delay:  ma.delay_node,
    }

    @(require_results)
    _init :: proc() -> bool {
        rm_config := ma.resource_manager_config_init()
        rm_config.pVFS = cast(^ma.vfs)&_ma_null_vfs

        _ma_check(ma.resource_manager_init(&rm_config, &_state.manager)) or_return

        config := ma.engine_config_init()
        config.listenerCount = 1
        config.pResourceManager = &_state.manager

        _ma_check(ma.engine_init(&config, &_state.engine)) or_return

        return true
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

    _get_global_time :: proc() -> u64 {
        return ma.engine_get_time_in_milliseconds(&_state.engine) * 1e6
    }

    _get_output_sample_rate :: proc() -> u32 {
        return ma.engine_get_sample_rate(&_state.engine)
    }


    // MARK: Sound

    _init_resource_decoded :: proc(
        resource:       ^Resource,
        handle:         Resource_Handle,
        data:           []byte,
        format:         Sample_Format,
        stereo:         bool,
        sample_rate:    u32,
    ) -> bool {
        assert(handle != {})

        sample_rate := sample_rate

        manager := ma.engine_get_resource_manager(&_state.engine)

        if sample_rate == 0 {
            sample_rate = ma.engine_get_sample_rate(&_state.engine)
        }

        channels: u32 = stereo ? 2 : 1

        _ma_check(ma.resource_manager_register_decoded_data(
            manager,
            pName = _ma_handle_cstr(Handle(handle)),
            pData = raw_data(data),
            frameCount = u64(len(data)),
            format = _ma_sample_format(format),
            channels = channels,
            sampleRate = sample_rate,
        )) or_return

        return true
    }

    _init_resource_encoded :: proc(resource: ^Resource, handle: Resource_Handle,  data: []byte) -> bool {
        assert(handle != {})

        manager := ma.engine_get_resource_manager(&_state.engine)

        path := _ma_handle_cstr(Handle(handle))
        log.info("init res", handle, path)

        _ma_check(ma.resource_manager_register_encoded_data(
            manager,
            pName = path,
            pData = raw_data(data),
            sizeInBytes = len(data),
        )) or_return

        return true
    }

    _init_sound :: proc(sound: ^Sound, resource_handle: Resource_Handle, async_decode: bool, group_handle: Group_Handle) -> bool {
        assert(resource_handle != {})

        group: ^ma.sound_group
        if g, g_ok := get_internal_group(group_handle); g_ok {
            group = &g.group
        }

        path := _ma_handle_cstr(Handle(resource_handle))

        _ma_check(ma.sound_init_from_file(
            &_state.engine,
            pFilePath = path,
            flags = (async_decode ? {.DECODE, .ASYNC} : {.DECODE}) + {.NO_SPATIALIZATION},
            pGroup = group,
            pDoneFence = nil,
            pSound = &sound.sound,
        )) or_return

        // ma.sound_start(&sound.sound)

        return true
    }

    _is_sound_playing :: proc(sound: ^Sound) -> bool {
        return bool(ma.sound_is_playing(&sound.sound) && !ma.sound_at_end(&sound.sound))
    }

    _is_sound_finished :: proc(sound: ^Sound) -> bool {
        return bool(ma.sound_at_end(&sound.sound))
    }

    _get_sound_time :: proc(sound: ^Sound, units: Units) -> f32 {
        switch units {
        case .Seconds:
            res: f32
            _ma_check(ma.sound_get_cursor_in_seconds(&sound.sound, &res))
            return res

        case .Percentage:
            sec: f32
            length: f32
            _ma_check(ma.sound_get_length_in_seconds(&sound.sound, &length))
            _ma_check(ma.sound_get_cursor_in_seconds(&sound.sound, &sec))
            return clamp(sec / length, 0, 1)

        case .Samples:
            cur: u64
            _ma_check(ma.sound_get_cursor_in_pcm_frames(&sound.sound, &cur))
            return f32(cur)
        }

        return 0
    }

    _destroy_sound :: proc(sound: ^Sound) {
        ma.sound_uninit(&sound.sound)
    }

    _set_sound_volume :: proc(sound: ^Sound, factor: f32) {
        ma.sound_set_volume(&sound.sound, factor)
    }

    _set_sound_pan :: proc(sound: ^Sound, pan: f32, mode: Pan_Mode) {
        ma.sound_set_pan_mode(&sound.sound, _ma_pan_mode(mode))
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

    _set_sound_playing :: proc(sound: ^Sound, play: bool) {
        if play {
            ma.sound_start(&sound.sound)
        } else {
            ma.sound_stop(&sound.sound)
        }
    }

    _set_sound_looping :: proc(sound: ^Sound, val: bool) {
        ma.sound_set_looping(&sound.sound, b32(val))
    }

    _set_sound_start_delay :: proc(sound: ^Sound, val: f32, units: Units = .Seconds) {
        pcm_delay: u64

        switch units {
        case .Seconds:
            pcm_delay = u64(f64(val) * f64(ma.engine_get_sample_rate(&_state.engine)))

        case .Percentage:
            length: f32
            ma.sound_get_length_in_seconds(&sound.sound, &length)
            pcm_delay = u64(f64(val * length) * f64(ma.engine_get_sample_rate(&_state.engine)))

        case .Samples:
            pcm_delay = u64(val)
        }

        ma.sound_set_start_time_in_pcm_frames(&sound.sound,
            ma.engine_get_time_in_milliseconds(&_state.engine) + pcm_delay,
        )
    }



    // MARK: Group

    _init_group :: proc(group: ^Group, parent_handle: Group_Handle, delay: f32) {
        parent_group: ^ma.sound_group
        if g, g_ok := get_internal_group(parent_handle); g_ok {
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
        ma.sound_group_set_pan_mode(&group.group, _ma_pan_mode(mode))
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

    _ma_check :: proc(res: ma.result, expr := #caller_expression(res), loc := #caller_location) -> bool {
        #partial switch res {
        case .SUCCESS:
            return true
        }
        log.errorf("Audio: miniaudio error: %v (%s)", res, expr, location = loc)
        return false
    }

    // NOTE: returns a ptr to an internal buffer.
    _ma_handle_cstr :: proc(handle: Handle) -> cstring {
        @(static) buf: [8 + 1]byte

        offs := 0
        offs += _encode_hex(buf[offs:], u64(handle.index), size_of(handle.index))
        offs += _encode_hex(buf[offs:], u64(handle.gen), size_of(handle.gen))
        buf[offs] = 0

        return cast(cstring)&buf[0]

        _encode_hex :: proc(buf: []byte, value: u64, size: int) -> int {
            shift := (size * 8) - 4

            index := 0
            for shift >= 0 {
                d := (value >> uint(shift)) & 0xf
                if d < 10 {
                    buf[index] = byte('0' + d)
                } else {
                    buf[index] = byte('a' + (d - 10))
                }
                shift -= 4
                index += 1
            }

            return int(size) * 2
        }
    }

    _ma_pan_mode :: proc(pan_mode: Pan_Mode) -> ma.pan_mode {
        switch pan_mode {
        case .Pan: return .pan
        case .Balance: return .balance
        }
        assert(false)
        return .pan
    }

    _ma_sample_format :: proc(format: Sample_Format) -> ma.format {
        switch format {
        case .F32:  return .f32
        case .I32:  return .s32
        case .I16:  return .s16
        case .U8:   return .u8
        }
        assert(false)
        return .s16
    }

    @(rodata)
    _ma_null_vfs := ma.vfs_callbacks{
	    onOpen  = _ma_on_open_callback,
	    onOpenW = _ma_on_open_w_callback,
	    onClose = _ma_on_close_callback,
	    onRead  = _ma_on_read_callback,
	    onWrite = _ma_on_write_callback,
	    onSeek  = _ma_on_seek_callback,
	    onTell  = _ma_on_tell_callback,
	    onInfo  = _ma_on_info_callback,
    }

    _ma_on_open_callback :: proc "c" (pVFS: ^ma.vfs, pFilePath: cstring, openMode: ma.open_mode_flags, pFile: ^ma.vfs_file) -> ma.result {
        return .DOES_NOT_EXIST
    }

    _ma_on_open_w_callback :: proc "c" (pVFS: ^ma.vfs, pFilePath: [^]u16, openMode: ma.open_mode_flags, pFile: ^ma.vfs_file) -> ma.result {
        return .DOES_NOT_EXIST
    }

    _ma_on_close_callback :: proc "c" (pVFS: ^ma.vfs, file: ma.vfs_file) -> ma.result {
        return .DOES_NOT_EXIST
    }

    _ma_on_read_callback :: proc "c" (pVFS: ^ma.vfs, file: ma.vfs_file, pDst: rawptr, sizeInBytes: uint, pBytesRead: ^uint) -> ma.result {
        return .DOES_NOT_EXIST
    }

    _ma_on_write_callback :: proc "c" (pVFS: ^ma.vfs, file: ma.vfs_file, pSrc: rawptr, sizeInBytes: uint, pBytesWritten: ^uint) -> ma.result {
        return .DOES_NOT_EXIST
    }

    _ma_on_seek_callback :: proc "c" (pVFS: ^ma.vfs, file: ma.vfs_file, offset: i64, origin: ma.seek_origin) -> ma.result {
        return .DOES_NOT_EXIST
    }

    _ma_on_tell_callback :: proc "c" (pVFS: ^ma.vfs, file: ma.vfs_file, pCursor: ^i64) -> ma.result {
        return .DOES_NOT_EXIST
    }

    _ma_on_info_callback :: proc "c" (pVFS: ^ma.vfs, file: ma.vfs_file, pInfo: ^ma.file_info) -> ma.result {
        return .DOES_NOT_EXIST
    }
}