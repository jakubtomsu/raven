#+build js
#+vet explicit-allocators shadowing unused
package raven_platform

import "core:log"
import "core:sys/wasm/js"

// NOTE: backend guard is not required on JS backend

// // NOTE: frame loop is done by the runtime.js repeatedly calling `step`.
// @(private="file", export)
// step :: proc(dt: f32) -> bool {
//     if !state.os.initialized {
//         return true
//     }

//     frame(dt)
//     return true
// }



_State :: struct {
    _: u8,
}

_File_Handle :: struct { _: u8 }
_File_Request :: struct { _: u8 }
_File_Watcher :: struct { _: u8 }
_Directory_Iter :: struct { _: u8 }
_Barrier :: struct { _: u8 }
_Thread :: struct { _: u8 }
_Window :: struct { _: u8 }
_Module :: struct { _: u8 }


/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// MARK: Common
//

_init :: proc() {
    for proc_ptr, kind in _js_event_callbacks {
        if proc_ptr == nil {
            continue
        }
        if !js.add_window_event_listener(kind, user_data = nil, callback = proc_ptr) {
            log.error("Failed to add '{}' event listener when initializing", kind)
        }
    }
}

_shutdown :: proc() {
    for proc_ptr, kind in _js_event_callbacks {
        if proc_ptr == nil {
            continue
        }
        if !js.remove_window_event_listener(kind, user_data = nil, callback = proc_ptr) {
            log.error("Failed to remove '{}' event listener when shutting down", kind)
        }
    }
}



@(require_results)
_get_commandline_args :: proc(allocator := context.allocator) -> []string {
    return nil
}

@(require_results)
_run_shell_command :: proc(command: string) -> int {
    return 0
}

_exit_process :: proc(code: int) -> ! {
    // HACK
    js.trap()
}

@(require_results)
_memory_protect :: proc(ptr: rawptr, num_bytes: int, protect: Memory_Protection) -> bool {
    return true
}

@(require_results)
_clipboard_set :: proc(data: []byte, format: Clipboard_Format = .Text) -> bool {
    _js_unsupported()
    return true
}

@(require_results)
_clipboard_get :: proc(format: Clipboard_Format = .Text, allocator := context.temp_allocator) -> ([]byte, bool) {
    _js_unsupported()
    return nil, false
}

@(require_results)
_get_gamepad_state :: proc(#any_int index: int) -> (result: Gamepad_State, ok: bool) {
    _js_unsupported()
    return {}, false
}

@(require_results)
_set_gamepad_feedback :: proc(#any_int index: int, output: Gamepad_Feedback) -> bool {
    _js_unsupported()
    return false
}


@(require_results)
_get_user_data_dir :: proc(allocator := context.allocator) -> string {
    _js_unsupported()
    return ""
}

_set_mouse_relative :: proc(window: Window, relative: bool) {
    _js_unsupported()
}

_set_mouse_visible :: proc(visible: bool) {
    _js_unsupported()
}

_set_dpi_aware :: proc() {
    _js_unsupported()
}

@(require_results)
_get_main_monitor_rect :: proc() -> Rect {
    return _get_window_frame_rect({})
}

@(require_results)
_set_current_directory :: proc(path: string) -> bool {
    _js_unsupported()
    return false
}

@(require_results)
_get_executable_path :: proc(allocator := context.temp_allocator) -> string {
    _js_unsupported()
    return ""
}

@(require_results)
_load_module :: proc(path: string) -> (result: Module, ok: bool) {
    _js_unsupported()
    return {}, false
}

_unload_module :: proc(module: Module) {
    _js_unsupported()
}

@(require_results)
_module_symbol_address :: proc(module: Module, cstr: cstring) -> (result: rawptr) {
    _js_unsupported()
    return nil
}

_sleep_ms :: proc(#any_int ms: int) {
    _js_unsupported()
}

@(require_results)
_get_time_ns :: proc() -> u64 {
    return u64(_tick_now() * 1e6)
}


