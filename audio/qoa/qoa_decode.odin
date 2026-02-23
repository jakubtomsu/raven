#+vet explicit-allocators shadowing unused
package qoa

max_frame_size :: proc(desc: ^Desc) -> u32 {
    return _frame_size(desc.channels, SLICES_PER_FRAME)
}

decode :: proc(data: []byte, allocator := context.allocator) -> (desc: Desc, result: []i16, ok: bool) {
    buf: Buffer = {
        data = data,
        offs = 0,
    }

    desc, ok = decode_header(&buf)
    if !ok {
		log(.Error, "QOA: Failed to decode header")
        return {}, nil, false
    }

    // Calculate the required size of the sample buffer and allocate
    result = make([]i16, desc.samples * desc.channels, allocator = allocator)

    sample_index: u32 = 0

    // Decode all frames
    for {
        samples := result[sample_index * desc.channels:]
        frame_len := decode_frame(&buf, &desc, sample_data = samples)
        sample_index += frame_len

        if frame_len == 0 || sample_index >= desc.samples {
            break
        }
    }

    desc.samples = sample_index
    return desc, result, true
}

decode_header :: proc(buf: ^Buffer) -> (desc: Desc, ok: bool) {
    if len(buf.data[buf.offs:]) < MIN_FILESIZE {
		log(.Error, "QOA: Input buffer is too small to decode a header")
        return {}, false
    }

    // Read the file header, verify the magic number ('qoaf') and read the
    // total number of samples.
    file_header := read_u64(buf)

    if u32(file_header >> 32) != MAGIC {
		log(.Error, "QOA: Header magic mismatch")
        return {}, false
    }

    desc.samples = u32(file_header & 0xffffffff)
    if desc.samples == 0 {
		log(.Error, "QOA: Streaming not supported")
        return {}, false
    }

    // Peek into the first frame header to get the number of channels and
    // the samplerate.
    frame_header := read_u64(buf)
    desc.channels   = u32(frame_header >> 56) & 0x0000ff
    desc.samplerate = u32(frame_header >> 32) & 0xffffff

    if desc.channels == 0 || desc.samples == 0 || desc.samplerate == 0 {
		log(.Error, "QOA: Invalid header parameters")
        return {}, false
    }

    return desc, true
}

decode_frame :: proc(buf: ^Buffer, desc: ^Desc, sample_data: []i16) -> (frame_len: u32) {
    size := len(buf.data[buf.offs:])
    if u32(size) < 8 + LMS_LEN * 4 * desc.channels {
		log(.Error, "QOA: Input buffer is too small to decode a frame")
        return 0
    }

    // Read and verify the frame header
    frame_header := read_u64(buf)
    channels   := u32(frame_header >> 56) & 0x0000ff
    samplerate := u32(frame_header >> 32) & 0xffffff
    samples    := u32(frame_header >> 16) & 0x00ffff
    frame_size := u32(frame_header      ) & 0x00ffff

    data_size: u32 = frame_size - 8 - LMS_LEN * 4 * channels
    num_slices: u32 = data_size / 8
    max_total_samples: u32 = num_slices * SLICE_LEN

    if (
        channels != desc.channels ||
        samplerate != desc.samplerate ||
        int(frame_size) > size ||
        samples * channels > max_total_samples
    ) {
        return 0
    }


    /* Read the LMS state: 4 x 2 bytes history, 4 x 2 bytes weights per channel */
    for c in 0..<channels {
        history := read_u64(buf)
        weights := read_u64(buf)
        for i in 0..<LMS_LEN {
            desc.lms[c].history[i] = i32(history >> 48)
            history <<= 16
            desc.lms[c].weights[i] = i32(weights >> 48)
            weights <<= 16
        }
    }


    /* Decode all slices for all channels in this frame */
    for sample_index: u32; sample_index < samples; sample_index += SLICE_LEN {
        for c in 0..<channels {
            slice := read_u64(buf)

            scalefactor := i32(slice >> 60) & 0xf
            slice <<= 4

            slice_start := i32(sample_index * channels + c)
            slice_end := i32(clamp(sample_index + SLICE_LEN, 0, samples) * channels + c)

            for si := slice_start; si < slice_end; si += i32(channels) {
                predicted: i32 = lms_predict(desc.lms[c])
                quantized := i32(slice >> 61) & 0x7
                dequantized := _dequant_tab[scalefactor][quantized]
                reconstructed := clamp_s16(predicted + dequantized)

                sample_data[si] = i16(reconstructed)
                slice <<= 3

                lms_update(&desc.lms[c], reconstructed, dequantized)
            }
        }
    }

    frame_len = samples
    return frame_len
}
