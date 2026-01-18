#+vet explicit-allocators shadowing style
#+feature dynamic-literals
package shaderprep

// https://github.com/gingerBill/titania

import "core:reflect"
import "core:odin/tokenizer"
import "base:builtin"
import "core:strconv"
import "core:strings"
import "core:fmt"
import "core:io"
import "../platform"

EXT :: ".rvsl"

Stage :: enum u8 {
    None,
    Vertex,
    Pixel,
    Compute,
}

Target :: enum u8 {
    HLSL,
    GLSL,
}

Parser :: struct {
    tokenizer:  Tokenizer,
    prev_token: Token,
    curr_token: Token,
    // Sub buffer let us fill in gaps
    output:     [dynamic][dynamic]u8,
}

Struct :: struct {
    pos:    Pos,
    fields: [dynamic]Struct_Field,
}

Struct_Field :: struct {
    name:   string,
    type:   Type,
}

Basic_Type :: enum u8 {
    Int,
    UInt,
    Float,
    Bool,
}

Type_Kind :: enum u8 {
    Basic,
    Vector,
    Matrix,
}

Type :: struct {
    kind:   Type_Kind,
    basic:  Basic_Type,
    len:    u8,
}


Input_File :: struct {
    full_path:  string, // for error reporting
    code:       string,
}

Builtin :: enum {
    include,
    define,

    vs,
    ps,
    cs,

    target,
    depth,
    depth_le,
    depth_ge,

    // implicit variables

    vert_id,
    inst_id,
    vert_pos,
    frontface,
    dispatch_id,
    thread_id,

    // calls

    texture_sample,
    texture_load,
    texture_store,

    // slot resources

    constants,

    ro_texture2d,
    ro_texture2d_array,
    ro_texture3d,
    ro_buffer,

    rw_buffer,
    rw_texture2d,
    rw_texture2d_array,
    rw_texture3d,
}

_builtin_table: map[string]Builtin

// Initialize the global compiler state.
// Must be called before everything else.
init :: proc() {
    for b in Builtin {
        str := strings.to_lower(reflect.enum_string(b), context.temp_allocator)
        _builtin_table[fmt.tprintf("@%v", str)] = b
    }
}

Options :: struct {
    target:         Target,
    line_markers:   bool,
    whitespace:     bool,
    include_proc:   Include_Proc,
    include_user:   rawptr,
}

File :: struct {
    stage:              Stage,
    state:              File_State,
    code:               string,
    // includes:   map[string]struct{},
    resources:          map[string]Resource,
    resource_samples:   map[[2]string]struct{},
}

Resource :: struct {
    slot:       i32,
    base_slot:  i32,
    subbuf:     i32,
}

Include_Proc :: #type proc(opts: Options, path: string) -> (File, bool)

// Files can only include other shader files without an entry point.
// This combined with our "macros" being very stateless means
// it's fine to compile the files in any order.
Unit :: struct {
    opts:       Options,
    input:      map[string]Input_File,
    output:     map[string]File,
}

unit_include_proc :: proc(opts: Options, path: string) -> (File, bool) {
    unit := cast(^Unit)opts.include_user

    // TODO: prevent infinite recursion loop

    // Check if compiled already
    if output, output_ok := unit.output[path]; output_ok {
        if output.stage != .None {
            // Error
            return {}, false
        }

        return output, true
    }

    // Try compile
    if input, input_ok := unit.input[path]; input_ok {
        file := process_file(input.full_path, input.code, unit.opts, allocator = context.allocator)
        assert(path not_in unit.output)
        unit.output[path] = file

        if file.stage == .None {
            return file, true
        }
    }

    // Invalid path
    return {}, false
}

process_unit :: proc(
    input_files:    map[string]Input_File,
    opts:           Options,
    allocator       := context.allocator,
) -> (unit: Unit) {
    context.allocator = allocator

    opts := opts

    unit = {
        input = input_files,
        opts = opts,
    }

    opts.include_proc = unit_include_proc
    opts.include_user = &unit

    for name, file in input_files {
        if name in unit.output {
            continue
        }
        file := process_file(file.full_path, file.code, opts, allocator = allocator)
        unit.output[name] = file
    }

    return unit
}

// NUMERIC CONSTANTS ONLY ATM
File_State :: struct {
    structs:    map[string]Struct,
    defines:    map[string]Define,
}

Define :: struct {
    val:    i64,
}

