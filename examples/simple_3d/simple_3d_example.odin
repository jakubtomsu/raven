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

@export _module_desc := rv.Module_Desc {
    state_size = size_of(State),
    init = _init,
    shutdown = _shutdown,
    update = _update,
}

main :: proc() {
    rv.run_main_loop(_module_desc)
}

_init :: proc() {
    state = new(State)

    // TODO: FIXME: relative and non-relative mouse have inverted delta
    platform.set_mouse_relative(rv.get_window(), true)
    platform.set_mouse_visible(false)

    state.cam_pos = {1.5, 3, -8}
    state.cam_ang = {0.3, 0, 0}
}

_shutdown :: proc() {
    free(state)
}

_update :: proc(hot_state: rawptr) -> rawptr {
    if hot_state != nil {
        state = cast(^State)hot_state
    }

    if rv.key_pressed(.Escape) {
        rv.request_shutdown()
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

    state.cam_ang.xy += rv.mouse_delta().yx * {-1, 1} * 0.005
    state.cam_ang.x = clamp(state.cam_ang.x, -math.PI * 0.49, math.PI * 0.49)

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

    if rv.scope_binds() {
        rv.bind_texture("default")

        rv.draw_mesh(rv.get_mesh("Circle"), {-3, 0, 0}, col = rv.YELLOW)
        rv.draw_mesh(rv.get_mesh("Plane"), {0, 0, 0}, col = rv.GREEN)
        rv.draw_mesh(rv.get_mesh("Cube"), {3, 0, 0}, rv.quat_angle_axis(rv.get_time(), {0, 1, 0}), col = rv.GRAY, add_col = rv.WHITE * rv.nsin(rv.get_time()))
        rv.draw_mesh(rv.get_mesh("Icosphere"), {6, 0, 0}, col = rv.CYAN)
        rv.draw_mesh(rv.get_mesh("Cylinder"), {9, 0, 0}, scale = {1, 0.1 + rv.nsin(rv.get_time() * 0.5), 1}, col = rv.GRAY)

        rv.draw_triangle(
            pos = {
                rv.Vec3{-0.5, 0, 0} + {-6, 0, 0},
                rv.Vec3{ 0, 0.7, 0} + {-6, 0, 0},
                rv.Vec3{ 0.5, 0, 0} + {-6, 0, 0},
            },
            col = {
                {1, 0, 0},
                {0, 1, 0},
                {0, 0, 1},
            },
        )
    }

    rv.bind_layer(1)
    rv.bind_texture("thick")
    rv.bind_depth_test(true)
    rv.bind_depth_write(true)
    rv.draw_text("Use WASD and QE to move, mouse to look", {220, 18, 0.1}, scale = math.ceil(rv._state.dpi_scale)) // DPI HACK

    rv.draw_counter(.CPU_Frame_Ns, {15, 15, 0.1}, scale = 2, unit = 1e-6, col = rv.GREEN)

    rv.upload_gpu_layers()
    rv.render_gpu_layer(0, rv.DEFAULT_RENDER_TEXTURE, rv.Vec3{0, 0, 0.1}, true)
    rv.render_gpu_layer(1, rv.DEFAULT_RENDER_TEXTURE, nil, false)

    return state
}