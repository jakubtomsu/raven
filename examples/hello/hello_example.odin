package raven_example_hello

import rv "../.."

state: ^State

State :: struct {
    // Commonly you would store ALL your game data here.
    // Everything has to be within this struct to allow for hotreloading, otherwise the data would get lost.
    some_data: u32,
}

// The main procedure is your app's entry point.
// But to support multiple platforms, Raven handles the frame update loop, only calling your module.
main :: proc() {
    // If you really want you can write your own main loop directly.
    rv.run_main_loop(_module_api())
}

// Module_API structure let's Raven know which procedures to call to init, update frame etc.
// The '@export' qualifier makes sure it's visible when running in hot-reload mode.
// The state_size is there for error checking.
@export _module_api :: proc "contextless" () -> (result: rv.Module_API) {
    result = {
        state_size = size_of(State),
        init = transmute(rv.Init_Proc)_init,
        shutdown = transmute(rv.Shutdown_Proc)_shutdown,
        update = transmute(rv.Update_Proc)_update,
    }
    return result
}

_init :: proc() -> ^State {
    state = new(State)
    rv.init_window("Raven Hello Example")
    return state
}

_shutdown :: proc(prev_state: ^State) {
    free(prev_state)
}

_update :: proc(prev_state: ^State) -> ^State {
    // This line ensures your global 'state' ptr points to the correct data even after hotreload.
    state = prev_state

    if rv.key_pressed(.Escape) {
        return nil
    }

    // Raven renders into "draw layers".
    // Layer 0 is the default one, so let's set up a regular screenspace view for it.
    rv.set_layer_params(0, rv.make_screen_camera())

    // To configure draw state like blending, textures, shaders, current layer, etc, call 'rv.bind_*'
    // You can also call push_binds/pop_binds to save and restore the bind state.
    rv.bind_texture("thick")

    // Odin strings are UTF-8 encoded, but fonts are currently CP437 16x16 atlases.
    // Unicode fonts might get supported later.
    rv.draw_text("Hello World! ☺", {200, 200, 0}, scale = 4, spacing = 1)

    // Draw the full font atlas texture
    rv.draw_sprite({rv.get_screen_size().x * 0.5, rv.get_screen_size().y * 0.5, 0.1}, scale = 2)

    // The 'rv.draw_*' commands only record what geometry you want to render each frame.
    // To actually display it on the screen you must first upload it to the GPU, and then
    // explicily render each layer into a particular render texture.
    rv.upload_gpu_layers()
    rv.render_gpu_layer(0, rv.DEFAULT_RENDER_TEXTURE, clear_color = rv.Vec3{0, 0, 0.5}, clear_depth = true)

    return state

}
