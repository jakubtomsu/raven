# RAVN Cheatsheet
> Generated with `build/cheatsheet`

## Packages

- [ravn](#ravn) - 254 procedures
- [ravn_audio](#ravn_audio) - 59 procedures
- [audio_wav](#audio_wav) - 6 procedures
- [ravn_base](#ravn_base) - 38 procedures
- [ufmt](#ufmt) - 4 procedures
- [ravn_bvh](#ravn_bvh) - 18 procedures
- [ravn_collision](#ravn_collision) - 43 procedures
- [ravn_geometry](#ravn_geometry) - 41 procedures
- [ravn_gpu](#ravn_gpu) - 53 procedures
- [ravn_platform](#ravn_platform) - 64 procedures
- [rscn](#rscn) - 4 procedures
- [ravn_shader_compiler](#ravn_shader_compiler) - 3 procedures

## ravn

### ravn.odin

```odin
set_state_ptr(state: ^State)
get_state_ptr() -> (state: ^State)
run_main_loop(desc: App_Desc) // Default runner for a ravn app.
get_context() -> (result: runtime.Context)
init_context_state(ctx: ^Context_State, allocator: runtime.Allocator)
init_state(allocator: runtime.Allocator, desc: App_Desc) // Create state, init context, init subsystems.
request_shutdown()
shutdown_state() // Called automatically at the right time when you call rv.request_shutdown()!
begin_frame() -> (keep_running: bool)
end_frame(vsync := true)
get_builtin_texture(id: Builtin_Texture) -> Texture_Handle
get_builtin_mesh(id: Builtin_Mesh) -> Mesh_Handle
get_builtin_shader(id: Builtin_Shader) -> Shader_Handle
get_delta_time() -> f32 // Last frame delta time
get_frame_index() -> u64
get_time() -> f32
get_window() -> platform.Window
atlas_cell(split: [2]i32, coord: [2]i32, scale: [2]f32 = 1.0) -> Rect
atlas_slot(split: [2]i32, #any_int index: i32) -> Rect
font_cell(coord: [2]i32) -> Rect
font_slot(#any_int index: i32) -> Rect // Use rune_to_char to convert unicode symbols to the index.
hash_name(name: string) -> u64
hash_const_name($Name: string) -> u64
get_screen_size() -> [2]f32
create_arena(usage: Arena_Usage, #any_int max_mesh_verts: i32 = 1024 * 1024, #any_int max_mesh_indices: i32 = 1024 * 1024, #any_int max_spline_verts: i32 = 1024 * 8, #any_int collision_arena_size: u64 = 1024 * 1024) -> (result: Arena_Handle, ok: bool)
clear_arena(handle: Arena_Handle)
flush_arena_gpu_buffers(handle: Arena_Handle) // NOTE: doesn't clear!
destroy_arena(handle: Arena_Handle)
load_scene(name: string, arena_handle: Arena_Handle = {}) -> (result_arena: Arena_Handle, ok: bool)
load_scene_from_data(txt: string, bin: []byte, arena_handle: Arena_Handle) -> (result_arena: Arena_Handle, ok: bool)
get_mesh($Name: string) -> (result: Mesh_Handle, ok: bool)
get_mesh_by_name(name: string) -> (result: Mesh_Handle, ok: bool)
get_mesh_by_hash(hash: u64) -> (result: Mesh_Handle, ok: bool)
get_texture($Name: string) -> (result: Texture_Handle, ok: bool)
get_texture_by_name(name: string) -> (result: Texture_Handle, ok: bool)
get_texture_by_hash(hash: u64) -> (result: Texture_Handle, ok: bool)
get_spline($Name: string) -> (result: Spline_Handle, ok: bool)
get_spline_by_name(name: string) -> (result: Spline_Handle, ok: bool)
get_spline_by_hash(hash: u64) -> (result: Spline_Handle, ok: bool)
get_shader($Name: string) -> (result: Shader_Handle, ok: bool)
get_shader_by_name(name: string) -> (result: Shader_Handle, ok: bool)
get_shader_by_hash(hash: u64) -> (result: Shader_Handle, ok: bool)
insert_mesh_by_name(name: string, mesh: Mesh) -> (result: Mesh_Handle, ok: bool)
insert_spline_by_name(name: string, spline: Spline) -> (result: Spline_Handle, ok: bool)
insert_shader_by_name(name: string, shader: Shader) -> (result: Shader_Handle, ok: bool)
insert_mesh_by_hash(hash: u64, mesh: Mesh) -> (result: Mesh_Handle, ok: bool)
insert_spline_by_hash(hash: u64, spline: Spline) -> (result: Spline_Handle, ok: bool)
insert_vertex_shader_by_hash(hash: u64, shader: Shader) -> (result: Shader_Handle, ok: bool)
get_file_data(name: string, flush := false) -> (data: []byte, ok: bool)
get_file_data_by_hash(hash: u64, flush := false) -> (data: []byte, ok: bool)
load_asset(name: string, arena_handle: Arena_Handle) -> bool
register_file(path: string) -> bool
register_file_data(path: string, data: []byte, flags: bit_set[File_Flag] = {}) -> bool
register_file_data_by_hash(hash: u64, data: []byte, flags: bit_set[File_Flag]) -> bool
register_const_directory(files: []runtime.Load_Directory_File) -> (ok: bool)
register_directory(path: string) // TODO: allow path patterns, just like platform dir iterator?
watch_asset_directory(path: string) -> bool
invalidate_collision_mesh(mesh_handle: Mesh_Handle)
get_or_create_collision_mesh(mesh_handle: Mesh_Handle) -> (result: collision.Mesh_Handle, ok: bool)
load_sound_resource(path: string) -> (result: Sound_Resource_Handle, ok: bool)
create_sound_resource_encoded(name: string, data: []byte) -> (result: Sound_Resource_Handle, ok: bool)
get_sound_resource(name: string) -> (result: Sound_Resource_Handle, ok: bool)
insert_sound_resource_by_hash(name: string, handle: Sound_Resource_Handle) -> bool
alloc_slice_non_zeroed($T: typeid, init_len: int, alignment: int = 2 * align_of(rawptr), allocator: runtime.Allocator) -> []T
normalize_path(path: string, allocator := context.temp_allocator) -> (result: string) // Clean up a VFS path
asset_name_from_path(str: string) -> (result: string) // Convert VFS path to an asset name by stripping the directory and the last extension, for example:
file_name_from_path(str: string) -> string
string_has_suffix(s, suffix: string) -> bool
enum_to_string(val: $T) -> string
strings_join(a: ..string, allocator := context.temp_allocator, loc := #caller_location) -> (res: string, ok: bool)
pack_unorm8(val: [4]f32) -> [4]u8
unpack_unorm8(val: [4]u8) -> [4]f32
pack_unorm16(val: [2]f32) -> [2]u16
unpack_unorm16(val: [2]u16) -> [2]f32
pack_signed_color_unorm8(val: [4]f32) -> [4]u8 // Special packing to allow -2..2 range
unpack_signed_color_unorm8(val: [4]u8) -> [4]f32
pack_uv_unorm16(val: [2]f32) -> [2]u16 // No UV precision loss up to 2048x2048 textures.
unpack_uv_unorm16(val: [2]u16) -> [2]f32
pack_normal_octahedral_unorm8(val: [3]f32) -> [2]u8
unpack_normal_octahedral_unorm8(val: [2]u8) -> [3]f32
encode_octahedral(n: [3]f32) -> [2]f32 // Input is vector from a sphere.
decode_octahedral(f: [2]f32) -> [3]f32 // Result is normalized vector on a sphere
pack_sprite_inst(pos: [3]f32, col: [4]f32, mat_x: [3]f32, uv_min: [2]f32, mat_y: [3]f32, uv_size: [2]f32, add_col: [4]f32, param: u32 = 0, tex_slice: u8) -> Sprite_Inst
pack_mesh_inst(pos: [3]f32, col: [4]f32, mat_x: [3]f32, add_col: [4]f32, mat_y: [3]f32, tex_slice: u8, vert_offs: u32, mat_z: [3]f32, param: u32) -> Mesh_Inst
pack_vertex(pos: [3]f32, uv: [2]f32 = 0, normal: [3]f32 = {0, 1, 0}, col: [4]f32 = 1, joints: [4]u8 = 0, weights: [4]f32 = {1, 0, 0, 0}) -> Vertex
is_blend_mode_order_dependent(mode: Blend_Mode) -> bool // Order independent blend modes are a lot simpler on the renderer CPU side.
draw_perf_counter(kind: Perf_Counter_Kind, pos: [3]f32, scale: f32 = 1, col: [4]f32 = 1, show_text := true) // Displays max of the recent history and a graph.
perf_scope(name: string = "", loc := #caller_location) -> i64
draw_perf_scopes(pos: [3]f32 = {10, 40, 0.1}, scale: f32 = 1)
rune_to_char(r: rune) -> u8 // Unicode -> CP437. Use when iterating over a string.
char_to_rune(ch: u8) -> rune // CP437 -> Unicode. Use when iterating over encoded text to print it.
```

### ravn_curve.odin

```odin
curve_cubic(points: [4]$T, t: f32, m: matrix[4, 4]f32) -> (result: T)
curve_bezier(points: [4]$T, t: f32) -> (result: T) // Shapes, fonts, vector graphics.
curve_hermite_points(points: [4]$T, t: f32) -> T // Animation, physics sim, interpolation.
curve_hermite_tangents(values: [4]$T, t: f32) -> T // Based on two points with velocities.
curve_hermite(pos0, vel0, pos1, vel1: $T, t: f32) -> T
curve_catmull_rom(points: [4]$T, t: f32) -> (result: T) // Animation and paths.
curve_cardinal(points: [4]$T, t: f32, scale: f32) // Catmull rom with configurable scale factor.
curve_b_spline(points: [4]$T, t: f32) -> (result: T) // Curvature-sensitive shapes, animations, camera paths.
curve_sample(curve: Curve_Kind, points: [4]$T, t: f32) -> T
spline_sample_linear(points: []$T, t: f32) -> T
```

### ravn_graphics.odin

```odin
create_mesh_from_data(name: string, arena_handle: Arena_Handle, verts: []Vertex, indices: []Vertex_Index) -> (result: Mesh_Handle, ok: bool)
destroy_mesh(handle: Mesh_Handle) -> bool
create_texture_pool(size: [2]i32, slices: i32) -> (ok: bool) // Texture pool allows for better batching when textures are the same size.
load_texture(path: string) -> (result: Texture_Handle, ok: bool)
create_texture_from_encoded_data(name: string, data: []byte) -> (result: Texture_Handle, ok: bool)
create_texture_from_data(name: string, data: Texture_Data) -> (result: Texture_Handle, ok: bool)
create_texture_from_resource(name: string, handle: gpu.Resource_Handle) -> (result: Texture_Handle, ok: bool)
destroy_texture(handle: Texture_Handle)
decode_texture_data(data: []byte) -> (result: Texture_Data, ok: bool)
destroy_decoded_texture_data(data: ^Texture_Data) // NOTE: this is potentially unsafe.
load_shader(path: string) -> (result: Shader_Handle, ok: bool)
create_shader_from_bin(name: string, data: []byte) -> (result: Shader_Handle, ok: bool)
create_shader_from_source(name: string, source: string) -> (result: Shader_Handle, ok: bool)
experimental_create_quick_pixel_shader(name: string, source_body: string) -> Shader_Handle
create_render_texture(size: [2]i32, depth := true) -> (result: Render_Texture_Handle, ok: bool)
destroy_render_texture(handle: Render_Texture_Handle)
get_render_texture_size(handle: Render_Texture_Handle) -> (result: [2]i32, ok: bool)
scope_draw_state() -> bool
push_draw_state()
pop_draw_state()
get_draw_state() -> Draw_State
set_draw_state(binds: Draw_State) // NOTE: be very careful when changing fields in Draw_State.
get_default_draw_state() -> (result: Draw_State)
set_draw_layer(#any_int layer: i32)
set_draw_blend(blend: Blend_Mode)
set_draw_fill(fill: Fill_Mode)
set_draw_depth(depth: Depth_Mode)
set_draw_shader(handle: Shader_Handle)
set_draw_texture(handle: Texture_Handle)
set_draw_render_texture(handle: Render_Texture_Handle) // Bind render texture for READING like a regular texture.
update_draw_layer(#any_int layer: i32, camera: Camera, flags: bit_set[Draw_Layer_Flag] = {}) // Set up layer draw parameters for this frame.
draw_sprite(pos: [3]f32, rect: Rect = {0, 1}, scale: [2]f32 = 1, col: [4]f32 = 1, rot: matrix[3, 3]f32 = 1, anchor: [2]f32 = 0, add_col: [4]f32 = 0, scaling: Sprite_Scaling = .Pixel, param: u32 = 0)
draw_sprite_2d(pos: [2]f32, rect: Rect = {0, 1}, scale: [2]f32 = 1, col: [4]f32 = 1, rot: f32 = 0, anchor: [2]f32 = 0, add_col: [4]f32 = 0, scaling: Sprite_Scaling = .Pixel, z: f32 = 0, param: u32 = 0)
draw_rect_2d(rect: Rect, tex_rect: Rect = {0, 1}, z: f32 = 0, col: [4]f32 = 1, add_col: [4]f32 = 0, param: u32 = 0)
draw_mesh(handle: Mesh_Handle, pos: [3]f32 = 0, scale: [3]f32 = 1, rot: quaternion128 = 1, col: [4]f32 = 1, add_col: [4]f32 = 0, param: u32 = 0)
draw_sphere(pos: [3]f32, scale: [3]f32 = 1, rot: quaternion128 = 1, col: [4]f32 = 1, add_col: [4]f32 = 0, param: u32 = 0)
draw_box(pos: [3]f32, scale: [3]f32 = 1, rot: quaternion128 = 1, col: [4]f32 = 1, add_col: [4]f32 = 0, param: u32 = 0)
draw_plane(pos: [3]f32, scale: [2]f32 = 1, rot: quaternion128 = 1, col: [4]f32 = 1, add_col: [4]f32 = 0, param: u32 = 0)
draw_capsule_line(pos0: [3]f32, pos1: [3]f32, rad: f32 = 1, col: [4]f32 = 1, add_col: [4]f32 = 0, param: u32 = 0)
draw_cylinder_line(pos0: [3]f32, pos1: [3]f32, rad: f32 = 1, col: [4]f32 = 1, add_col: [4]f32 = 0, param: u32 = 0)
draw_triangles(verts: ..Vertex, pos: [3]f32 = 0, scale: [3]f32 = 1, rot: quaternion128 = 1, col: [4]f32 = WHITE, add_col: [4]f32 = 0, param: u32 = 0)
draw_lines(verts: ..Vertex, pos: [3]f32 = 0, scale: [3]f32 = 1, rot: quaternion128 = 1, col: [4]f32 = WHITE, add_col: [4]f32 = 0, param: u32 = 0)
draw_triangle(pos: [3][3]f32, col: [3][4]f32 = WHITE, uvs: [3][2]f32 = {{0, 0}, {1, 0}, {0, 1}}, add_col: [4]f32 = BLACK, normals: Maybe([3][3]f32) = nil) // Prefer draw_triangles if you need to efficiently draw many triangles.
draw_triangle_2d(pos: [3][2]f32, col: [3][4]f32 = WHITE, uvs: [3][2]f32 = {{0, 0}, {1, 0}, {0, 1}}, add_col: [4]f32 = BLACK, z: f32 = 0)
draw_line(pos0: [3]f32, pos1: [3]f32, col: [2][4]f32 = WHITE, uvs: [2][2]f32 = {{0, 0.5}, {1, 0.5}}, add_col: [4]f32 = BLACK, normals: Maybe([2][3]f32) = nil) // Prefer draw_lines if you need to efficiently draw many lines.
draw_line_2d(pos0: [2]f32, pos1: [2]f32, col: [2][4]f32 = WHITE, uvs: [2][2]f32 = {{0, 0.5}, {1, 0.5}}, add_col: [4]f32 = BLACK, z: f32 = 0)
draw_text(text: string, pos: [3]f32, scale: [2]f32 = 1, anchor: [2]f32 = -1, spacing: [2]f32 = {0, 8}, col: [4]f32 = 1, add_col: [4]f32 = 0, rot: matrix[3, 3]f32 = 1) -> []Sprite_Inst // Returns a slice of the GPU sprite instances.
draw_text_2d(text: string, pos: [2]f32, scale: [2]f32 = 1, anchor: [2]f32 = -1, spacing: [2]f32 = {0, 8}, col: [4]f32 = 1, add_col: [4]f32 = 0, z: f32 = 0) -> []Sprite_Inst
rune_is_drawable(r: rune) -> bool
calc_text_size(text: string, scale: [2]f32, char_size: [2]i32 = 8, spacing: [2]f32 = 0) -> [2]f32
text_glyph_apply(offs: [2]f32, r: rune, scale: [2]f32, char_size: [2]i32 = 8, spacing: [2]f32 = 0) -> [2]f32
draw_line_triangle(verts: [3][3]f32, col := WHITE)
draw_line_point(pos: [3]f32, rad: [3]f32 = 1, col := WHITE)
draw_line_box(pos: [3]f32, mat: matrix[3, 3]f32 = 1, col := WHITE)
draw_line_mat3(pos: [3]f32, mat: matrix[3, 3]f32 = 1)
draw_line_aabb(min: [3]f32, max: [3]f32, col := WHITE)
draw_line_circle(pos: [3]f32, rad: [2]f32 = 1, axis: [3]f32 = {0, 1, 0}, col := WHITE, segments := 12)
draw_line_sphere(pos: [3]f32, mat: matrix[3, 3]f32 = 1, col := WHITE, segments := 12)
draw_line_cylinder(pos_a, pos_b: [3]f32, rad: f32 = 1.0, col := WHITE, segments := 12)
draw_line_grid(pos: [3]f32 = 0, axis_a: [3]f32 = {1, 0, 0}, axis_b: [3]f32 = {0, 0, 1}, col := WHITE, segments: [2]i32 = 5) // The axis vectors determine a single cell size.
ceil_div(a, b: $T) -> T
submit_layers() // Finishes drawing for this frame.
render_layer(#any_int layer_index: i32, ren_tex_handle: Render_Texture_Handle = DEFAULT_RENDER_TEXTURE, clear_color: Maybe([3]f32) = nil, clear_depth: bool = true, sampler: gpu.Sampler_Desc = DEFAULT_SAMPLER, user_samplers: []gpu.Sampler_Desc = nil, user_constants: []gpu.Resource_Handle = nil, user_resources: []gpu.Resource_Handle = nil) // NOTE: the instance bind data only use a few of the available sots (consts/resources/blends/etc)
orthographic_projection(left, right, top, bottom: f32, near: f32 = 0.01, far: f32 = 1000.0) -> (result: matrix[4, 4]f32)
perspective_projection(screen: [2]f32, fov: f32, near: f32 = 0.01, far: f32 = 1000.0) -> (result: matrix[4, 4]f32) // left handed reverse Z
calc_camera_world_to_view_matrix(camera: Camera) -> (result: matrix[4, 4]f32)
calc_camera_world_to_clip_matrix(camera: Camera) -> (result: matrix[4, 4]f32)
calc_camera_frustum(cam: Camera) -> Frustum
calc_matrix_frustum(clip_to_world: matrix[4, 4]f32) -> (result: Frustum)
is_box_in_frustum(fru: Frustum, pos: [3]f32, rad: [3]f32) -> bool
is_sphere_in_frustum(fru: Frustum, pos: [3]f32, rad: f32) -> bool
is_sphere_in_frustum_simd(fru_pos: [3]#simd[LANES]f32, fru_rad: [3]#simd[LANES]f32, fru_planes: [6][4]#simd[LANES]f32, pos: [3]#simd[LANES]f32, rad: #simd[LANES]f32) -> (result: #simd[LANES]u32) // TODO: early out path? Most objects are small.
screen_to_world_ray(pos: [2]f32, cam: Camera) -> [3]f32 // Returns the ray direction.
```

### ravn_input.odin

```odin
get_key_down(key: Key) -> bool
get_key_down_time(key: Key) -> f32 // Down time is 0 on pressed.
get_key_repeated(key: Key) -> bool
get_key_released(key: Key) -> bool
get_key_pressed(key: Key, buf: f32 = 0) -> bool // buf: buffering window duration in seconds
get_mouse_pos() -> [2]f32 // NOTE: [0, 0] is the bottom left corner.
get_mouse_delta() -> [2]f32 // Positive Y is up.
get_scroll_delta() -> [2]f32
get_mouse_down(button: Mouse_Button) -> bool
get_mouse_down_time(button: Mouse_Button) -> f32 // Down time is 0 on pressed.
get_mouse_repeated(button: Mouse_Button) -> bool
get_mouse_released(button: Mouse_Button) -> bool
get_mouse_pressed(button: Mouse_Button, buf: f32 = 0) -> bool // buf: buffering window duration in seconds
get_gamepad_axis(gamepad_index: int, axis: Gamepad_Axis, deadzone: f32 = 0.01) -> f32
get_gamepad_down(gamepad_index: int, button: Gamepad_Button) -> bool
get_gamepad_down_time(gamepad_index: int, button: Gamepad_Button) -> f32 // Down time is 0 on pressed
get_gamepad_repeated(gamepad_index: int, button: Gamepad_Button) -> bool
get_gamepad_released(gamepad_index: int, button: Gamepad_Button) -> bool
get_gamepad_pressed(gamepad_index: int, button: Gamepad_Button, buf: f32 = 0) -> bool // buf: buffering window duration in seconds
```

### ravn_util.odin

```odin
deg(degrees: f32) -> (radians: f32)
lerp(a, b: $T, t: f32) -> T
lexp(a, b: $T, rate: f32) -> T // Exponential lerp. Multiply rate by delta to get frame rate independent interpolation
slexp(a, b: $T, rate: f32) -> T
nlerp(a, b: $T, t: f32) -> T
nlexp(a, b: $T, rate: f32) -> T
move_towards :: proc{move_towards_scalar, move_towards_vec, move_towards_quat}
move_towards_scalar(x, target: f32, rate: f32) -> f32
move_towards_vec(x, target: [$N]$E, rate: f32) -> [N]E
move_towards_quat(x, target: $Q, rate: f32) -> Q
fade(alpha: f32) -> [4]f32
gray(val: f32) -> [4]f32
addz(v: [2]f32, z: f32 = 0.0) -> [3]f32
nsin(x: f32) -> f32
vcast($T: typeid, v: [$N]$E) -> (result: [N]T)
int_cast($Dst: typeid, v: $Src) -> Dst
rot90(v: [2]$T) -> [2]T // Counter-clockwise. Negate to do clockwise.
unlerp(a, b: f32, x: f32) -> f32 // Returns value in 0..1 range.
remap(x, a0, a1: f32, b0: f32 = 0, b1: f32 = 1) -> f32 // Linearly transform x from range a0..a1 to b0..b1
remap_clamped(x, a0, a1: f32, b0: f32 = 0, b1: f32 = 1) -> f32
remap_smooth(x, a0, a1: f32, b0: f32 = 0, b1: f32 = 1) -> f32
smoothstep(edge0, edge1, x: f32) -> f32
luminance(rgb: [3]f32) -> f32
floor :: proc{floor_f32, floor_vec}
floor_vec(x: [$N]f32) -> [N]f32
floor_f32(x: f32) -> f32
hex_color(hex: u32) -> [4]f32 // RGB only!
oklerp(a, b: [4]f32, t: f32) -> (result: [4]f32) // Oklab lerp - Better color gradients than regular lerp()
heatmap_color(val: f32) -> (result: [4]f32) // 0 -> Red, 0.5 -> Blue, 1 -> Green
euler_rot(angles: [3]f32) -> quaternion128 // ZXY order for first-person view.
clamp_length(v: [$N]f32, min: f32 = 0, max: f32 = 1) -> [N]f32
spring(x, v: ^$T, x_target: T, damp: f32, freq: f32, delta: f32) // Spring Integration
spring2(xv: ^[2]$T, x_target: T, damp: f32, freq: f32, delta: f32) // Utility for springs where X and V are packed in an array.
approx_nexp(x: f32) -> (result: f32) // https://gist.github.com/jakubtomsu/d25210b55037858c3ed35fe00182f92a
rcp(denom: f32) -> (result: f32)
rect_make(min: [2]f32, full_size: [2]f32) -> Rect
rect_make_centered(pos: [2]f32, half_size: [2]f32) -> Rect
rect_center(r: Rect) -> [2]f32
rect_anchor(r: Rect, anchor: [2]f32) -> [2]f32
rect_full_size(r: Rect) -> [2]f32
rect_expand(r: Rect, a: [2]f32) -> Rect
rect_scale(r: Rect, a: [2]f32) -> Rect
rect_contains_point(r: Rect, p: [2]f32) -> bool
rect_clamp_point(r: Rect, p: [2]f32) -> [2]f32
rect_cut_left(r: ^Rect, a: f32) -> Rect
rect_cut_right(r: ^Rect, a: f32) -> Rect
rect_cut_top(r: ^Rect, a: f32) -> Rect
rect_cut_bottom(r: ^Rect, a: f32) -> Rect
rect_split_left(r: ^Rect, t: f32) -> Rect
rect_split_right(r: ^Rect, t: f32) -> Rect
rect_split_top(r: ^Rect, t: f32) -> Rect
rect_split_bottom(r: ^Rect, t: f32) -> Rect
transform_make(pos: [3]f32 = 0, scale: [3]f32 = 1, rot: quaternion128 = 1) -> Transform
transform_make_angle_axis(pos: [3]f32 = 0, scale: [3]f32 = 1, angle: f32 = 0, axis: [3]f32 = {0, 1, 0}) -> Transform
transform_point(tran: Transform, point: [3]f32) -> [3]f32
transform_mul(parent, child: Transform) -> Transform
transform_inv(tran: Transform) -> Transform
make_perspective_3d_camera(screen: [2]f32, pos: [3]f32, rot: quaternion128, fov: f32 = math.PI * 0.5) -> Camera
make_orthographic_3d_camera(screen: [2]f32, pos: [3]f32, rot: quaternion128, fov: f32 = 1) -> Camera
make_2d_camera(screen: [2]f32, pos: [3]f32 = 0, fov: [2]f32 = 1.0, angle: f32 = 0) -> Camera
make_screen_camera(screen: [2]f32, pos: [3]f32 = 0) -> Camera
```

## ravn_audio

### audio.odin

```odin
set_state_ptr(state: ^State)
get_state_ptr() -> (state: ^State)
init(state: ^State) -> bool
shutdown()
update() // Call every frame from the main thread.
set_master_mixer(mixer: Generator_Proc)
set_listener(pos: [3]f32, vel: [3]f32, forw: [3]f32 = {0, 0, 1}, right: [3]f32 = {1, 0, 0})
create_resource_mono_f32(frames: []f32, frame_rate: u32) -> (result: Resource_Handle, ok: bool)
create_resource_stereo_f32(frames: [][2]f32, frame_rate: u32) -> (result: Resource_Handle, ok: bool)
create_resource(format: Resource_Format, data: []byte, flags: bit_set[Resource_Flag] = {}, frame_rate: u32 = 0) -> (result: Resource_Handle, ok: bool) // The data slice must remain valid until the resource is destroyed.
destroy_resource(handle: Resource_Handle) -> bool
create_sound(source: Sound_Source, flags: bit_set[Sound_Flag] = {}, pitch: [2]f32 = 1.0, pan: [2]f32 = 0, volume: [2]f32 = 1, attenuation_range: [2]f32 = {0.1, 100}, lowpass: [2]f32 = 0.0, highpass: [2]f32 = 0.0, doppler_factor: f32 = 1.0, playing := true, chop: [2]f32 = {0, 1}, start_delay: f32 = 0, pos: [3]f32 = 0, vel: [3]f32 = 0, #any_int group_index: int = 0) -> (result: Sound_Handle, ok: bool)
destroy_sound(handle: Sound_Handle) -> bool
get_sound_time(handle: Sound_Handle, unit: Unit = .Seconds) -> f32
get_sound_playing(handle: Sound_Handle) -> bool
set_sound_playing(handle: Sound_Handle, playing: bool) -> bool
set_sound_param(handle: Sound_Handle, kind: Sound_Param_Kind, value: f32, dur: f32 = 0) -> bool // Dur determines the time (in seconds) it takes to interpolate to the new value.
set_group_sound_param(#any_int index: int, kind: Sound_Param_Kind, value: f32, dur: f32 = 0) -> bool
set_sound_transform(handle: Sound_Handle, pos: [3]f32, vel: [3]f32)
is_resource_valid(handle: Resource_Handle) -> bool
is_sound_valid(handle: Sound_Handle) -> bool
is_group_valid(#any_int index: int) -> bool
default_master_mixer(out_buf: [][2]f32, frame_rate: int)
fast_tanh(x: f32) -> f32 // Approximation for tanh(x) in the range [-3, 3].
fast_tanh_simd(x: $T/#simd[$N]f32) -> T
sample_base_signal(out_buf: [][2]f32, frame_bytes: [^]byte, frame_num: u32, format: Resource_Format, mono: bool, time: f64, delta_range: [2]f32, loop: bool, frame_range: [2]u32) -> f64 // Interpolated, Stereo/Mono
unpack_frame :: proc{unpack_frame_mono_f32, unpack_frame_mono_i16, unpack_frame_mono_u8, unpack_frame_stereo_f32, unpack_frame_stereo_i16, unpack_frame_stereo_u8}
unpack_frame_mono_u8(v: u8) -> [2]f32
unpack_frame_mono_i16(v: i16) -> [2]f32
unpack_frame_mono_f32(v: f32) -> [2]f32
unpack_frame_stereo_u8(v: [2]u8) -> [2]f32
unpack_frame_stereo_i16(v: [2]i16) -> [2]f32
unpack_frame_stereo_f32(v: [2]f32) -> [2]f32
sample_wave_signal(out_buf: [][2]f32, wave_kind: Wave_Kind, time: f64, end_time: f64, delta_range: [2]f32, frame_range: [2]u32) -> f64
sample_wave(kind: Wave_Kind, t: f32) -> f32
sample_sine_wave(t: f32) -> f32
sample_square_wave(t: f32) -> f32
sample_pulse_wave(t: f32) -> f32
sample_triangle_wave(t: f32) -> f32
sample_saw_wave(t: f32) -> f32
sample_noise_wave(t: f32) -> f32
sample_rand_wave(t: f32) -> f32
atomic_load_components_acquire :: proc{atomic_load_components_acquire_single, atomic_load_components_acquire_vec}
atomic_load_components_acquire_single(v: ^$T) -> T
atomic_load_components_acquire_vec(v: ^$T/[$N]$V) -> (result: T)
atomic_store_components_release_vec(dst: ^$T/[$N]$V, v: T)
update_param(param: ^Param, delta: f32) -> (result: [2]f32)
linear_attenuation(x: f32, range: [2]f32) -> f32 // Result is in 0..1 range
lerp(a, b: $T, t: f32) -> T
dot(a, b: [3]f32) -> f32
cross(a, b: [3]f32) -> (c: [3]f32)
length(v: [3]f32) -> f32
normalize(v: [3]f32) -> [3]f32
move_towards :: proc{move_towards_f32, move_towards_vec3}
move_towards_f32(val: f32, target: f32, delta: f32) -> f32
move_towards_vec3(val: [3]f32, target: [3]f32, delta: f32) -> [3]f32
volume_linear_to_db(factor: f32) -> f32
volume_db_to_linear(gain: f32) -> f32
note(#any_int midi_n: i32) -> f32 // Returns frequency in Hz for a given midi note.
```

## audio_wav

### wav.odin

```odin
decode(data: []byte, allocator := context.allocator) -> (header: Header, samples: []f32, ok: bool)
decode_header(data: []byte) -> (result: Header, result_data: []byte, ok: bool)
decode_samples(format: Format_Chunk, data: []byte, allocator := context.allocator) -> (result: []f32)
init_header(header: ^Header, sample_rate: u32, num_channels: u16, sample_size: u32, sample_format: Format, data: []byte) // Initialize a header for writing it to a file.
reinterpret_bytes($T: typeid, bytes: []byte) -> []T
log(level: runtime.Logger_Level, str: string, loc := #caller_location)
```

## ravn_base

### base.odin

```odin
log_err(format: string, args: ..any, loc := #caller_location)
log_warn(format: string, args: ..any, loc := #caller_location)
log_info(format: string, args: ..any, loc := #caller_location)
log_debug(format: string, args: ..any, loc := #caller_location)
log_dump(arg: any, expr := #caller_expression(arg), loc := #caller_location)
log(level: Log_Level, format: string, args: ..any, loc := #caller_location)
make_logger() -> runtime.Logger
reinterpret_slice($T: typeid, data: []$E, loc := #caller_location) -> []T
reinterpret_bytes($T: typeid, bytes: []byte, loc := #caller_location) -> []T
to_bytes(data: []$T) -> []byte
is_finite_f32(x: f32) -> bool // Quickly checks if x is not NaN or Inf
is_finite_vec(v: [$N]f32) -> bool
hash_fnv64a(data: []byte, seed: u64) -> u64
hash_murmurhash32_mix32(x: u32) -> u32
hash_splittable64(x: u64) -> u64
```

### base_bit_pool.odin

```odin
bit_pool_clear(bp: ^Bit_Pool($N))
bit_pool_alloc(bp: ^Bit_Pool($N)) -> (result: int, ok: bool)
bit_pool_find_0(bp: Bit_Pool($N)) -> (index: int, ok: bool)
bit_pool_set_1(bp: ^Bit_Pool($N), #any_int index: u64)
bit_pool_set_0(bp: ^Bit_Pool($N), #any_int index: u64)
bit_pool_is_1(bp: Bit_Pool($N), #any_int index: u64) -> bool // bit_pool_get
```

### base_hash_pool.odin

```odin
hash_pool_clear(pool: ^$T/Hash_Pool($N, $D, $H)) // Call to initialize and destroy. Does not clear generation counters and values - garbage is fine.
hash_pool_has(pool: $T/Hash_Pool($N, $D, $H), handle: H) -> bool
hash_pool_find_free(pool: $T/Hash_Pool($N, $D, $H), hash: u64) -> (: H, : bool)
hash_pool_find(pool: $T/Hash_Pool($N, $D, $H), hash: u64) -> (: H, : bool)
hash_pool_insert(pool: ^$T/Hash_Pool($N, $D, $H), hash: u64, handle: H, data: D) -> bool
hash_pool_remove(pool: ^$T/Hash_Pool($N, $D, $H), handle: Handle) -> bool
hash_pool_get(pool: ^$T/Hash_Pool($N, $D, $H)) -> (: ^D, : bool)
```

### base_pool.odin

```odin
pool_clear(pool: ^$T/Pool($N, $D, $H)) // Call to initialize and destroy. Does not clear generation counters and values - garbage is fine.
pool_has(pool: $T/Pool($N, $D, $H), handle: H) -> bool
pool_find_free(pool: $T/Pool($N, $D, $H)) -> (: H, : bool)
pool_insert(pool: ^$T/Pool($N, $D, $H), handle: H, data: D) -> bool
pool_remove(pool: ^$T/Pool($N, $D, $H), handle: Handle) -> bool
pool_get(pool: ^$T/Pool($N, $D, $H)) -> (: ^D, : bool)
```

### base_spsc.odin

```odin
spsc_push_elems(q: ^$T/SPSC($N, $V), vals: ..V) -> int
spsc_pop_elems(q: ^$T/SPSC($N, $V), buf: []V) -> []V
spsc_push(q: ^$T/SPSC($N, $V), val: V) -> bool
spsc_pop(q: ^$T/SPSC($N, $V)) -> (result: V, ok: bool)
```

## ufmt

### ufmt.odin

```odin
eprintf(format: string, args: ..any) -> int
eprintfln(format: string, args: ..any) -> int
ctprintf(format: string, args: ..any) -> cstring
tprintf(format: string, args: ..any) -> string
```

## ravn_bvh

### bvh.odin

```odin
max_nodes_for_prims(#any_int num_prims: int) -> int
init(bvh: ^BVH, nodes: []Node, indices: []u32, prims: [][2][3]f32 = nil, #any_int max_leaf_prims := 3)
init_prims(bvh: ^BVH, prims: [][2][3]f32) // Re-initialize the primitive buffer only and clears the existing nodes.
build_none(bvh: ^BVH) // Not actual BVH, contains a single huge node with all prims.
build_mid(bvh: ^BVH, curr_index := 0) // Very fast but the result isn't a high-quality tree.
build_mean_sah(bvh: ^BVH, curr_index := 0) // Similar to mid, spends more time selecting better split.
build_sah(bvh: ^BVH, curr_index := 0) // Very slow, each node is O(n_prims^2).
build_binned(bvh: ^BVH, num_bins := 8, curr_index := 0)
iter(bvh: ^BVH) -> Iter
iter_pop(iter: ^Iter) -> bool
iter_next(iter: ^Iter, t0, t1: f32) -> bool // t0, t1: intersection times for the children of the current node. Use max(f32) on miss.
iter_unordered_next(iter: ^Iter, hit0, hit1: bool) -> bool
refit(bvh: ^BVH, index := 0)
calc_sah(bvh: BVH, index := 0) -> f32 // Can be normalized by root surface area.
calc_height(bvh: BVH, index := 0) -> int
vec_min(a, b: [3]f32) -> [3]f32
vec_max(a, b: [3]f32) -> [3]f32
surface_area(min, max: [3]f32) -> f32
```

## ravn_collision

### collision.odin

```odin
init(state: ^State, allocator := context.allocator)
shutdown()
is_step_in_progress() -> bool
get_step_state() -> ^Step_State
begin_step(delta: f32)
end_step()
create_arena(size_in_bytes: u64, allocator := context.allocator, loc := #caller_location) -> (: Arena_Handle, : bool)
destroy_arena(handle: Arena_Handle) -> bool
arena_allocator(handle: Arena_Handle) -> runtime.Allocator
get_arena(handle: Arena_Handle) -> (: ^Arena, : bool)
get_mesh(handle: Mesh_Handle) -> (: ^Mesh, : bool)
create_mesh(arena_handle: Arena_Handle, verts: [][3]f32, triangles: [][3]u16) -> (: Mesh_Handle, : bool) // NOTE: doesn't clone the data. You must allocate it yourself with the
destroy_mesh(handle: Mesh_Handle) -> bool
add_sphere_shape(pos: [3]f32, rad: f32, #any_int layer: u8 = 0, #any_int id: u64 = 0)
add_capsule_shape(p0, p1: [3]f32, rad: f32, #any_int layer: u8 = 0, #any_int id: u64 = 0)
add_box_shape(pos: [3]f32, scale: [3]f32, rad: f32 = 0.0, #any_int layer: u8 = 0, #any_int id: u64 = 0)
add_oriented_box_shape(pos: [3]f32, scale: [3]f32, rot: quaternion128, rad: f32 = 0.0, #any_int layer: u8 = 0, #any_int id: u64 = 0)
add_mesh_shape(handle: Mesh_Handle, pos: [3]f32 = 0, scale: [3]f32 = 1, rot: quaternion128 = 1, rad: f32 = 0.0, #any_int layer: u8 = 0, #any_int id: u64 = 0)
collide_sphere(pos: [3]f32, vel: [3]f32, rad: f32, ignore_layers: bit_set[0 ..< NUM_LAYERS] = {}, max_contacts := 8, max_triangles := 32, allocator := context.temp_allocator) -> (new_pos: [3]f32, new_vel: [3]f32, contacts: []Contact) // Immediate-mode discrete collision.
collide_sphere_swept(pos: [3]f32, vel: [3]f32, rad: f32, ignore_layers: bit_set[0 ..< NUM_LAYERS] = {}, max_sweeps := 4) -> (new_pos: [3]f32, new_vel: [3]f32) // Immediate-mode continous shape-swept collision
make_sweep(pos: [3]f32, move: [3]f32, rad: f32 = 0, range: f32 = 1) -> Sweep
sweep_point(pos: [3]f32, move: [3]f32, range: f32 = 1, ignore_layers: bit_set[0 ..< NUM_LAYERS] = {}) -> (result: Sweep, ok: bool) // World raycast
sweep_sphere(pos: [3]f32, move: [3]f32, rad: f32, range: f32 = 1, ignore_layers: bit_set[0 ..< NUM_LAYERS] = {}) -> (result: Sweep, ok: bool) // World spherecast
eval_sweep(sweep: ^Sweep)
test_sphere(pos: [3]f32, rad: f32, ignore_layers: bit_set[0 ..< NUM_LAYERS] = {}) -> (result: Test, ok: bool) // Checks for *any* collider overlap.
overlap_sphere(pos: [3]f32, rad: f32, max_overlaps := 16, ignore_layers: bit_set[0 ..< NUM_LAYERS] = {}, allocator := context.temp_allocator) -> (result: Overlap, ok: bool) // Returns all overlapping colliders
overlap_sphere_buf(pos: [3]f32, rad: f32, shapes: []i32, ignore_layers: bit_set[0 ..< NUM_LAYERS] = {}) -> (result: Overlap, ok: bool)
find_contacts_sphere(pos: [3]f32, rad: f32, max_contacts := 8, max_triangles := 32, ignore_layers: bit_set[0 ..< NUM_LAYERS] = {}, allocator := context.temp_allocator) -> (result_contacts: []Contact)
find_contacts_sphere_buf(pos: [3]f32, rad: f32, out_contacts: []Contact, out_triangles: []Triangle_Contact, ignore_layers: bit_set[0 ..< NUM_LAYERS]) -> (num_contacts: i32, num_triangles: i32)
generate_filtered_sphere_vs_triangle_contacts(pos: [3]f32, rad: f32, out_contacts: []Contact, triangles: []Triangle_Contact) -> (num_contacts: i32) // https://www.codercorner.com/MeshContacts.pdf
get_shape(shape: i32) -> (: Shape, : bool)
get_mesh_triangle(handle: Mesh_Handle, #any_int tri_index: int) -> (verts: [3][3]f32, ok: bool)
clone_slice(a: $T/[]$E, align: int, allocator := context.allocator, loc := #caller_location) -> (: []E, : bool)
```

### collision_shape.odin

```odin
sweep_point_vs_shape(pos: [3]f32, move: [3]f32, shape: Shape, range: f32) -> (t: f32, prim: i32, ok: bool)
sweep_sphere_vs_shape(pos: [3]f32, move: [3]f32, rad: f32, shape: Shape, range: f32) -> (t: f32, prim: i32, ok: bool)
sweep_point_vs_mesh_local(pos: [3]f32, move: [3]f32, handle: Mesh_Handle, range: f32 = 1) -> (t: f32, prim: i32, ok: bool)
find_contacts_sphere_vs_shape(pos: [3]f32, rad: f32, shape: Shape, out_contacts: []Contact, out_triangles: []Triangle_Contact) -> (num_contacts: i32, num_triangles: i32)
sweep_sphere_vs_mesh_local(pos: [3]f32, move: [3]f32, rad: f32, handle: Mesh_Handle, scale: [3]f32 = 1, range: f32 = 1) -> (t: f32, prim: i32, ok: bool)
test_sphere_vs_mesh_local(pos: [3]f32, rad: f32, handle: Mesh_Handle, scale: [3]f32 = 1) -> (: i32, : bool)
find_potential_contact_triangles_sphere_vs_mesh_local(pos: [3]f32, rad: f32, handle: Mesh_Handle, scale: [3]f32 = 1, out_triangles: []Triangle_Contact) -> (num_triangles: i32)
test_sphere_vs_shape(pos: [3]f32, rad: f32, shape: Shape) -> (prim: i32, ok: bool)
get_shape_aabb(shape: Shape) -> (bb_min, bb_max: [3]f32)
get_shape_gradient(shape: Shape, query_origin_pos: [3]f32, hit: [3]f32, prim: i32) -> (result: [3]f32)
```

## ravn_geometry

### geometry_bounds.odin

```odin
get_oriented_box_bounds(pos: [3]f32, rad: [3]f32, rot: matrix[3, 3]f32) -> (min, max: [3]f32)
```

### geometry_dist.odin

```odin
get_sphere_dist_sq(pos: [3]f32, center: [3]f32, rad: f32) -> f32
get_sphere_dist(pos: [3]f32, center: [3]f32, rad: f32) -> f32
get_sphere_dist_grad(pos: [3]f32, center: [3]f32, rad: f32) -> (dist: f32, grad: [3]f32)
get_box_dist(pos: [3]f32, center: [3]f32, rad: [3]f32) -> f32
get_box_dist_grad(pos: [3]f32, center: [3]f32, rad: [3]f32) -> (dist: f32, grad: [3]f32)
get_line_dist(pos: [3]f32, points: [2][3]f32) -> f32 // Capsule
get_line_dist_sq(pos: [3]f32, points: [2][3]f32) -> f32
get_line_dist_grad(pos: [3]f32, points: [2][3]f32) -> (dist: f32, grad: [3]f32) // Capsule
get_triangle_dist(pos: [3]f32, tri: [3][3]f32) -> (dist: f32)
get_triangle_dist_sq(pos: [3]f32, tri: [3][3]f32) -> (dist: f32)
get_triangle_dist_grad(pos: [3]f32, tri: [3][3]f32) -> (dist: f32, grad: [3]f32)
```

### geometry_sweep.odin

```odin
sweep_point_vs_plane(pos: [3]f32, move: [3]f32, normal: [3]f32, dist: f32, range: f32 = 1) -> (t: f32, ok: bool)
sweep_point_vs_sphere(pos: [3]f32, move: [3]f32, center: [3]f32, rad: f32, range: f32 = 1) -> (t: f32, ok: bool)
sweep_point_vs_sphere_simd(pos: [3]#simd[LANES]f32, move: [3]#simd[LANES]f32, move_len2: #simd[LANES]f32, move_len2_inv: #simd[LANES]f32, center: [3]#simd[LANES]f32, rad: #simd[LANES]f32, range: #simd[LANES]f32 = 1) -> (t: #simd[LANES]f32, ok: #simd[LANES]u32) // NOTE: move vector must have length greater than zero.
sweep_point_vs_aabb(pos: [3]f32, move: [3]f32, aabb_min: [3]f32, aabb_max: [3]f32, range: f32 = 1) -> (t: f32, ok: bool) // NOTE: rays running exactly parallel to one of the planes return miss.
sweep_point_vs_aabb_simd_single(pos: #simd[4]f32, inv_move: #simd[4]f32, aabb_min: #simd[4]f32, aabb_max: #simd[4]f32, range: f32 = 1) -> (t: f32, ok: bool) // W component is ignored
sweep_point_vs_aabb_simd(pos: [3]#simd[LANES]f32, inv_move: [3]#simd[LANES]f32, aabb_min: [3]#simd[LANES]f32, aabb_max: [3]#simd[LANES]f32, range: #simd[LANES]f32 = 1) -> (t: #simd[LANES]f32, ok: #simd[LANES]u32)
sweep_point_vs_triangle(pos: [3]f32, move: [3]f32, tri: [3][3]f32, range: f32 = 1) -> (t: f32, ok: bool)
sweep_point_vs_triangle_simd(pos: [3]#simd[LANES]f32, move: [3]#simd[LANES]f32, tri: [3][3]#simd[LANES]f32, range: #simd[LANES]f32 = 1) -> (t: #simd[LANES]f32, ok: #simd[LANES]u32)
sweep_point_vs_triangle_slab(pos: [3]f32, move: [3]f32, tri: [3][3]f32, rad: f32, range: f32 = 1) -> (t: f32, uv: [2]f32, ok: bool) // Triangle expanded by 2*radius along the normal.
sweep_point_vs_uncapped_cylinder(pos: [3]f32, move: [3]f32, points: [2][3]f32, rad: f32, range: f32 = 1) -> (t: f32, ok: bool)
sweep_point_vs_uncapped_cylinder_simd(pos: [3]#simd[LANES]f32, move: [3]#simd[LANES]f32, points: [2][3]#simd[LANES]f32, rad: #simd[LANES]f32, range: #simd[LANES]f32 = 1) -> (t: #simd[LANES]f32, ok: #simd[LANES]u32)
sweep_point_vs_cylinder(pos: [3]f32, move: [3]f32, points: [2][3]f32, rad: f32, range: f32 = 1) -> (t: f32, ok: bool)
sweep_point_vs_capsule(pos: [3]f32, move: [3]f32, points: [2][3]f32, rad: f32, range: f32 = 1) -> (t: f32, ok: bool) // FIXME: broken endcaps
sweep_sphere_vs_aabb(pos: [3]f32, move: [3]f32, rad: f32, aabb_min: [3]f32, aabb_max: [3]f32, range: f32 = 1) -> (t: f32, ok: bool)
sweep_sphere_vs_triangle(pos: [3]f32, move: [3]f32, rad: f32, tri: [3][3]f32, range: f32 = 1) -> (t: f32, ok: bool)
dot_simd(a, b: [3]#simd[LANES]f32) -> #simd[LANES]f32
cross_simd(a, b: [3]#simd[LANES]f32) -> [3]#simd[LANES]f32
length2_simd(a: [3]#simd[LANES]f32) -> #simd[LANES]f32
approx_rsqrt(x: f32) -> f32
approx_sqrt(x: f32) -> f32
```

### geometry_test.odin

```odin
test_point_vs_aabb(pos: [3]f32, min, max: [3]f32) -> bool
test_point_vs_aabb_simd_single(pos: #simd[4]f32, min, _max: #simd[4]f32) -> bool
test_point_vs_sphere(pos: [3]f32, center: [3]f32, rad: f32) -> bool
test_point_vs_capsule(pos: [3]f32, points: [2][3]f32, rad: f32) -> bool
test_sphere_vs_sphere(pos_a: [3]f32, rad_a: f32, pos_b: [3]f32, rad_b: f32) -> bool
test_sphere_vs_box(pos: [3]f32, rad: f32, center, extent: [3]f32) -> bool
test_sphere_vs_triangle(pos: [3]f32, rad: f32, tri: [3][3]f32) -> bool
test_aabb_vs_aabb(a_min, a_max: [3]f32, b_min, b_max: [3]f32) -> bool
```

### geometry_voronoi.odin

```odin
get_triangle_closest_point(pos: [3]f32, tri: [3][3]f32) -> (closest: [3]f32, feature_kind: Voronoi_Feature_Kind, feature_index: i32) // Edges: 01, 02, 12
```

## ravn_gpu

### gpu.odin

```odin
blend_desc(src_color: Blend_Factor = .Src_Alpha, dst_color: Blend_Factor = .One_Minus_Src_Alpha, src_alpha: Blend_Factor = .Src_Alpha, dst_alpha: Blend_Factor = .One_Minus_Src_Alpha, op_color: Blend_Op = .Add, op_alpha: Blend_Op = .Add) -> Blend_Desc // Alpha blending is default
sampler_desc(filter: Filter, bounds: [3]Texture_Bounds = {.Wrap, .Wrap, .Wrap}, mip_min: f32 = 0, mip_max: f32 = 10, mip_bias: f32 = 0, max_aniso: i32 = 1) -> Sampler_Desc
set_state_ptr(state: ^State)
get_state_ptr() -> (state: ^State)
init(state: ^State, native_window: rawptr) -> bool
is_init_done() -> bool
shutdown()
begin_frame() -> (ok: bool) // return value of false means skip frame
end_frame(sync: bool = true)
pipeline_desc(ps: Shader_Handle, vs: Shader_Handle, out_colors: []Texture_Format, out_depth: Texture_Format = .Invalid, blends: []Blend_Desc = {}, index_resource: Resource_Handle = {}, index_format: Index_Format = .Invalid, index_offset: i32 = 0, samplers: []Sampler_Desc = {}, consts: []Resource_Handle = {}, resources: []Resource_Handle = {}, topo: Topology = .Triangles, cull: Cull_Mode = .None, fill: Fill_Mode = .Solid, depth_comparison: Comparison_Op = .Always, depth_write: bool = false, depth_bias: i32 = 0) -> (result: Pipeline_Desc)
create_pipeline(name: string, desc: Pipeline_Desc, loc := #caller_location) -> (result: Pipeline_Handle, ok: bool) // The pipeline will get re-created only when necessary.
hash_pipeline_desc(desc: Pipeline_Desc) -> Hash
hash_pipeline_bindings_desc(desc: Pipeline_Bindings_Desc) -> Hash
hash_compute_pipeline_desc(desc: Compute_Pipeline_Desc) -> Hash
compute_pipeline_desc(cs: Shader_Handle, samplers: []Sampler_Desc = {}, consts: []Resource_Handle = {}, resources: []Resource_Handle = {}, rw_resources: []Resource_Handle = {}) -> (result: Compute_Pipeline_Desc)
create_compute_pipeline(name: string, desc: Compute_Pipeline_Desc, loc := #caller_location) -> (result: Compute_Pipeline_Handle, ok: bool)
create_constants(name: string, item_size: i32, item_num: i32 = 1) -> (result: Resource_Handle, ok: bool) // Set 'item_num' to 2 or more to enable multi const buffers with dynamic offsets.
create_shader(name: string, data: []byte, kind: Shader_Kind) -> (result: Shader_Handle, ok: bool)
get_swapchain() -> (result: Resource_Handle)
update_swapchain(window: rawptr, size: [2]i32) -> (result: Resource_Handle, ok: bool) // This creates or re-creates the swapchain if already exists.
create_texture_2d(name: string, format: Texture_Format, size: [2]i32, usage: Usage = .Default, mips: i32 = 1, array_depth: i32 = 1, render_texture: bool = false, rw_resource: bool = false, data: []byte = nil) -> (result: Resource_Handle, ok: bool) // TODO: Mips to zero to gen?
create_buffer(name: string, #any_int stride: i32, #any_int size: i32 = 0, usage: Usage = .Default, data: []u8 = nil) -> (result: Resource_Handle, ok: bool) // Must set size or data.
create_index_buffer(name: string, #any_int size: i32 = 0, data: []u8 = nil, usage: Usage = .Default) -> (result: Resource_Handle, ok: bool) // Must set size or data.
destroy :: proc{destroy_shader, destroy_resource}
destroy_shader(handle: Shader_Handle)
destroy_resource(handle: Resource_Handle)
scope_pass(name: string, desc: Pass_Desc) -> bool
begin_pass(name: string, desc: Pass_Desc)
end_pass()
set_pipeline(handle: Pipeline_Handle)
scope_compute_pass(name: string) -> bool
begin_compute_pass(name: string)
end_compute_pass()
set_compute_pipeline(handle: Compute_Pipeline_Handle)
update_constants(handle: Resource_Handle, data: []byte) // WARNING: currently 'data' is not internally copied before use, make sure to keep it alive and valid for the whole pass.
update_buffer(handle: Resource_Handle, offset: int, buffers: ..[]byte) // "buffers" can be multiple separate slices of CPU memory, written consecutively to the GPU memory.
update_texture_2d(handle: Resource_Handle, data: []byte, #any_int slice: i32 = 0)
draw_non_indexed(#any_int vertex_num: u32, #any_int instance_num: u32 = 1, const_offsets: []u32 = nil)
draw_indexed(#any_int index_num: u32, #any_int instance_num: u32 = 1, #any_int index_offset: u32 = 0, const_offsets: []u32 = nil)
dispatch_compute(size: [3]i32)
validate(cond: bool, msg: string = "", loc := #caller_location, expr := #caller_expression(cond)) // TODO: remove the default msg empty value?
validate_pass_desc(desc: Pass_Desc)
validate_pipeline_desc(desc: Pipeline_Desc, loc := #caller_location)
validate_pipeline_for_pass(pip: Pipeline_Desc, pass: Pass_Desc)
validate_compute_pipeline_desc(desc: Compute_Pipeline_Desc, loc := #caller_location)
get_pipeline_desc_bindings(desc: Pipeline_Desc) -> Pipeline_Bindings_Desc
texture_format_is_depth_stencil(format: Texture_Format) -> bool
texture_format_channels(format: Texture_Format) -> i32
texture_pixel_size(format: Texture_Format) -> i32
```

### gpu_util.odin

```odin
ptr_bytes(ptr: ^$T, len := 1) -> []byte
slice_bytes(s: []$T) -> []byte
bucket_find_or_create(bucket: ^$T/Bucket($N, $K, $V), key: K, create_proc: proc(K) -> V) -> (result: V)
clone_to_cstring(s: string, allocator := context.allocator, loc := #caller_location) -> (res: cstring, err: runtime.Allocator_Error)
```

## ravn_platform

### platform.odin

```odin
set_state_ptr(state: ^State)
get_state_ptr() -> (state: ^State)
init(state: ^State)
shutdown()
get_commandline_args(allocator := context.allocator) -> []string
run_shell_command(command: string) -> int
exit_process(code: int)
memory_protect(ptr: rawptr, num_bytes: int, protect: Memory_Protection) -> bool
clipboard_set(data: string) -> bool
clipboard_get(allocator := context.temp_allocator) -> (: string, : bool)
get_gamepad_state(#any_int index: int) -> (result: Gamepad_State, ok: bool)
set_gamepad_feedback(#any_int index: int, output: Gamepad_Feedback) -> bool
get_user_data_dir(allocator := context.allocator) -> string
set_mouse_relative(window: Window, relative: bool)
set_mouse_visible(visible: bool)
set_current_directory(path: string) -> bool
get_executable_path(allocator := context.temp_allocator) -> string
load_module(path: string) -> (result: Module, ok: bool)
unload_module(module: Module)
get_module_symbol_address(module: Module, cstr: cstring) -> (result: rawptr)
sleep_ms(#any_int ms: int)
get_time_ns() -> u64
get_time_sec() -> f32
register_default_exception_handler()
create_thread(procedure: Thread_Proc, name: string) -> Thread
join_thread(thread: Thread)
get_current_thread_id() -> u64
refresh_cpu_core_info()
get_cpu_core_num() -> int
get_cpu_core_info(#any_int core_index: int) -> CPU_Core_Info
pin_thread_to_cpu_core(thread: Thread, #any_int core_index: int) -> bool // thread == {} means current thread
create_window(name: string, style: Window_Style = .Regular, rect: Rect = {}, high_dpi := false) -> Window
destroy_window(window: Window)
set_window_title(window: Window, name: string)
set_window_style(window: Window, style: Window_Style)
set_window_pos(window: Window, pos: [2]i32)
set_window_size(window: Window, size: [2]i32)
get_window_rect(window: Window) -> Rect // Drawable area within the window, without decorators.
set_mouse_pos_window_relative(window: Window, pos: [2]i32)
is_window_minimized(window: Window) -> bool
is_window_focused(window: Window) -> bool
get_window_dpi_scale(window: Window) -> f32
get_native_window_ptr(window: Window) -> rawptr // HWND on windows
poll_window_events(window: Window) -> (event: Event, should_continue: bool)
get_main_monitor_rect() -> Rect
open_file(path: string) -> (: File_Handle, : bool)
close_file(handle: File_Handle)
get_last_write_time(handle: File_Handle) -> (: u64, : bool)
get_last_write_time_by_path(path: string) -> (result: u64, ok: bool)
delete_file(path: string) -> bool
read_file_by_path(path: string, allocator := context.allocator) -> (data: []byte, ok: bool)
write_file_by_path(path: string, data: []u8) -> bool
file_exists(path: string) -> bool
clone_file(dst_path: string, src_path: string, fail_if_exists := false) -> bool
create_directory(path: string) -> bool
is_file(path: string) -> bool
is_directory(path: string) -> bool
iter_directory(iter: ^Directory_Iter, pattern: string, allocator := context.temp_allocator) -> (result: string, ok: bool)
init_file_watcher(watcher: ^File_Watcher, path: string, recursive := false) -> bool // IMPORTANT NOTE: the watcher structure must stay in the same place in memory for it's entire lifetime.
poll_file_watcher(watcher: ^File_Watcher) -> []string
destroy_file_watcher(watcher: ^File_Watcher)
file_dialog(mode: File_Dialog_Mode, default_path: string, patterns: []File_Pattern, title := "") -> (: string, : bool)
clone_to_cstring(s: string, allocator: runtime.Allocator, loc := #caller_location) -> (res: cstring, err: runtime.Allocator_Error)
```

### platform_windows.odin

```odin
win32_set_message_hook_proc(message_hook: Win32_Message_Hook_Proc, data: rawptr = nil)
```

## rscn

### rscn_parser.odin

```odin
init_parser(p: ^Parser, data: string)
make_parser(data: string) -> (result: Parser)
parse_header(p: ^Parser) -> (result: Header, err: Error)
parse_next_elem(p: ^Parser) -> (result: Elem, err: Error)
```

## ravn_shader_compiler

### shader_compiler.odin

```odin
init(state: ^State, target: Target) -> bool // If this returns false the shader compiler is not available. Do not call any other procedures.
compile(state: ^State, name: string, source: string, opts: Options, loc := #caller_location) -> (result: []byte, ok: bool)
clone_to_cstring(s: string, allocator := context.allocator, loc := #caller_location) -> (res: cstring, err: runtime.Allocator_Error)
```