// Overwrites prev
file_state_include :: proc(parser: ^Parser, dst: ^File_State, src: File_State) {
    for k, v in src.structs {
        if existing, existing_ok := dst.structs[k]; existing_ok {
            error(v.pos, "vs_out '{}' already defined at %s(%i:%i)",
                existing.pos.path,
                existing.pos.line,
                existing.pos.column,
            )
        }
        dst.structs[k] = v
    }

    for k, v in src.defines {
        dst.defines[k] = v
    }
}

@(require_results, optimization_mode="favor_size")
process_file :: proc(
    filename:   string,
    code:       string,
    opts:       Options,
    allocator   := context.allocator,
) -> (result: File) {
    assert(filename != "")

    parser: Parser = {
        tokenizer = make_tokenizer(
            filename = filename,
            data = code,
        ),
    }

    switch opts.target {
    case .HLSL:

    case .GLSL:
        // emit_str(&parser, "#version 300 es")
    }

    parser_next(&parser)

    prev_line := 0

    emit_new_subbuf(&parser)

    for {
        tok := parser_next(&parser)

        if tok.kind == .EOF {
            break
        }

        if opts.line_markers {
            if prev_line != parser.tokenizer.line {
                prev_line = parser.tokenizer.line
                emit_str(&parser, fmt.tprintfln("\n#line %i \"%s\"", prev_line, filename))
            }
        }

        if opts.whitespace && tok.kind != .Semicolon {
            emit_str(&parser, tok.whitespace)
        }

        #partial switch tok.kind {
        case .Invalid:
            assert(false)

        case .EOF:
            assert(false)

        case:
            // Direct token passthru by default
            emit_str(&parser, tok.text)

        case .Builtin:

            builtin_kind, builtin_ok := _builtin_table[tok.text]

            if !builtin_ok {
                for k, v in _builtin_table {
                    fmt.println(k, v)
                }
                error(tok.pos, "Invalid builtin: {}", tok.text)
            }

            switch builtin_kind {
            case .include:
                path_tok := parser_expect(&parser, .String)
                parser_expect(&parser, .Semicolon)

                path := unquote(path_tok.text)

                if opts.include_proc == nil {
                    error(path_tok.pos, "Include builtin is not allowed")
                }

                included, included_ok := opts.include_proc(opts, path)

                if !included_ok {
                    // TODO: better error msg
                    error(path_tok.pos, "Cannot include '%s'", path)
                }

                assert(included.stage == .None)

                file_state_include(&parser, dst = &result.state, src = included.state)

                emit_str(&parser, included.code)

            case .define:
                name_tok := parser_expect(&parser, .Ident)
                val_tok := parser_expect(&parser, .Integer)

                def: Define
                def.val = i64(tok_to_int(&parser, val_tok))

                result.state.defines[name_tok.text] = def

            case .texture_sample:
                parser_expect(&parser, .Open_Paren)
                tex_tok := parser_expect(&parser, .Ident)
                parser_expect(&parser, .Comma)

                switch opts.target {
                case .HLSL:
                    emit_str(&parser, fmt.tprintf("%s.Sample(%s, __%s_smp",
                        tex_tok.text,
                        tex_tok.text,
                    ))

                case .GLSL:
                    emit_str(&parser, fmt.tprintf("texture(%s",
                        tex_tok.text,
                    ))
                }

                parse_expr_passthrough(&parser, opts, .Close_Paren)
                parser_expect(&parser, .Close_Paren)

                emit_str(&parser, ")")

            case .texture_load:
                unimplemented()

            case .texture_store:
                unimplemented()

            case .target,
                 .depth,
                 .depth_le,
                 .depth_ge:
                 error(tok, "Builtin {} is invalid in this context", tok.text)

            case .vert_id:
                if result.stage != .Vertex {
                    error(tok.pos, "{} is not available in {} stage", tok.text, result.stage)
                }

                switch opts.target {
                case .HLSL: emit_str(&parser, "__vert_id")
                case .GLSL: emit_str(&parser, "gl_VertexID")
                }

            case .inst_id:
                if result.stage != .Vertex {
                    error(tok.pos, "{} is not available in {} stage", tok.text, result.stage)
                }

                switch opts.target {
                case .HLSL: emit_str(&parser, "__inst_id")
                case .GLSL: emit_str(&parser, "gl_InstanceID")
                }

            case .vert_pos:
                if result.stage != .Pixel && result.stage != .Vertex {
                    error(tok.pos, "{} is not available in {} stage", tok.text, result.stage)
                }

                switch opts.target {
                case .HLSL: emit_str(&parser, "__vert_pos")
                case .GLSL: emit_str(&parser, "gl_Position")
                }

            case .frontface:
                if result.stage != .Pixel {
                    error(tok.pos, "{} is not available in {} stage", tok.text, result.stage)
                }

                switch opts.target {
                case .HLSL: emit_str(&parser, "__frontface")
                case .GLSL: emit_str(&parser, "gl_FrontFacing")
                }

            case .dispatch_id:
                if result.stage != .Compute {
                    error(tok.pos, "{} is not available in {} stage", tok.text, result.stage)
                }

                switch opts.target {
                case .HLSL: emit_str(&parser, "__dispatch_id")
                case .GLSL: emit_str(&parser, "gl_WorkGroupID")
                }

            case .thread_id:
                if result.stage != .Compute {
                    error(tok.pos, "{} is not available in {} stage", tok.text, result.stage)
                }

                switch opts.target {
                case .HLSL: emit_str(&parser, "__thread_id")
                case .GLSL: emit_str(&parser, "gl_LocalInvocationID")
                }


            case .ro_texture2d,
                 .ro_texture2d_array,
                 .ro_texture3d,
                 .rw_texture2d,
                 .rw_texture2d_array,
                 .rw_texture3d,
                 .ro_buffer,
                 .rw_buffer:

                slot, slot_base := parse_resource_slot(&parser, result.state)

                typename := parser_expect(&parser, .Ident)
                ident := parser_expect(&parser, .Ident)
                parser_expect(&parser, .Semicolon)

                type, type_ok := translate_typename(typename.text, opts.target)
                if !type_ok && builtin_kind != .ro_buffer && builtin_kind != .rw_buffer {
                    error(typename.pos, "Invalid texture type: {}", typename.text)
                }

                switch opts.target {
                case .HLSL:
                    res_name: string
                    #partial switch builtin_kind {
                    case .ro_texture2d:
                        res_name = "Texture2D"
                    case .ro_texture2d_array:
                        res_name = "Texture2DArray"
                    case .ro_texture3d:
                        res_name = "Texture3D"
                    case .rw_texture2d:
                        res_name = "RWTexture2D"
                    case .rw_texture2d_array:
                        res_name = "RWTexture2DArray"
                    case .rw_texture3d:
                        res_name = "RWTexture3D"
                    case .ro_buffer:
                        res_name = "StructuredBuffer"
                    case .rw_buffer:
                        res_name = "RWStructuredBuffer"
                    case: assert(false)
                    }

                    emit_str(&parser, fmt.tprintf("%s<%s> %s : register(t%i);\n",
                        res_name,
                        type,
                        ident.text,
                        slot + slot_base,
                    ))

                    if builtin_kind != .ro_buffer && builtin_kind != .rw_buffer {
                        emit_str(&parser, fmt.tprintf("SamplerState __%s_smp : register(s%i);\n",
                            ident.text,
                            slot_base + slot,
                        ))
                    }

                case .GLSL:
                    #partial switch builtin_kind {
                    case .ro_buffer, .rw_buffer:
                        qual := builtin_kind == .ro_buffer ? "readonly" : ""

                        emit_str(&parser, fmt.tprintf(
                            "layout(std430, binding=%i) restrict %s buffer __%s_buf {{ %s %s[]; }}",
                            slot + slot_base,
                            qual,
                            ident.text,
                            type,
                            ident.text,
                        ))

                    case .ro_texture2d,
                         .ro_texture2d_array,
                         .ro_texture3d:

                        res_name: string
                        format: string
                        #partial switch builtin_kind {
                        case .ro_texture2d:
                            res_name = "sampler2D"
                        case .ro_texture2d_array:
                            res_name = "sampler2DArray"
                        case .ro_texture3d:
                            res_name = "sampler3D"
                        case: assert(false)
                        }

                        emit_str(&parser, fmt.tprintf(
                            "layout(binding=%i) %s %s;\n",
                            slot + slot_base,
                            res_name,
                            ident.text,
                        ))

                    case .rw_texture2d,
                         .rw_texture2d_array,
                         .rw_texture3d:

                        res_name: string
                        format: string
                        #partial switch builtin_kind {
                        case .rw_texture2d:
                            res_name = "image2D"
                        case .rw_texture2d_array:
                            res_name = "image2DArray"
                        case .rw_texture3d:
                            res_name = "image3D"
                        case: assert(false)
                        }

                        // HACK
                        // TODO: intermmediate type num?
                        switch type {
                        case "float": format = "r32f"
                        case "int": format = "r32i"
                        case "uint": format = "r32ui"
                        case "vec4": format = "rgba32f"
                        case "ivec4": format = "rgba32i"
                        case "uvec4": format = "rgba32ui"
                        }

                        emit_str(&parser, fmt.tprintf(
                            "layout(binding=%i, %s) uniform %s %s",
                            slot + slot_base,
                            ident.text,
                            ident.text,
                        ))


                    case:
                        assert(false)
                    }
                }

                res: Resource = {
                    slot = i32(slot),
                    base_slot = i32(slot_base),
                    subbuf = i32(emit_new_subbuf(&parser)),
                }

                if ident.text in result.resources {
                    error(ident, "Resource '{}' already defined", ident.text)
                }

                result.resources[ident.text] = res


            case .constants:
                slot, slot_base := parse_resource_slot(&parser, result.state)

                ident := parser_expect(&parser, .Ident)
                parser_expect(&parser, .Open_Brace)

                switch opts.target {
                case .HLSL:
                    emit_str(&parser, fmt.tprintf("cbuffer %s : register(b%i) {{\n",
                        ident.text,
                        slot + slot_base,
                    ))

                case .GLSL:
                    emit_str(&parser, fmt.tprintf("layout(std140, binding=%i) uniform %s {{\n",
                        slot + slot_base,
                        ident.text,
                    ))
                }

                for {
                    if parser_allow(&parser, .Close_Brace) {
                        break
                    }

                    field_type := parser_expect(&parser, .Ident)
                    field_name := parser_expect(&parser, .Ident)
                    parser_expect(&parser, .Semicolon)

                    emit_str(&parser, fmt.tprintf("    %s %s;\n",
                        translate_typename(field_type.text, opts.target), field_name.text))
                }

                emit_str(&parser, "}")

            case .vs:
                if result.stage != .None {
                    error(tok, "A file cannot contain multiple shader entry points")
                }
                result.stage = .Vertex

                parser_expect(&parser, .Open_Paren)
                vert := parser_expect(&parser, .Ident)
                parser_expect(&parser, .Close_Paren)
                parser_allow(&parser, .Semicolon)

                stru, stru_ok := result.state.structs[vert.text]

                if !stru_ok {
                    error(vert, "{} is not a valid vs_out", vert.text)
                }

                // Preamble
                switch opts.target {
                case .HLSL:
                    emit_str(&parser, "void __vs_main(\n")
                    emit_str(&parser, "    in uint __vert_id : SV_VertexID,\n")
                    emit_str(&parser, "    in uint __inst_id : SV_InstanceID,\n")
                    emit_str(&parser, "    out float4 __vert_pos : SV_Position,\n")

                case .GLSL:
                }

                for field, i in stru.fields {
                    typename, typename_ok := type_to_target(field.type, opts.target)

                    if !typename_ok {
                        error(vert, "Type '{}' is not valid as a VS-out parameter")
                    }

                    switch opts.target {
                    case .HLSL:
                        emit_str(&parser, fmt.tprintf("    out %s %s : TEXCOORD%i,\n",
                            typename,
                            field.name,
                            i,
                        ))

                    case .GLSL:
                        emit_str(&parser, fmt.tprintf("layout(location=%i) out %s %s;\n",
                            i,
                            typename,
                            field.name,
                        ))
                    }
                }

                switch opts.target {
                case .HLSL:
                    emit_str(&parser, ")")

                case .GLSL:
                    emit_str(&parser, "void main()")
                }

            case .ps:
                if result.stage != .None {
                    error(tok, "A file cannot contain multiple shader entry points")
                }
                result.stage = .Pixel

                parser_expect(&parser, .Open_Paren)
                vert := parser_expect(&parser, .Ident)
                parser_expect(&parser, .Close_Paren)
                parser_allow(&parser, .Semicolon)

                stru, stru_ok := result.state.structs[vert.text]

                if !stru_ok {
                    error(vert, "{} is not a valid vs_out", vert.text)
                }

                // Preamble
                switch opts.target {
                case .HLSL:
                    emit_str(&parser, "void __ps_main(\n")
                    emit_str(&parser, "    in uint __frontface : SV_IsFrontFace,\n")
                    emit_str(&parser, "    in float4 __vert_pos : SV_Position,\n")

                case .GLSL:
                }

                for field, i in stru.fields {
                    typename, typename_ok := type_to_target(field.type, opts.target)

                    if !typename_ok {
                        error(vert, "Type '{}' is not valid as a VS-in parameter")
                    }

                    switch opts.target {
                    case .HLSL:
                        emit_str(&parser, fmt.tprintf("    out %s %s : TEXCOORD%i,\n",
                            typename,
                            field.name,
                            i,
                        ))

                    case .GLSL:
                        emit_str(&parser, fmt.tprintf("layout(location=%i) in %s %s;\n",
                            i,
                            field.type,
                            field.name,
                        ))
                    }
                }

                switch opts.target {
                case .HLSL:
                    emit_str(&parser, ")")

                case .GLSL:
                    emit_str(&parser, "void main()")
                }

                has_depth := false
                has_slots: bit_set[0..<64]

                for rt_index := 0;; rt_index += 1{
                    if parser_allow(&parser, .Open_Brace) {
                        break
                    }

                    if rt_index > 0 {
                        parser_expect(&parser, .Semicolon)
                    }

                    rt_tok := parser_expect(&parser, .Builtin)

                    rt_kind, rt_ok := _builtin_table[rt_tok.text]
                    if !rt_ok {
                        error(rt_tok, "Invalid builtin")
                    }

                    #partial switch rt_kind {
                    case .target:
                        parser_expect(&parser, .Open_Paren)
                        slot_tok := parser_expect(&parser, .Integer)
                        parser_expect(&parser, .Close_Paren)
                        type_tok := parser_expect(&parser, .Ident)
                        name_tok := parser_expect(&parser, .Ident)

                    case .depth, .depth_le, .depth_ge:
                        has_depth = true

                        type_tok := parser_expect(&parser, .Ident)
                        name_tok := parser_expect(&parser, .Ident)

                        if type_tok.text != "float" {
                            error(type_tok, "Depth output must be a float")
                        }

                    case:
                        error(rt_tok, "Builtin {} is not valid in pixel shader output declaration context", rt_tok.text)
                    }
                }

                emit_str(&parser, " {")

            case .cs:
                if result.stage != .None {
                    error(tok, "A file cannot contain multiple shader entry points")
                }
                result.stage = .Compute

                parser_expect(&parser, .Open_Paren)
                size_x := parser_expect(&parser, .Integer)
                parser_expect(&parser, .Comma)
                size_y := parser_expect(&parser, .Integer)
                parser_expect(&parser, .Comma)
                size_z := parser_expect(&parser, .Integer)
                parser_expect(&parser, .Close_Paren)
            }

        case .Struct:

            ident := parser_expect(&parser, .Ident)
            parser_expect(&parser, .Open_Brace)

            if _, existing_ok := result.state.structs[ident.text]; existing_ok {
                // TODO: print existing pos
                error(ident.pos, "struct '{}' already defined", ident.text)
            }

            str: Struct
            str.pos = ident.pos

            for {
                if parser_allow(&parser, .Close_Brace) {
                    break
                }

                field_type := parser_expect(&parser, .Ident)
                field_name := parser_expect(&parser, .Ident)
                parser_expect(&parser, .Semicolon)

                type, type_ok := _basic_type_map[field_type.text]

                if !type_ok {
                    error(field_type.pos, "Invalid type: {}", field_type.text)
                }

                append(&str.fields, Struct_Field{
                    name = field_name.text,
                    type = type,
                })
            }

            result.state.structs[ident.text] = str

            fmt.println("vsout:", str)

            parser_allow(&parser, .Semicolon)


        case .Ident:

            res := tok.text
            res = translate_typename(res, opts.target)

            emit_str(&parser, res)

        case .Float:
            emit_str(&parser, tok.text)
            if tok.text[len(tok.text) - 1] != 'f' {
                emit_str(&parser, "f")
            }

        case .Semicolon:
            if tok.text != ";" {
                emit_str(&parser, ";")
            }
            emit_str(&parser, tok.text)
        }
    }

    // TODO: finish subbuffers

    total_len := 0
    for buffer in parser.output {
        total_len += len(buffer)
    }

    final_buf := make([dynamic]byte, 0, total_len, allocator)
    for buffer in parser.output {
        append_elems(&final_buf, ..buffer[:])
    }


    if final_buf[len(final_buf) - 1] != '\n' {
        append(&final_buf, '\n')
    }

    result.code = string(final_buf[:])

    return result
}

