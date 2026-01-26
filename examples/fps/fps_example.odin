package raven_fps_example

import "core:math/linalg"
import "core:math"
import "core:fmt"
import rv "../.."
import "../../platform"

state: ^State

State :: struct {
    pos:    rv.Vec3,
    vel:    rv.Vec3,
    ang:    rv.Vec3,
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

    return state
}

_shutdown :: proc(prev: ^State) {
    free(prev)
}

_update :: proc(prev: ^State) -> ^State {
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

    cam_rot := rv.euler_rot(state.ang)
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

    rv.set_layer_params(0, rv.make_3d_perspective_camera(state.pos, cam_rot))
    rv.set_layer_params(1, rv.make_screen_camera())

    rv.bind_texture("default")

    rv.draw_mesh_by_handle(
        rv.get_mesh("Plane"),
        {0, 0, 0},
        scale = 25,
        col = rv.RED,
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