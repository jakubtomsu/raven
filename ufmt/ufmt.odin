// Micro-fmt
//
// Extremely stripped down `core:fmt` replacement.
// Supports only %s, %f, %i, %x, %%
// NOTE: curly braces don't need to be doubled ({{ and }}) like in `core:fmt`
//
// By Jakub Tomšů
// Read <link> for more info.
package ufmt

import "base:runtime"

printf :: proc(format: string, args: ..any) {
    runtime.print_string(tprintf(format = format, args = args))
}

printfln :: proc(format: string, args: ..any) {
    runtime.print_string(tprintf(format = format, args = args))
    runtime.print_byte('\n')
}

tprintf :: proc(format: string, args: ..any) -> string {
    curr := format

    buf := make([dynamic]byte, 0, len(format) + 256, context.temp_allocator)

    curr_arg := 0

    for len(curr) > 0 {
        r, r_size := runtime.string_decode_rune(curr)

        if r != '%' {
            append_elems(&buf, ..transmute([]byte)curr[:r_size])
            curr = curr[r_size:]
            continue
        }

        curr = curr[r_size:]

        if len(curr) == 0 {
            return "<INVALID FORMAT>"
        }

        if curr_arg >= len(args) {
            return "<NOT ENOUGH ARGS>"
        }

        qual, qual_size := runtime.string_decode_rune(curr)
        curr = curr[qual_size:]

        arg := args[curr_arg]

        consume_arg := true
        switch qual {
        case 's':
            switch val in arg {
            case string:  append_elem_string(&buf, val)
            case cstring: append_elem_string(&buf, string(val))
            case: return "<NOT STRING>"
            }

        case 'i':
            switch val in arg {
            case u8:    _append_int(&buf, int(val))
            case i8:    _append_int(&buf, int(val))
            case u16:   _append_int(&buf, int(val))
            case i16:   _append_int(&buf, int(val))
            case u32:   _append_int(&buf, int(val))
            case i32:   _append_int(&buf, int(val))
            case u64:   _append_int(&buf, int(val))
            case i64:   _append_int(&buf, int(val))
            case uint:  _append_int(&buf, int(val))
            case int:   _append_int(&buf, int(val))
            case: return "<NOT INT>"
            }

        case 'x':
            switch val in arg {
            case u8:    _append_hex(&buf,      cast(u64)val, size_of(val))
            case i8:    _append_hex(&buf,      cast(u64)val, size_of(val))
            case u16:   _append_hex(&buf,      cast(u64)val, size_of(val))
            case i16:   _append_hex(&buf,      cast(u64)val, size_of(val))
            case u32:   _append_hex(&buf,      cast(u64)val, size_of(val))
            case i32:   _append_hex(&buf,      cast(u64)val, size_of(val))
            case u64:   _append_hex(&buf,               val, size_of(val))
            case i64:   _append_hex(&buf, transmute(u64)val, size_of(val))
            case uint:  _append_hex(&buf,      cast(u64)val, size_of(val))
            case int:   _append_hex(&buf,      cast(u64)val, size_of(val))
            case: return "<NOT INT>"
            }

        case 'f':
            switch val in arg {
            case f16: _append_float(&buf, f64(val))
            case f32: _append_float(&buf, f64(val))
            case f64: _append_float(&buf, f64(val))
            case: return "<NOT FLOAT>"
            }

        case '%':
            append_elem(&buf, '%')
            consume_arg = false

        case:
            return "<UNKNOWN SPECIFIER>"
        }

        if consume_arg {
            curr_arg += 1
        }
    }

    return string(buf[:])
}

_append_int :: proc(buf: ^[dynamic]byte, value: int) {
    val := value
    if val < 0 {
        append_elem(buf, '-')
        val = -val
    }

    if val == 0 {
        append_elem(buf, '0')
    }

    temp: [32]u8
    temp_index := len(temp) - 1
    for val != 0 {
        rem := val % 10
        val /= 10
        temp[temp_index] = u8('0' + rem)
        temp_index -= 1
    }

    append_elems(buf, ..cast([]u8)temp[temp_index + 1:])
}

_append_hex :: proc(buf: ^[dynamic]byte, value: u64, size: int) {
    val := value

    append_elem_string(buf, "0x")

    shift := (size * 8) - 4

    for shift >= 0 {
        d := (value >> uint(shift)) & 0xf
        if d < 10 {
            append_elem(buf, u8('0' + d))
        } else {
            append_elem(buf, u8('a' + (d - 10)))
        }
        shift -= 4
    }
}

_append_float :: proc(buf: ^[dynamic]byte, value: f64) {
    val := value
    if val < 0 {
        append_elem(buf, '-')
        val = -val
    }

    if value != value {
        append_elem_string(buf, "NaN")
        return
    }

    if value > max(f64) || value < -max(f64) {
        append_elem_string(buf, "Inf")
        return
    }


    scaled := i64(val * 1000.0 + 0.5)
    ip := scaled / 1000
    fp := scaled % 1000

    _append_int(buf, int(ip))

    // Always 3 decimal places
    append_elem(buf, '.')
    append_elem(buf, byte('0' + int(fp / 100) % 10))
    append_elem(buf, byte('0' + int(fp / 10 ) % 10))
    append_elem(buf, byte('0' + int(fp / 1  ) % 10))
}

// TODO: support very simple RTTI traversal