/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// MARK: Thread
//

@(require_results)
_create_thread :: proc(procedure: Thread_Proc) -> Thread {
    _js_unsupported()
    return {}
}

_join_thread :: proc(thread: Thread) {
    _js_unsupported()
}

_set_thread_name :: proc(thread: Thread, name: string) {
    _js_unsupported()
}

@(require_results)
_get_current_thread :: proc() -> Thread {
    _js_unsupported()
    return {}
}

@(require_results)
_get_current_thread_id :: proc() -> u64 {
    _js_unsupported()
    return 0
}



/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// MARK: Window
//

@(require_results)
_create_window :: proc(name: string, style: Window_Style = .Regular, full_rect: Rect = {}) -> Window {
    _js_unsupported()
    return {}
}

_destroy_window :: proc(window: Window) {
    _js_unsupported()
}

@(require_results)
_window_dpi_scale :: proc(window: Window) -> f32 {
    // _js_unsupported()
    return 1.0
}

_set_window_style :: proc(window: Window, style: Window_Style) {
    _js_unsupported()
}

_set_window_pos :: proc(window: Window, pos: [2]i32) {
    _js_unsupported()
}

_set_window_size :: proc(window: Window, size: [2]i32) {
    _js_unsupported()
}

@(require_results)
_get_window_frame_rect :: proc(window: Window) -> Rect {
    rect := js.get_bounding_client_rect("body")
    dpi := js.device_pixel_ratio()
    return {
        min = 0,
        size = {
            i32(f64(rect.width) * dpi),
            i32(f64(rect.height) * dpi),
        },
    }
}

@(require_results)
_get_window_full_rect :: proc(window: Window) -> Rect {
    return _get_window_frame_rect(window)
}

_set_mouse_pos_window_relative :: proc(window: Window, pos: [2]i32) {
    _js_unsupported()
}

@(require_results)
_is_window_minimized :: proc(window: Window) -> bool {
    _js_unsupported()
    return false
}

@(require_results)
_is_window_focused :: proc(window: Window) -> bool {
    _js_unsupported()
    return true
}

@(require_results)
_get_native_window_ptr :: proc(window: Window) -> rawptr {
    return nil
}

@(require_results)
_poll_window_events :: proc(window: Window) -> (ok: bool) {
    return false
}



////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// MARK: Barrier
//

@(require_results)
_barrier_create :: proc(num_threads: int) -> (result: Barrier) {
    _js_unsupported()
    return {}
}

_barrier_delete :: proc(barrier: ^Barrier) {
    _js_unsupported()
}

_barrier_sync :: proc(barrier: ^Barrier) {
    _js_unsupported()
}



////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// MARK: File IO
//

@(require_results)
_open_file :: proc(path: string) -> (File_Handle, bool) {
    _js_unsupported()
    return {}, false
}

_close_file :: proc(handle: File_Handle) {
}

@(require_results)
_get_last_write_time :: proc(handle: File_Handle) -> (u64, bool) {
    _js_unsupported()
    return 0, false
}

@(require_results)
_delete_file :: proc(path: string) -> bool {
    _js_unsupported()
    return false
}

@(require_results)
_read_file_by_path :: proc(path: string, allocator := context.allocator) -> (data: []byte, ok: bool) {
    _js_unsupported()
    return nil, false
}

@(require_results)
_write_file_by_path :: proc(path: string, data: []u8) -> bool {
    _js_unsupported()
    return false
}

@(require_results)
_file_exists :: proc(path: string) -> bool {
    _js_unsupported()
    return false
}

@(require_results)
_clone_file :: proc(path: string, new_path: string, fail_if_exists := true) -> bool {
    _js_unsupported()
    return false
}

@(require_results)
_read_file_by_path_async :: proc(path: string, allocator := context.allocator) -> (file: File_Request, ok: bool) {
    _js_unsupported()
    return {}, false
}

