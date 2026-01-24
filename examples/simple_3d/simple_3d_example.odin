package raven_simple_3d_example

import "core:log"
import "core:math/linalg"
import "core:math"
import rv "../.."
import "../../platform"

state: ^State

State :: struct {
    cam_pos:    rv.Vec3,
    cam_ang:    rv.Vec3,
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

    rv.init_window("Simple 3D Example")
    // TODO: FIXME: relative and non-relative mouse have inverted delta
    platform.set_mouse_relative(rv._state.window, true)
    platform.set_mouse_visible(false)

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

    move: rv.Vec3
    if rv.key_down(.D) do move.x += 1
    if rv.key_down(.A) do move.x -= 1
    if rv.key_down(.W) do move.z += 1
    if rv.key_down(.S) do move.z -= 1
    if rv.key_down(.E) do move.y += 1
    if rv.key_down(.Q) do move.y -= 1

    state.cam_ang.xy += rv.mouse_delta() * 0.005
    // state.cam_ang.y = clamp(state.cam_ang.y, -math.PI * 0.49, math.PI * 0.49)

    cam_rot := rv.euler_rot(state.cam_ang)
    mat := linalg.matrix3_from_quaternion_f32(cam_rot)

    speed: f32 = 1.0
    if rv.key_down(.Left_Shift) {
        speed *= 10
    } else if rv.key_down(.Left_Control) {
        speed *= 0.1
    }

    state.cam_pos += mat[0] * move.x * delta * speed
    state.cam_pos += mat[2] * move.z * delta * speed
    state.cam_pos.y += move.y * delta * speed

    rv.set_layer_params(0, rv.make_3d_perspective_camera(state.cam_pos, cam_rot))
    rv.set_layer_params(1, rv.make_screen_camera())

    rv.bind_depth_test(true)
    rv.bind_depth_write(true)
    rv.bind_texture("thick")
    rv.bind_blend(.Opaque)

    // for i in 0..<100 {
    //     rv.draw_sprite({1, f32(i), f32(i) + 10}, scale = 0.1)
    // }

    // rv.draw_triangle(
    //     {{0, 0, 0}, {10, 0, 0}, {0, 10, 0}},
    //     col = rv.ORANGE.rgb,
    // )

    if rv.scope_binds() {
        rv.bind_texture("default")

        rv.draw_mesh_by_handle(rv.get_mesh("Plane"), {0, 0, 0})
        rv.draw_mesh_by_handle(rv.get_mesh("Cube"), {3, 0, 0})
        rv.draw_mesh_by_handle(rv.get_mesh("Icosphere"), {6, 0, 0})
        rv.draw_mesh_by_handle(rv.get_mesh("Cylinder"), {9, 0, 0})
    }

    // rv.draw_line(0, {0, math.sin_f32(rv.get_time()) * 5, 10}, 1)

    rv.bind_layer(1)
    rv.bind_depth_test(true)
    rv.bind_depth_write(true)
    rv.draw_text("Use WASD and QE to move", {200, 14, 0.1})

    rv.draw_counter(.CPU_Frame_Ns, {10, 10, 0.1}, scale = 2, unit = 1e-6, col = rv.GREEN)

    rv.upload_gpu_layers()
    rv.render_gpu_layer(0, rv.DEFAULT_RENDER_TEXTURE, rv.Vec3{0, 0, 0.1}, true)
    rv.render_gpu_layer(1, rv.DEFAULT_RENDER_TEXTURE, nil, false)

    return state
}