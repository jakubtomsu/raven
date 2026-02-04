package raven_fps_example

import "core:math/linalg"
import "core:math"
import "core:fmt"
import rv "../.."
import "../../platform"

state: ^State

State :: struct {
    pos:        rv.Vec3,
    vel:        rv.Vec3,
    ang:        rv.Vec3,
    gun_pos:    rv.Vec3,
    group:      rv.Group_Handle,
    terrain:    rv.Mesh_Handle,
}

main :: proc() {
    rv.run_main_loop(_module_api())
}

@export _module_api :: proc "contextless" () -> (rv.Module_API) {
    return {
        state_size = size_of(State),
        init = transmute(rv.Init_Proc)_init,
        shutdown = transmute(rv.Shutdown_Proc)_shutdown,
        update = transmute(rv.Update_Proc)_update,
    }
}

_init :: proc() -> ^State {
    state = new(State)

    rv.init_window("FPS Example", .Borderless)
    platform.set_mouse_relative(rv._state.window, true)
    platform.set_mouse_visible(false)

    state.pos = {0, 1, 0}
    state.ang = {0, 0, 0}

    state.group = rv.create_group()

    state.terrain = rv.create_mesh_from_data("terrain", state.group,
        {
            {pos = {0, 0, 0}, color = {255, 0, 255}},
            {pos = {0, 10, 0}, color = 255},
            {pos = {10, 10, 0}, color = {0, 0, 255}},
        },
        indices = {0, 1, 2},
    )

    return state
}

_shutdown :: proc(prev_state: ^State) {
    free(prev_state)
}

_update :: proc(prev_state: ^State) -> ^State {
    state = prev_state

    if rv.key_pressed(.Escape) {
        return nil
    }

    delta := rv.get_delta_time()

    // TODO: abstract basic flycam controls into a simple util?

    move: rv.Vec2
    if rv.key_down(.D) do move.x += 1
    if rv.key_down(.A) do move.x -= 1
    if rv.key_down(.W) do move.y += 1
    if rv.key_down(.S) do move.y -= 1

    state.ang.xy += rv.mouse_delta().yx * {-1, 1} * 0.002
    state.ang.x = clamp(state.ang.x, -math.PI * 0.49, math.PI * 0.49)
    state.ang.z = rv.lexp(state.ang.z, 0, delta * 5)

    state.ang.z += move.x * delta * -0.2

    cam_rot := linalg.quaternion_normalize(rv.euler_rot(state.ang))
    mat := linalg.matrix3_from_quaternion_f32(cam_rot)

    grounded := state.pos.y <= 1

    speed: f32 = grounded ? 60 : 20
    state.vel += mat[0] * move.x * delta * speed
    state.vel += mat[2] * move.y * delta * speed

    if grounded && rv.key_pressed(.Space, buf = 0.2) {
        state.vel.y = 10
        grounded = false
    }

    state.vel.y -= delta * (state.vel.y < 0 ? 30 : 20)
    state.vel = rv.lexp(state.vel, 0, delta * 0.5)

    state.pos += state.vel * delta

    if grounded {
        state.pos.y = 0.9999
        state.vel = rv.lexp(state.vel, 0, delta * 8)
    }

    cam_pos := state.pos

    if grounded {
        cam_pos.y += 0.1 * math.sin_f32(rv.get_time() * 11) * rv.remap_clamped(linalg.length(state.vel.xz), 0, 2, 0, 1)
    }

    state.gun_pos = rv.lexp(state.gun_pos, cam_pos + mat * rv.Vec3{0.2, -0.1, 0.2}, delta * 100)

    rv.set_layer_params(0, rv.make_3d_perspective_camera(cam_pos, cam_rot, rv.deg(110)))
    rv.set_layer_params(1, rv.make_screen_camera())

    rv.bind_texture("default")
    rv.bind_depth_test(true)
    rv.bind_depth_write(true)
    rv.bind_fill(.All)

    rv.draw_mesh(
        rv.get_mesh("Cube"),
        state.gun_pos,
        rot = cam_rot,
        scale = {0.03, 0.05, 0.12},
    )

    rv.draw_mesh(
        state.terrain,
        0,
    )

    rv.draw_mesh(
        rv.get_mesh("Plane"),
        {0, 0, 0},
        scale = 25,
        col = rv.GRAY,
    )

    rv.bind_layer(1)

    rv.bind_texture("thick")
    rv.draw_text("Use WASD and QE to move, mouse to look", {14, 14, 0.1}, scale = math.ceil(rv._state.dpi_scale)) // DPI HACK
    rv.draw_text(fmt.tprint(rv._state.input.keys.buffered), {14, 200, 0.1}, scale = math.ceil(rv._state.dpi_scale)) // DPI HACK

    rv.upload_gpu_layers()
    rv.render_gpu_layer(0, rv.DEFAULT_RENDER_TEXTURE, rv.Vec3{0, 0, 0.1}, true)
    rv.render_gpu_layer(1, rv.DEFAULT_RENDER_TEXTURE, nil, false)

    return state
}