@(require_results)
_file_request_wait :: proc(file: ^File_Request) -> (buffer: []byte, ok: bool) {
    _js_unsupported()
    return {}, false
}

@(require_results)
_create_directory :: proc(path: string) -> bool {
    _js_unsupported()
    return false
}

@(require_results)
_is_file :: proc(path: string) -> bool {
    return false
}

@(require_results)
_is_directory :: proc(path: string) -> bool {
    return false
}

@(require_results)
_get_directory :: proc(path: string, buf: []string) -> []string {
    return nil
}

@(require_results)
_iter_directory :: proc(iter: ^Directory_Iter, pattern: string, allocator := context.temp_allocator) -> (result: string, ok: bool) {
    return "", false
}

@(require_results)
_init_file_watcher :: proc(watcher: ^File_Watcher, path: string, recursive := false) -> bool {
    return false
}

@(require_results)
_watch_file_changes :: proc(watcher: ^File_Watcher) -> []string {
    return nil
}

_destroy_file_watcher :: proc(watcher: ^File_Watcher) {
}

@(require_results)
_file_dialog :: proc(mode: File_Dialog_Mode, default_path: string, patterns: []File_Pattern, title := "") -> (string, bool) {
    // TODO
    _js_unsupported()
    return {}, false
}


////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// MARK: Internal
//

_js_unsupported :: proc(loc := #caller_location) {
    // NOTE: this doesn't mean it won't be implemented at some point if possible.
    // log.warnf("'%s' is not supported on JS target", loc.procedure, location = loc)
}


_JS_Event_Callback :: #type proc(event: js.Event)

@(rodata)
_js_event_callbacks := [js.Event_Kind]_JS_Event_Callback {
    .Invalid = nil,
    .Load = nil,
    .Unload = nil,
    .Error = nil,

    .Resize = proc(e: js.Event) {
        _event_queue_push(Event_Window_Size{
            size = _get_window_frame_rect({}).size,
        })
    },

    .Visibility_Change = nil,
    .Fullscreen_Change = nil,
    .Fullscreen_Error = nil,
    .Click = nil,
    .Double_Click = nil,
    .Mouse_Move = nil,
    .Mouse_Over = nil,
    .Mouse_Out = nil,
    .Mouse_Up = nil,
    .Mouse_Down = nil,
    .Key_Up = nil,
    .Key_Down = nil,
    .Key_Press = nil,
    .Scroll = nil,
    .Wheel = nil,
    .Focus = nil,
    .Focus_In = nil,
    .Focus_Out = nil,
    .Submit = nil,
    .Blur = nil,
    .Change = nil,
    .Hash_Change = nil,
    .Select = nil,
    .Animation_Start = nil,
    .Animation_End = nil,
    .Animation_Iteration = nil,
    .Animation_Cancel = nil,
    .Copy = nil,
    .Cut = nil,
    .Paste = nil,
    .Pointer_Cancel = nil,
    .Pointer_Down = nil,
    .Pointer_Enter = nil,
    .Pointer_Leave = nil,
    .Pointer_Move = nil,
    .Pointer_Over = nil,
    .Pointer_Up = nil,
    .Got_Pointer_Capture = nil,
    .Lost_Pointer_Capture = nil,
    .Pointer_Lock_Change = nil,
    .Pointer_Lock_Error = nil,
    .Selection_Change = nil,
    .Selection_Start = nil,
    .Touch_Cancel = nil,
    .Touch_End = nil,
    .Touch_Move = nil,
    .Touch_Start = nil,
    .Transition_Start = nil,
    .Transition_End = nil,
    .Transition_Run = nil,
    .Transition_Cancel = nil,
    .Context_Menu = nil,
    .Gamepad_Connected = nil,
    .Gamepad_Disconnected = nil,
    .Custom = nil,
}


foreign import "odin_env"

foreign odin_env {
    @(link_name="time_now")     _time_now :: proc "contextless" () -> i64 ---
    @(link_name="tick_now")     _tick_now :: proc "contextless" () -> f64 ---
}