parse_resource_slot :: proc(parser: ^Parser, file: File_State) -> (slot: int, base: int) {
    parser_expect(parser, .Open_Paren)

    slot = parse_value(parser, file)
    if parser_allow(parser, .Comma) {
        base = parse_value(parser, file)
    }

    parser_expect(parser, .Close_Paren)

    return slot, base
}

parse_value :: proc(parser: ^Parser, file: File_State) -> (val: int) {
    tok := parser_next(parser)
    #partial switch tok.kind {
    case .Integer:
        return tok_to_int(parser, tok)

    case .Ident:
        def, def_ok := file.defines[tok.text]
        if !def_ok {
            error(tok, "@define {} not found", tok.text)
        }

        return int(def.val)

    case:
        error(tok, "Resource slot must be an integer or a @defined constant")
    }

    return 0
}

parse_expr_passthrough :: proc(parser: ^Parser, opts: Options, end: Token_Kind) -> (any_tokens: bool) {
    depth := 0
    for {
        if depth <= 0 && parser_peek(parser) == end {
            break
        }


        tok := parser_next(parser)

        any_tokens = true

        #partial switch tok.kind {
        case .Invalid, .EOF:
            assert(false)

        case .Builtin:
            error(tok, "Cannot use builtins in a nested expression")

        case .Open_Paren, .Open_Brace, .Open_Bracket:
            depth += 1

        case .Close_Paren, .Close_Brace, .Close_Bracket:
            depth -= 1
            if depth <= 0 {
                break
            }
        }

        emit_str(parser, tok.whitespace)
        emit_str(parser, tok.text)
    }

    return any_tokens
}

