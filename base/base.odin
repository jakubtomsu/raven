package raven_base

import "base:runtime"
import "ufmt"

// MARK: Log

Log_Level :: runtime.Logger_Level

log_err :: proc(format: string, args: ..any, loc := #caller_location) {
    log(.Error, format = format, args = args, loc = loc)
}

log_warn :: proc(format: string, args: ..any, loc := #caller_location) {
    log(.Warning, format = format, args = args, loc = loc)
}

log_info :: proc(format: string, args: ..any, loc := #caller_location) {
    log(.Info, format = format, args = args, loc = loc)
}

log_debug :: proc(format: string, args: ..any, loc := #caller_location) {
    log(.Debug, format = format, args = args, loc = loc)
}


log :: proc(level: Log_Level, format: string, args: ..any, loc := #caller_location) {
    logger := context.logger
    if level < logger.lowest_level {
        return
    }
    if logger.procedure == nil {
        return
    }
    runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()
    str := ufmt.tprintf(format = format, args = args)
    context.logger.procedure(logger.data, level, str, logger.options, location = loc)
}

// _logger_proc :: proc(logger_data: rawptr, level: runtime.Logger_Level, text: string, options: bit_set[runtime.Logger_Option], location := #caller_location) {
// }


// MARK: Module

// WARNING: this structure must match the one in build_hot.odin exactly,
// since it's passed between DLLs when hot-reloading.
Module_Desc :: struct {
    state_size: i64,
    init:       Module_Init_Proc,
    shutdown:   Module_Shutdown_Proc,
    update:     Module_Update_Proc,
}

// Called after internal init is done to let the app initialize.
Module_Init_Proc ::       #type proc()
// Called after request_shutdown() but before the engine cleans up.
Module_Shutdown_Proc ::   #type proc()
// Called every frame.
// Usually, hot_ptr is nil. But after a hotreload, hot_ptr is the last returned data_ptr.
// This way you can
Module_Update_Proc ::     #type proc(hot_ptr: rawptr) -> (data_ptr: rawptr)
