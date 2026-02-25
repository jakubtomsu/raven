package qoa

import "core:slice"
import "base:runtime"
import "core:testing"
import "core:log"
import "core:strings"
import "../wav"

// Try a different linker if the files bloat compile times too much.
// The samples are from:
// https://qoaformat.org/samples/
// Unzip and put them into a qoa_test_samples directory.

@(private)
_wav_data := [][]runtime.Load_Directory_File{
    #load_directory("qoa_test_samples/oculus_audio_pack"),
    // #load_directory("qoa_test_samples/sqam"),
}

@(private)
_qoa_data := [][]runtime.Load_Directory_File{
    #load_directory("qoa_test_samples/oculus_audio_pack/qoa"),
    // #load_directory("qoa_test_samples/sqam/qoa"),
}

@(private)
_qoa_wav_data := [][]runtime.Load_Directory_File{
    #load_directory("qoa_test_samples/oculus_audio_pack/qoa_wav"),
    // #load_directory("qoa_test_samples/sqam/qoa"),
}


@(test)
file_sanity_test :: proc(t: ^testing.T) {
    testing.expect(t, len(_wav_data) == len(_qoa_data))
    testing.expect(t, len(_wav_data) == len(_qoa_wav_data))
    for dir, i in _wav_data {
        testing.expect(t, len(dir) == len(_qoa_data[i]))
        testing.expect(t, len(dir) == len(_qoa_wav_data[i]))

        for file, j in dir {
            testing.expect(t, len(strings.common_prefix(file.name, _qoa_data[i][j].name)) > 5)
            testing.expect(t, len(strings.common_prefix(file.name, _qoa_wav_data[i][j].name)) > 5)
        }
    }
}

@(test)
encode_test :: proc(t: ^testing.T) {
    for dir, i in _wav_data {
        for file, j in dir {
            defer free_all(context.temp_allocator)

            wav_header, wav_data, wav_ok := wav.decode_header(file.data)
            testing.expect(t, wav_ok)

            assert(wav_header.format.bits_per_sample == 16)
            samples := wav.reinterpret_bytes(i16, wav_data)

            log.infof("Encode %s: %i samples, %i channels, %ihz", file.name, len(samples) / int(wav_header.format.num_channels), wav_header.format.num_channels, wav_header.format.sample_rate)

            desc := Desc{
                samplerate = wav_header.format.sample_rate,
                channels = u32(wav_header.format.num_channels),
            }

            qoa_enc, qoa_ok := encode(&desc, samples, context.temp_allocator)
            testing.expect(t, qoa_ok)

            qoa_src := _qoa_data[i][j].data

            testing.expect(t, len(qoa_enc) == len(qoa_src))
            if !testing.expectf(t, slice.equal(qoa_enc, qoa_src), "%s: data mismatch", file.name) {
                n := 0
                for i in 0..<len(qoa_enc) {
                    if qoa_enc[i] != qoa_src[i] {
                        n += 1
                        log.infof("%s: %i: %i vs %i", file.name, i, qoa_enc[i], qoa_src[i])
                    }
                }
                log.errorf("\tnum different samples: %i", n)
            }
        }
    }
}

@(test)
decode_test :: proc(t: ^testing.T) {
    for dir, i in _wav_data {
        for file, j in dir {
            defer free_all(context.temp_allocator)


            wav_header, wav_data, wav_ok := wav.decode_header(file.data)
            testing.expect(t, wav_ok)
            assert(wav_header.format.bits_per_sample == 16)
            orig_samples := wav.reinterpret_bytes(i16, wav_data)

            qoa_src := _qoa_data[i][j].data
            qoa_wav_src := _qoa_wav_data[i][j].data

            // log.infof("Decode %s: %i samples, %i channels, %ihz", file.name, len(orig_samples) / int(wav_header.format.num_channels), wav_header.format.num_channels, wav_header.format.sample_rate)

            qoa_wav_header, qoa_wav_data, qoa_wav_ok := wav.decode_header(qoa_wav_src)
            testing.expect(t, qoa_wav_ok)
            assert(qoa_wav_header.format.bits_per_sample == 16)
            expected_samples := wav.reinterpret_bytes(i16, qoa_wav_data)

            desc, decoded_samples, decode_ok := decode(qoa_src, context.temp_allocator)

            testing.expect(t, decode_ok)
            testing.expect(t, desc.samples > 0)
            testing.expect(t, desc.channels > 0)
            testing.expect(t, desc.samplerate > 0)
            testing.expect(t, desc.channels == u32(wav_header.format.num_channels))
            testing.expect(t, desc.channels == u32(qoa_wav_header.format.num_channels))
            testing.expect(t, desc.samplerate == wav_header.format.sample_rate)
            testing.expect(t, desc.samplerate == qoa_wav_header.format.sample_rate)
            testing.expect(t, len(decoded_samples) == len(orig_samples))
            testing.expect(t, len(decoded_samples) == len(expected_samples))
            testing.expect(t, slice.equal(decoded_samples, expected_samples))
        }
    }
}