// encode_unit :: proc(unit: Unit, allocator := context.allocator) -> []byte {

// }

// decode_unit :: proc(unit: Unit, allocator := context.allocator) -> []byte {

// }

emit_str :: proc(p: ^Parser, str: string, subbuf := -1) {
    buf := subbuf >= 0 ? subbuf : len(p.output) - 1
    append_elem_string(&p.output[buf], str)
}

// returns old index
emit_new_subbuf :: proc(p: ^Parser) -> (result: int) {
    result = len(p.output)
    append(&p.output, make([dynamic]u8, 0, 256, context.allocator))
    return result
}

parser_peek :: proc(p: ^Parser) -> Token_Kind {
    return p.curr_token.kind
}

parser_next :: proc(p: ^Parser, loc := #caller_location) -> Token {
    token, err := next_token(&p.tokenizer)
    if err != nil && token.kind != .EOF {
        error(token.pos, "Invalid token: {}", err)
    }

    // Print every token. Useful for parser debugging
    // fmt.println(token, loc)

    p.prev_token, p.curr_token = p.curr_token, token
    return p.prev_token
}

parser_expect :: proc(p: ^Parser, kind: Token_Kind, loc := #caller_location) -> Token {
    token := parser_next(p, loc = loc)
    if token.kind != kind {
        error(token.pos, "Expected {}, got {} ({})", kind, token.kind, token.text, loc = loc)
    }
    return token
}

