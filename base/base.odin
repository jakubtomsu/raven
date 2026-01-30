package raven_base

import "base:runtime"
import "ufmt"

// context.logger calls
// shared datastructures

log :: proc(level: runtime.Logger_Level, format: string, args: ..any, loc := #caller_location) {
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