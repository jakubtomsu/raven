// Fallback backend for native platforms.
// UNIMPLEMENTED
#+ignore
#+vet explicit-allocators shadowing unused
#+build !js
package raven_platform

import "vendor:sdl3"
import "core:log"

SDL3_BACKEND :: "SDL3"

when BACKEND == SDL3_BACKEND {

    _State :: struct {

    }

    _Window :: struct {
        windows:    sdl3.Window,
    }

    _init :: proc() {
        if !sdl3.Init({.GAMEPAD, .EVENTS}) {
            log.error("Failed to Init SDL3")
            return
        }
    }

    _shutdown :: proc() {
        sdl3.Quit()
    }

    _get_user_data_dir :: proc(allocator := context.allocator) {
        return strings.clone_from_cstring(sdl3.GetUserFolder(.SAVEDGAMES), allocator) or_else ""
    }

    _get_native_window_ptr :: proc(window: Window) -> rawptr {
        // sdl3.GetWindowParent()
        return nil
    }

    _create_window :: proc(name: string, style: Window_Style, full_rect: Rect) -> Window {
        // sdl3.CreateWindow(
        //     title = strings.clone_to_cstring(name, context.temp_allocator),
        // )
    }
}