parser_allow :: proc(p: ^Parser, kind: Token_Kind, loc := #caller_location) -> bool {
    if p.curr_token.kind == kind {
        parser_next(p, loc = loc)
        return true
    }
    return false
}

// TODO: return error code instead of a crash
error :: proc(pos: Pos, format: string, args: ..any, loc := #caller_location) -> ! {
    fmt.eprintln(loc)
    assert(pos.path != "", loc = loc)
    fmt.eprintf("{}(%i:%i): ", pos.path, pos.line, pos.column)
    fmt.eprintf(format, args = args)
    fmt.eprintln()
    platform.exit_process(-1)
}

unquote :: proc(str: string) -> (result: string) {
    result = str
    if result[0] == '"' || result[0] == '\'' {
        result = result[1:]
    }

    last := len(result) - 1
    if result[last] == '"' || result[last] == '\'' {
        result = result[:last]
    }

    return result
}


tok_to_int :: proc(parser: ^Parser, tok: Token) -> int {
    if tok.kind != .Integer {
        error(tok, "Not an integer token")
    }

    res, res_ok := try_parse_int(tok.text)

    if !res_ok {
        error(tok, "Invalid integer")
    }

    return res
}

try_parse_int :: proc(str: string) -> (int, bool) {
    num: int
    val, _ := strconv.parse_int(str, 10, &num)
    if num == 0 {
        return 0, false
    }
    return int(val), true
}

translate_typename :: proc(name: string, target: Target) -> (string, bool) #optional_ok {
    mapped, mapped_ok := _target_type_map[target][name]

    if !mapped_ok {
        return name, false
    }

    return mapped, true
}

type_to_target :: proc(type: Type, target: Target) -> (string, bool) #optional_ok {
    switch type.kind {
    case .Basic:
        assert(type.len == 1)

        switch type.basic {
        case .Int: return "int", true
        case .UInt: return "uint", true
        case .Float: return "float", true
        case .Bool: return "bool", true
        }

    case .Vector:
        switch type.basic {
        case .Int:
            switch type.len {
            case 2:
                switch target {
                case .HLSL: return "int2", true
                case .GLSL: return "ivec2", true
                }
            case 3:
                switch target {
                case .HLSL: return "int3", true
                case .GLSL: return "ivec3", true
                }
            case 4:
                switch target {
                case .HLSL: return "int4", true
                case .GLSL: return "ivec4", true
                }
            }

        case .UInt:
            switch type.len {
            case 2:
                switch target {
                case .HLSL: return "uint2", true
                case .GLSL: return "uvec2", true
                }
            case 3:
                switch target {
                case .HLSL: return "uint3", true
                case .GLSL: return "uvec3", true
                }
            case 4:
                switch target {
                case .HLSL: return "uint4", true
                case .GLSL: return "uvec4", true
                }
            }

        case .Float:
            switch type.len {
            case 2:
                switch target {
                case .HLSL: return "float2", true
                case .GLSL: return "vec2", true
                }
            case 3:
                switch target {
                case .HLSL: return "float3", true
                case .GLSL: return "vec3", true
                }
            case 4:
                switch target {
                case .HLSL: return "float4", true
                case .GLSL: return "vec4", true
                }
            }

        case .Bool:
            switch type.len {
            case 2:
                switch target {
                case .HLSL: return "bool2", true
                case .GLSL: return "bvec2", true
                }
            case 3:
                switch target {
                case .HLSL: return "bool3", true
                case .GLSL: return "bvec3", true
                }
            case 4:
                switch target {
                case .HLSL: return "bool4", true
                case .GLSL: return "bvec4", true
                }
            }
        }

    case .Matrix:
        if type.basic != .Float {
            break
        }

        switch type.len {
        case 2:
            switch target {
            case .HLSL: return "float2x2", true
            case .GLSL: return "mat2", true
            }
        case 3:
            switch target {
            case .HLSL: return "float3x3", true
            case .GLSL: return "mat3", true
            }
        case 4:
            switch target {
            case .HLSL: return "float4x4", true
            case .GLSL: return "mat4", true
            }
        }
    }
    return "INVALID", false
}

_basic_type_map := map[string]Type{
    "float"     = {.Basic, .Float, 1},
    "int"       = {.Basic, .Float, 1},
    "uint"      = {.Basic, .Float, 1},
    "bool"      = {.Basic, .Float, 1},
    "vec2"      = {.Vector, .Float, 2},
    "vec3"      = {.Vector, .Float, 3},
    "vec4"      = {.Vector, .Float, 4},
    "bvec2"     = {.Vector, .Bool, 2},
    "bvec3"     = {.Vector, .Bool, 3},
    "bvec4"     = {.Vector, .Bool, 4},
    "ivec2"     = {.Vector, .Int, 2},
    "ivec3"     = {.Vector, .Int, 3},
    "ivec4"     = {.Vector, .Int, 4},
    "uvec2"     = {.Vector, .UInt, 2},
    "uvec3"     = {.Vector, .UInt, 3},
    "uvec4"     = {.Vector, .UInt, 4},
    "float2"    = {.Vector, .Float, 2},
    "float3"    = {.Vector, .Float, 3},
    "float4"    = {.Vector, .Float, 4},
    "bool2"     = {.Vector, .Bool, 2},
    "bool3"     = {.Vector, .Bool, 3},
    "bool4"     = {.Vector, .Bool, 4},
    "int2"      = {.Vector, .Int, 2},
    "int3"      = {.Vector, .Int, 3},
    "int4"      = {.Vector, .Int, 4},
    "uint2"     = {.Vector, .UInt, 2},
    "uint3"     = {.Vector, .UInt, 3},
    "uint4"     = {.Vector, .UInt, 4},
    "mat2"      = {.Matrix, .Float, 2},
    "mat3"      = {.Matrix, .Float, 3},
    "mat4"      = {.Matrix, .Float, 4},
    "mat2x2"    = {.Matrix, .Float, 2},
    "mat3x3"    = {.Matrix, .Float, 3},
    "mat4x4"    = {.Matrix, .Float, 4},
    "float2x2"  = {.Matrix, .Float, 2},
    "float3x3"  = {.Matrix, .Float, 3},
    "float4x4"  = {.Matrix, .Float, 4},
}

_target_type_map := [Target]map[string]string{
    .HLSL = {
        "float"     = "float",
        "int"       = "float",
        "uint"      = "uint",
        "bool"      = "bool",
        "vec2"      = "float2",
        "vec3"      = "float3",
        "vec4"      = "float4",
        "bvec2"     = "bool2",
        "bvec3"     = "bool3",
        "bvec4"     = "bool4",
        "ivec2"     = "int2",
        "ivec3"     = "int3",
        "ivec4"     = "int4",
        "uvec2"     = "uint2",
        "uvec3"     = "uint3",
        "uvec4"     = "uint4",
        "mat2"      = "float2x2",
        "mat3"      = "float3x3",
        "mat4"      = "float4x4",
        "mat2x2"    = "float2x2",
        "mat2x3"    = "float2x3",
        "mat2x4"    = "float2x4",
        "mat3x2"    = "float3x2",
        "mat3x3"    = "float3x3",
        "mat3x4"    = "float3x4",
        "mat4x2"    = "float4x2",
        "mat4x3"    = "float4x3",
        "mat4x4"    = "float4x4",
        "float2x2"  = "float2x2",
        "float2x3"  = "float2x3",
        "float2x4"  = "float2x4",
        "float3x2"  = "float3x2",
        "float3x3"  = "float3x3",
        "float3x4"  = "float3x4",
        "float4x2"  = "float4x2",
        "float4x3"  = "float4x3",
        "float4x4"  = "float4x4",
        "float2"    = "float2",
        "float3"    = "float3",
        "float4"    = "float4",
        "bool2"     = "bool2",
        "bool3"     = "bool3",
        "bool4"     = "bool4",
        "int2"      = "int2",
        "int3"      = "int3",
        "int4"      = "int4",
        "uint2"     = "uint2",
        "uint3"     = "uint3",
        "uint4"     = "uint4",
    },

    .GLSL = {
        "float"     = "float",
        "int"       = "float",
        "uint"      = "uint",
        "bool"      = "bool",
        "vec2"      = "vec2",
        "vec3"      = "vec3",
        "vec4"      = "vec4",
        "bvec2"     = "bvec2",
        "bvec3"     = "bvec3",
        "bvec4"     = "bvec4",
        "ivec2"     = "ivec2",
        "ivec3"     = "ivec3",
        "ivec4"     = "ivec4",
        "uvec2"     = "uvec2",
        "uvec3"     = "uvec3",
        "uvec4"     = "uvec4",
        "mat2"      = "mat2x2",
        "mat3"      = "mat3x3",
        "mat4"      = "mat4x4",
        "mat2x2"    = "mat2x2",
        "mat2x3"    = "mat2x3",
        "mat2x4"    = "mat2x4",
        "mat3x2"    = "mat3x2",
        "mat3x3"    = "mat3x3",
        "mat3x4"    = "mat3x4",
        "mat4x2"    = "mat4x2",
        "mat4x3"    = "mat4x3",
        "mat4x4"    = "mat4x4",
        "float2x2"  = "mat2x2",
        "float2x3"  = "mat2x3",
        "float2x4"  = "mat2x4",
        "float3x2"  = "mat3x2",
        "float3x3"  = "mat3x3",
        "float3x4"  = "mat3x4",
        "float4x2"  = "mat4x2",
        "float4x3"  = "mat4x3",
        "float4x4"  = "mat4x4",
        "float2"    = "vec2",
        "float3"    = "vec3",
        "float4"    = "vec4",
        "bool2"     = "bvec2",
        "bool3"     = "bvec3",
        "bool4"     = "bvec4",
        "int2"      = "ivec2",
        "int3"      = "ivec3",
        "int4"      = "ivec4",
        "uint2"     = "uvec2",
        "uint3"     = "uvec3",
        "uint4"     = "uvec4",
    },
}


/*
HLSL ONLY
lerp
saturate
rsqrt
mul
asuint
asint
asfloat
sincos
determinant
clip
ddx
ddy
fwidth
smoothstep
powr
rcp
step
reversebits
firstbithigh
firstbitlow
countbits
mad

GLSL ONLY
mix
fract
mod
modf
transpose
inverse
texture
textureSize
textureProj
textureLod
textureGrad
textureGather
dFdx
dFdy
fwidth
faceforward
reflect
refract
matrixCompMult
cross
normalize
length
distance
*/