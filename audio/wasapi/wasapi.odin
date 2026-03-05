package windows_wasapi

import "core:sys/windows"
import "core:c"

REFERENCE_TIME :: windows.LONGLONG


// extended waveform format structure used for all non-PCM formats. this
// structure is common to all non-PCM formats.
WAVEFORMATEX :: struct {
    wFormatTag:         windows.WORD,  // format type
    nChannels:          windows.WORD,  // number of channels (i.e. mono, stereo...)
    nSamplesPerSec:     windows.DWORD, // sample rate
    nAvgBytesPerSec:    windows.DWORD, // for buffer estimation
    nBlockAlign:        windows.WORD,  // block size of data
    wBitsPerSample:     windows.WORD,  // number of bits per sample of mono data
    cbSize:             windows.WORD,  // the count in bytes of the size of extra information (after cbSize)
}


//  New wave format development should be based on the
//  WAVEFORMATEXTENSIBLE structure. WAVEFORMATEXTENSIBLE allows you to
//  avoid having to register a new format tag with Microsoft. Simply
//  define a new GUID value for the WAVEFORMATEXTENSIBLE.SubFormat field
//  and use WAVE_FORMAT_EXTENSIBLE in the
//  WAVEFORMATEXTENSIBLE.Format.wFormatTag field.
WAVEFORMATEXTENSIBLE :: struct {
    Format:         WAVEFORMATEX,
    using Samples: struct #raw_union {
        wValidBitsPerSample:    windows.WORD, // bits of precision
        wSamplesPerBlock:       windows.WORD, // valid if wBitsPerSample==0
        wReserved:              windows.WORD, // If neither applies, set to zero.
    },
    dwChannelMask:  windows.DWORD, // which channels are  present in stream
    SubFormat:      windows.GUID,
}


//* WAVE form wFormatTag IDs
WAVE_FORMAT :: enum u32 {
    UNKNOWN                    = 0x0000, /* Microsoft Corporation */
    ADPCM                      = 0x0002, /* Microsoft Corporation */
    IEEE_FLOAT                 = 0x0003, /* Microsoft Corporation */
    VSELP                      = 0x0004, /* Compaq Computer Corp. */
    IBM_CVSD                   = 0x0005, /* IBM Corporation */
    ALAW                       = 0x0006, /* Microsoft Corporation */
    MULAW                      = 0x0007, /* Microsoft Corporation */
    DTS                        = 0x0008, /* Microsoft Corporation */
    DRM                        = 0x0009, /* Microsoft Corporation */
    WMAVOICE9                  = 0x000A, /* Microsoft Corporation */
    WMAVOICE10                 = 0x000B, /* Microsoft Corporation */
    OKI_ADPCM                  = 0x0010, /* OKI */
    DVI_ADPCM                  = 0x0011, /* Intel Corporation */
    IMA_ADPCM                  = .DVI_ADPCM, /*  Intel Corporation */
    MEDIASPACE_ADPCM           = 0x0012, /* Videologic */
    SIERRA_ADPCM               = 0x0013, /* Sierra Semiconductor Corp */
    G723_ADPCM                 = 0x0014, /* Antex Electronics Corporation */
    DIGISTD                    = 0x0015, /* DSP Solutions, Inc. */
    DIGIFIX                    = 0x0016, /* DSP Solutions, Inc. */
    DIALOGIC_OKI_ADPCM         = 0x0017, /* Dialogic Corporation */
    MEDIAVISION_ADPCM          = 0x0018, /* Media Vision, Inc. */
    CU_CODEC                   = 0x0019, /* Hewlett-Packard Company */
    HP_DYN_VOICE               = 0x001A, /* Hewlett-Packard Company */
    YAMAHA_ADPCM               = 0x0020, /* Yamaha Corporation of America */
    SONARC                     = 0x0021, /* Speech Compression */
    DSPGROUP_TRUESPEECH        = 0x0022, /* DSP Group, Inc */
    ECHOSC1                    = 0x0023, /* Echo Speech Corporation */
    AUDIOFILE_AF36             = 0x0024, /* Virtual Music, Inc. */
    APTX                       = 0x0025, /* Audio Processing Technology */
    AUDIOFILE_AF10             = 0x0026, /* Virtual Music, Inc. */
    PROSODY_1612               = 0x0027, /* Aculab plc */
    LRC                        = 0x0028, /* Merging Technologies S.A. */
    DOLBY_AC2                  = 0x0030, /* Dolby Laboratories */
    GSM610                     = 0x0031, /* Microsoft Corporation */
    MSNAUDIO                   = 0x0032, /* Microsoft Corporation */
    ANTEX_ADPCME               = 0x0033, /* Antex Electronics Corporation */
    CONTROL_RES_VQLPC          = 0x0034, /* Control Resources Limited */
    DIGIREAL                   = 0x0035, /* DSP Solutions, Inc. */
    DIGIADPCM                  = 0x0036, /* DSP Solutions, Inc. */
    CONTROL_RES_CR10           = 0x0037, /* Control Resources Limited */
    NMS_VBXADPCM               = 0x0038, /* Natural MicroSystems */
    CS_IMAADPCM                = 0x0039, /* Crystal Semiconductor IMA ADPCM */
    ECHOSC3                    = 0x003A, /* Echo Speech Corporation */
    ROCKWELL_ADPCM             = 0x003B, /* Rockwell International */
    ROCKWELL_DIGITALK          = 0x003C, /* Rockwell International */
    XEBEC                      = 0x003D, /* Xebec Multimedia Solutions Limited */
    G721_ADPCM                 = 0x0040, /* Antex Electronics Corporation */
    G728_CELP                  = 0x0041, /* Antex Electronics Corporation */
    MSG723                     = 0x0042, /* Microsoft Corporation */
    INTEL_G723_1               = 0x0043, /* Intel Corp. */
    INTEL_G729                 = 0x0044, /* Intel Corp. */
    SHARP_G726                 = 0x0045, /* Sharp */
    MPEG                       = 0x0050, /* Microsoft Corporation */
    RT24                       = 0x0052, /* InSoft, Inc. */
    PAC                        = 0x0053, /* InSoft, Inc. */
    MPEGLAYER3                 = 0x0055, /* ISO/MPEG Layer3 Format Tag */
    LUCENT_G723                = 0x0059, /* Lucent Technologies */
    CIRRUS                     = 0x0060, /* Cirrus Logic */
    ESPCM                      = 0x0061, /* ESS Technology */
    VOXWARE                    = 0x0062, /* Voxware Inc */
    CANOPUS_ATRAC              = 0x0063, /* Canopus, co., Ltd. */
    G726_ADPCM                 = 0x0064, /* APICOM */
    G722_ADPCM                 = 0x0065, /* APICOM */
    DSAT                       = 0x0066, /* Microsoft Corporation */
    DSAT_DISPLAY               = 0x0067, /* Microsoft Corporation */
    VOXWARE_BYTE_ALIGNED       = 0x0069, /* Voxware Inc */
    VOXWARE_AC8                = 0x0070, /* Voxware Inc */
    VOXWARE_AC10               = 0x0071, /* Voxware Inc */
    VOXWARE_AC16               = 0x0072, /* Voxware Inc */
    VOXWARE_AC20               = 0x0073, /* Voxware Inc */
    VOXWARE_RT24               = 0x0074, /* Voxware Inc */
    VOXWARE_RT29               = 0x0075, /* Voxware Inc */
    VOXWARE_RT29HW             = 0x0076, /* Voxware Inc */
    VOXWARE_VR12               = 0x0077, /* Voxware Inc */
    VOXWARE_VR18               = 0x0078, /* Voxware Inc */
    VOXWARE_TQ40               = 0x0079, /* Voxware Inc */
    VOXWARE_SC3                = 0x007A, /* Voxware Inc */
    VOXWARE_SC3_1              = 0x007B, /* Voxware Inc */
    SOFTSOUND                  = 0x0080, /* Softsound, Ltd. */
    VOXWARE_TQ60               = 0x0081, /* Voxware Inc */
    MSRT24                     = 0x0082, /* Microsoft Corporation */
    G729A                      = 0x0083, /* AT&T Labs, Inc. */
    MVI_MVI2                   = 0x0084, /* Motion Pixels */
    DF_G726                    = 0x0085, /* DataFusion Systems (Pty) (Ltd) */
    DF_GSM610                  = 0x0086, /* DataFusion Systems (Pty) (Ltd) */
    ISIAUDIO                   = 0x0088, /* Iterated Systems, Inc. */
    ONLIVE                     = 0x0089, /* OnLive! Technologies, Inc. */
    MULTITUDE_FT_SX20          = 0x008A, /* Multitude Inc. */
    INFOCOM_ITS_G721_ADPCM     = 0x008B, /* Infocom */
    CONVEDIA_G729              = 0x008C, /* Convedia Corp. */
    CONGRUENCY                 = 0x008D, /* Congruency Inc. */
    SBC24                      = 0x0091, /* Siemens Business Communications Sys */
    DOLBY_AC3_SPDIF            = 0x0092, /* Sonic Foundry */
    MEDIASONIC_G723            = 0x0093, /* MediaSonic */
    PROSODY_8KBPS              = 0x0094, /* Aculab plc */
    ZYXEL_ADPCM                = 0x0097, /* ZyXEL Communications, Inc. */
    PHILIPS_LPCBB              = 0x0098, /* Philips Speech Processing */
    PACKED                     = 0x0099, /* Studer Professional Audio AG */
    MALDEN_PHONYTALK           = 0x00A0, /* Malden Electronics Ltd. */
    RACAL_RECORDER_GSM         = 0x00A1, /* Racal recorders */
    RACAL_RECORDER_G720_A      = 0x00A2, /* Racal recorders */
    RACAL_RECORDER_G723_1      = 0x00A3, /* Racal recorders */
    RACAL_RECORDER_TETRA_ACELP = 0x00A4, /* Racal recorders */
    NEC_AAC                    = 0x00B0, /* NEC Corp. */
    RAW_AAC1                   = 0x00FF, /* For Raw AAC, with format block AudioSpecificConfig() (as defined by MPEG-4), that follows WAVEFORMATEX */
    RHETOREX_ADPCM             = 0x0100, /* Rhetorex Inc. */
    IRAT                       = 0x0101, /* BeCubed Software Inc. */
    VIVO_G723                  = 0x0111, /* Vivo Software */
    VIVO_SIREN                 = 0x0112, /* Vivo Software */
    PHILIPS_CELP               = 0x0120, /* Philips Speech Processing */
    PHILIPS_GRUNDIG            = 0x0121, /* Philips Speech Processing */
    DIGITAL_G723               = 0x0123, /* Digital Equipment Corporation */
    SANYO_LD_ADPCM             = 0x0125, /* Sanyo Electric Co., Ltd. */
    SIPROLAB_ACEPLNET          = 0x0130, /* Sipro Lab Telecom Inc. */
    SIPROLAB_ACELP4800         = 0x0131, /* Sipro Lab Telecom Inc. */
    SIPROLAB_ACELP8V3          = 0x0132, /* Sipro Lab Telecom Inc. */
    SIPROLAB_G729              = 0x0133, /* Sipro Lab Telecom Inc. */
    SIPROLAB_G729A             = 0x0134, /* Sipro Lab Telecom Inc. */
    SIPROLAB_KELVIN            = 0x0135, /* Sipro Lab Telecom Inc. */
    VOICEAGE_AMR               = 0x0136, /* VoiceAge Corp. */
    G726ADPCM                  = 0x0140, /* Dictaphone Corporation */
    DICTAPHONE_CELP68          = 0x0141, /* Dictaphone Corporation */
    DICTAPHONE_CELP54          = 0x0142, /* Dictaphone Corporation */
    QUALCOMM_PUREVOICE         = 0x0150, /* Qualcomm, Inc. */
    QUALCOMM_HALFRATE          = 0x0151, /* Qualcomm, Inc. */
    TUBGSM                     = 0x0155, /* Ring Zero Systems, Inc. */
    MSAUDIO1                   = 0x0160, /* Microsoft Corporation */
    WMAUDIO2                   = 0x0161, /* Microsoft Corporation */
    WMAUDIO3                   = 0x0162, /* Microsoft Corporation */
    WMAUDIO_LOSSLESS           = 0x0163, /* Microsoft Corporation */
    WMASPDIF                   = 0x0164, /* Microsoft Corporation */
    UNISYS_NAP_ADPCM           = 0x0170, /* Unisys Corp. */
    UNISYS_NAP_ULAW            = 0x0171, /* Unisys Corp. */
    UNISYS_NAP_ALAW            = 0x0172, /* Unisys Corp. */
    UNISYS_NAP_16K             = 0x0173, /* Unisys Corp. */
    SYCOM_ACM_SYC008           = 0x0174, /* SyCom Technologies */
    SYCOM_ACM_SYC701_G726L     = 0x0175, /* SyCom Technologies */
    SYCOM_ACM_SYC701_CELP54    = 0x0176, /* SyCom Technologies */
    SYCOM_ACM_SYC701_CELP68    = 0x0177, /* SyCom Technologies */
    KNOWLEDGE_ADVENTURE_ADPCM  = 0x0178, /* Knowledge Adventure, Inc. */
    FRAUNHOFER_IIS_MPEG2_AAC   = 0x0180, /* Fraunhofer IIS */
    DTS_DS                     = 0x0190, /* Digital Theatre Systems, Inc. */
    CREATIVE_ADPCM             = 0x0200, /* Creative Labs, Inc */
    CREATIVE_FASTSPEECH8       = 0x0202, /* Creative Labs, Inc */
    CREATIVE_FASTSPEECH10      = 0x0203, /* Creative Labs, Inc */
    UHER_ADPCM                 = 0x0210, /* UHER informatic GmbH */
    ULEAD_DV_AUDIO             = 0x0215, /* Ulead Systems, Inc. */
    ULEAD_DV_AUDIO_1           = 0x0216, /* Ulead Systems, Inc. */
    QUARTERDECK                = 0x0220, /* Quarterdeck Corporation */
    ILINK_VC                   = 0x0230, /* I-link Worldwide */
    RAW_SPORT                  = 0x0240, /* Aureal Semiconductor */
    ESST_AC3                   = 0x0241, /* ESS Technology, Inc. */
    GENERIC_PASSTHRU           = 0x0249,
    IPI_HSX                    = 0x0250, /* Interactive Products, Inc. */
    IPI_RPELP                  = 0x0251, /* Interactive Products, Inc. */
    CS2                        = 0x0260, /* Consistent Software */
    SONY_SCX                   = 0x0270, /* Sony Corp. */
    SONY_SCY                   = 0x0271, /* Sony Corp. */
    SONY_ATRAC3                = 0x0272, /* Sony Corp. */
    SONY_SPC                   = 0x0273, /* Sony Corp. */
    TELUM_AUDIO                = 0x0280, /* Telum Inc. */
    TELUM_IA_AUDIO             = 0x0281, /* Telum Inc. */
    NORCOM_VOICE_SYSTEMS_ADPCM = 0x0285, /* Norcom Electronics Corp. */
    FM_TOWNS_SND               = 0x0300, /* Fujitsu Corp. */
    MICRONAS                   = 0x0350, /* Micronas Semiconductors, Inc. */
    MICRONAS_CELP833           = 0x0351, /* Micronas Semiconductors, Inc. */
    BTV_DIGITAL                = 0x0400, /* Brooktree Corporation */
    INTEL_MUSIC_CODER          = 0x0401, /* Intel Corp. */
    INDEO_AUDIO                = 0x0402, /* Ligos */
    QDESIGN_MUSIC              = 0x0450, /* QDesign Corporation */
    ON2_VP7_AUDIO              = 0x0500, /* On2 Technologies */
    ON2_VP6_AUDIO              = 0x0501, /* On2 Technologies */
    VME_VMPCM                  = 0x0680, /* AT&T Labs, Inc. */
    TPC                        = 0x0681, /* AT&T Labs, Inc. */
    LIGHTWAVE_LOSSLESS         = 0x08AE, /* Clearjump */
    OLIGSM                     = 0x1000, /* Ing C. Olivetti & C., S.p.A. */
    OLIADPCM                   = 0x1001, /* Ing C. Olivetti & C., S.p.A. */
    OLICELP                    = 0x1002, /* Ing C. Olivetti & C., S.p.A. */
    OLISBC                     = 0x1003, /* Ing C. Olivetti & C., S.p.A. */
    OLIOPR                     = 0x1004, /* Ing C. Olivetti & C., S.p.A. */
    LH_CODEC                   = 0x1100, /* Lernout & Hauspie */
    LH_CODEC_CELP              = 0x1101, /* Lernout & Hauspie */
    LH_CODEC_SBC8              = 0x1102, /* Lernout & Hauspie */
    LH_CODEC_SBC12             = 0x1103, /* Lernout & Hauspie */
    LH_CODEC_SBC16             = 0x1104, /* Lernout & Hauspie */
    NORRIS                     = 0x1400, /* Norris Communications, Inc. */
    ISIAUDIO_2                 = 0x1401, /* ISIAudio */
    SOUNDSPACE_MUSICOMPRESS    = 0x1500, /* AT&T Labs, Inc. */
    MPEG_ADTS_AAC              = 0x1600, /* Microsoft Corporation */
    MPEG_RAW_AAC               = 0x1601, /* Microsoft Corporation */
    MPEG_LOAS                  = 0x1602, /* Microsoft Corporation (MPEG-4 Audio Transport Streams (LOAS/LATM) */
    NOKIA_MPEG_ADTS_AAC        = 0x1608, /* Microsoft Corporation */
    NOKIA_MPEG_RAW_AAC         = 0x1609, /* Microsoft Corporation */
    VODAFONE_MPEG_ADTS_AAC     = 0x160A, /* Microsoft Corporation */
    VODAFONE_MPEG_RAW_AAC      = 0x160B, /* Microsoft Corporation */
    MPEG_HEAAC                 = 0x1610, /* Microsoft Corporation (MPEG-2 AAC or MPEG-4 HE-AAC v1/v2 streams with any payload (ADTS, ADIF, LOAS/LATM, RAW). Format block includes MP4 AudioSpecificConfig() -- see HEAACWAVEFORMAT below */
    VOXWARE_RT24_SPEECH        = 0x181C, /* Voxware Inc. */
    SONICFOUNDRY_LOSSLESS      = 0x1971, /* Sonic Foundry */
    INNINGS_TELECOM_ADPCM      = 0x1979, /* Innings Telecom Inc. */
    LUCENT_SX8300P             = 0x1C07, /* Lucent Technologies */
    LUCENT_SX5363S             = 0x1C0C, /* Lucent Technologies */
    CUSEEME                    = 0x1F03, /* CUSeeMe */
    NTCSOFT_ALF2CM_ACM         = 0x1FC4, /* NTCSoft */
    DVM                        = 0x2000, /* FAST Multimedia AG */
    DTS2                       = 0x2001,
    MAKEAVIS                   = 0x3313,
    DIVIO_MPEG4_AAC            = 0x4143, /* Divio, Inc. */
    NOKIA_ADAPTIVE_MULTIRATE   = 0x4201, /* Nokia */
    DIVIO_G726                 = 0x4243, /* Divio, Inc. */
    LEAD_SPEECH                = 0x434C, /* LEAD Technologies */
    LEAD_VORBIS                = 0x564C, /* LEAD Technologies */
    WAVPACK_AUDIO              = 0x5756, /* xiph.org */
    ALAC                       = 0x6C61, /* Apple Lossless */
    OGG_VORBIS_MODE_1          = 0x674F, /* Ogg Vorbis */
    OGG_VORBIS_MODE_2          = 0x6750, /* Ogg Vorbis */
    OGG_VORBIS_MODE_3          = 0x6751, /* Ogg Vorbis */
    OGG_VORBIS_MODE_1_PLUS     = 0x676F, /* Ogg Vorbis */
    OGG_VORBIS_MODE_2_PLUS     = 0x6770, /* Ogg Vorbis */
    OGG_VORBIS_MODE_3_PLUS     = 0x6771, /* Ogg Vorbis */
    _3COM_NBX                  = 0x7000, /* 3COM Corp. */
    OPUS                       = 0x704F, /* Opus */
    FAAD_AAC                   = 0x706D,
    AMR_NB                     = 0x7361, /* AMR Narrowband */
    AMR_WB                     = 0x7362, /* AMR Wideband */
    AMR_WP                     = 0x7363, /* AMR Wideband Plus */
    GSM_AMR_CBR                = 0x7A21, /* GSMA/3GPP */
    GSM_AMR_VBR_SID            = 0x7A22, /* GSMA/3GPP */
    COMVERSE_INFOSYS_G723_1    = 0xA100, /* Comverse Infosys */
    COMVERSE_INFOSYS_AVQSBC    = 0xA101, /* Comverse Infosys */
    COMVERSE_INFOSYS_SBC       = 0xA102, /* Comverse Infosys */
    SYMBOL_G729_A              = 0xA103, /* Symbol Technologies */
    VOICEAGE_AMR_WB            = 0xA104, /* VoiceAge Corp. */
    INGENIENT_G726             = 0xA105, /* Ingenient Technologies, Inc. */
    MPEG4_AAC                  = 0xA106, /* ISO/MPEG-4 */
    ENCORE_G726                = 0xA107, /* Encore Software */
    ZOLL_ASAO                  = 0xA108, /* ZOLL Medical Corp. */
    SPEEX_VOICE                = 0xA109, /* xiph.org */
    VIANIX_MASC                = 0xA10A, /* Vianix LLC */
    WM9_SPECTRUM_ANALYZER      = 0xA10B, /* Microsoft */
    WMF_SPECTRUM_ANAYZER       = 0xA10C, /* Microsoft */
    GSM_610                    = 0xA10D,
    GSM_620                    = 0xA10E,
    GSM_660                    = 0xA10F,
    GSM_690                    = 0xA110,
    GSM_ADAPTIVE_MULTIRATE_WB  = 0xA111,
    POLYCOM_G722               = 0xA112, /* Polycom */
    POLYCOM_G728               = 0xA113, /* Polycom */
    POLYCOM_G729_A             = 0xA114, /* Polycom */
    POLYCOM_SIREN              = 0xA115, /* Polycom */
    GLOBAL_IP_ILBC             = 0xA116, /* Global IP */
    RADIOTIME_TIME_SHIFT_RADIO = 0xA117, /* RadioTime */
    NICE_ACA                   = 0xA118, /* Nice Systems */
    NICE_ADPCM                 = 0xA119, /* Nice Systems */
    VOCORD_G721                = 0xA11A, /* Vocord Telecom */
    VOCORD_G726                = 0xA11B, /* Vocord Telecom */
    VOCORD_G722_1              = 0xA11C, /* Vocord Telecom */
    VOCORD_G728                = 0xA11D, /* Vocord Telecom */
    VOCORD_G729                = 0xA11E, /* Vocord Telecom */
    VOCORD_G729_A              = 0xA11F, /* Vocord Telecom */
    VOCORD_G723_1              = 0xA120, /* Vocord Telecom */
    VOCORD_LBC                 = 0xA121, /* Vocord Telecom */
    NICE_G728                  = 0xA122, /* Nice Systems */
    FRACE_TELECOM_G729         = 0xA123, /* France Telecom */
    CODIAN                     = 0xA124, /* CODIAN */
    DOLBY_AC4                  = 0xAC40, /* Dolby AC-4 */
    FLAC                       = 0xF1AC, /* flac.sourceforge.net */
    EXTENSIBLE                 = 0xFFFE, /* Microsoft */
}


// Speaker Positions
SPEAKER :: enum u32 {
    FRONT_LEFT              = 0x1,
    FRONT_RIGHT             = 0x2,
    FRONT_CENTER            = 0x4,
    LOW_FREQUENCY           = 0x8,
    BACK_LEFT               = 0x10,
    BACK_RIGHT              = 0x20,
    FRONT_LEFT_OF_CENTER    = 0x40,
    FRONT_RIGHT_OF_CENTER   = 0x80,
    BACK_CENTER             = 0x100,
    SIDE_LEFT               = 0x200,
    SIDE_RIGHT              = 0x400,
    TOP_CENTER              = 0x800,
    TOP_FRONT_LEFT          = 0x1000,
    TOP_FRONT_CENTER        = 0x2000,
    TOP_FRONT_RIGHT         = 0x4000,
    TOP_BACK_LEFT           = 0x8000,
    TOP_BACK_CENTER         = 0x10000,
    TOP_BACK_RIGHT          = 0x20000,
    RESERVED                = 0x7FFC0000, // Bit mask locations reserved for future use
    ALL                     = 0x80000000, // Used to specify that any possible permutation of speaker configurations
}


KSDATAFORMAT_SUBTYPE_IEEE_FLOAT_STRING :: "00000003-0000-0010-8000-00aa00389b71"
KSDATAFORMAT_SUBTYPE_IEEE_FLOAT_UUID := &windows.IID{0x00000003, 0x0000, 0x0010, 0x8000, {0x00, 0xaa, 0x00, 0x38, 0x9b, 0x71}}



//-------------------------------------------------------------------------
// Description: AudioClient share mode
//
//     AUDCLNT_SHAREMODE_SHARED -    The device will be opened in shared mode and use the
//                                   WAS format.
//     AUDCLNT_SHAREMODE_EXCLUSIVE - The device will be opened in exclusive mode and use the
//                                   application specified format.
//
AUDCLNT_SHAREMODE :: u32 {
    SHARED,
    EXCLUSIVE
}

//-------------------------------------------------------------------------
// Description: Audio stream categories
//
// ForegroundOnlyMedia     - (deprecated for Win10) Music, Streaming audio
// BackgroundCapableMedia  - (deprecated for Win10) Video with audio
// Communications          - VOIP, chat, phone call
// Alerts                  - Alarm, Ring tones
// SoundEffects            - Sound effects, clicks, dings
// GameEffects             - Game sound effects
// GameMedia               - Background audio for games
// GameChat                - In game player chat
// Speech                  - Speech recognition
// Media                   - Music, Streaming audio
// Movie                   - Video with audio
// FarFieldSpeech          - Capture of far field speech
// UniformSpeech           - Uniform, device agnostic speech processing
// VoiceTyping             - Dictation, typing by voice
// Other                   - All other streams (default)
AUDIO_STREAM_CATEGORY :: enum u32 {
    Other = 0,
    ForegroundOnlyMedia = 1,
    BackgroundCapableMedia = 2, // #if NTDDI_VERSION < NTDDI_WINTHRESHOLD
    Communications = 3,
    Alerts = 4,
    SoundEffects = 5,
    GameEffects = 6,
    GameMedia = 7,
    GameChat = 8,
    Speech = 9,
    Movie = 10,
    Media = 11,
    FarFieldSpeech = 12, // #if NTDDI_VERSION >= NTDDI_WIN10_FE
    UniformSpeech = 13, // #if NTDDI_VERSION >= NTDDI_WIN10_FE
    VoiceTyping = 14, // #if NTDDI_VERSION >= NTDDI_WIN10_FE
}


//-------------------------------------------------------------------------
// Description: AudioClient stream flags
//
// Can be a combination of AUDCLNT_STREAMFLAGS and AUDCLNT_SYSFXFLAGS:
//
// AUDCLNT_STREAMFLAGS (this group of flags uses the high word,
// w/exception of high-bit which is reserved, 0x7FFF0000):
//
//
//     AUDCLNT_STREAMFLAGS_CROSSPROCESS -             Audio policy control for this stream will be shared with
//                                                    with other process sessions that use the same audio session
//                                                    GUID.
//
//     AUDCLNT_STREAMFLAGS_LOOPBACK -                 Initializes a renderer endpoint for a loopback audio application.
//                                                    In this mode, a capture stream will be opened on the specified
//                                                    renderer endpoint. Shared mode and a renderer endpoint is required.
//                                                    Otherwise the IAudioClient::Initialize call will fail. If the
//                                                    initialize is successful, a capture stream will be available
//                                                    from the IAudioClient object.
//
//     AUDCLNT_STREAMFLAGS_EVENTCALLBACK -            An exclusive mode client will supply an event handle that will be
//                                                    signaled when an IRP completes (or a waveRT buffer completes) telling
//                                                    it to fill the next buffer
//
//     AUDCLNT_STREAMFLAGS_NOPERSIST -                Session state will not be persisted
//
//     AUDCLNT_STREAMFLAGS_RATEADJUST -               The sample rate of the stream is adjusted to a rate specified by an application.
//
//     AUDCLNT_STREAMFLAGS_SRC_DEFAULT_QUALITY -      When used with AUDCLNT_STREAMFLAGS_AUTOCONVERTPCM, a sample rate
//                                                    converter with better quality than the default conversion but with a
//                                                    higher performance cost is used. This should be used if the audio is
//                                                    ultimately intended to be heard by humans as opposed to other
//                                                    scenarios such as pumping silence or populating a meter.
//
//     AUDCLNT_STREAMFLAGS_AUTOCONVERTPCM -           A channel matrixer and a sample rate converter are inserted as necessary
//                                                    to convert between the uncompressed format supplied to
//                                                    IAudioClient::Initialize and the audio engine mix format.
//
//     AUDCLNT_SESSIONFLAGS_EXPIREWHENUNOWNED -       Session expires when there are no streams and no owning
//                                                    session controls.
//
//     AUDCLNT_SESSIONFLAGS_DISPLAY_HIDE -            Don't show volume control in the Volume Mixer.
//
//     AUDCLNT_SESSIONFLAGS_DISPLAY_HIDEWHENEXPIRED - Don't show volume control in the Volume Mixer after the
//                                                    session expires.
//
//
// AUDCLNT_SYSFXFLAGS (these flags use low word 0x0000FFFF):
//
//     none defined currently
//
AUDCLNT_FLAG :: enum u32 {
    STREAMF_CROSSPROCESS             = 0x00010000,
    STREAMF_LOOPBACK                 = 0x00020000,
    STREAMF_EVENTCALLBACK            = 0x00040000,
    STREAMF_NOPERSIST                = 0x00080000,
    STREAMF_RATEADJUST               = 0x00100000,
    STREAMF_SRC_DEFAULT_QUALITY      = 0x08000000,
    STREAMF_AUTOCONVERTPCM           = 0x80000000,
    SESSIONF_EXPIREWHENUNOWNED       = 0x10000000,
    SESSIONF_DISPLAY_HIDE            = 0x20000000,
    SESSIONF_DISPLAY_HIDEWHENEXPIRED = 0x40000000,
}

EDataFlow :: enum u32 {
    Render,
    Capture,
    All,
}

ERole :: enum u32 {
    Console,
    Multimedia,
    Communications,
}

// MARK: IMMDeviceEnumerator

IMMDeviceEnumerator :: struct #raw_union {
    #subtype iunknown: windows.IUnknown,
    using immdeviceenumerator_vtable: ^IMMDeviceEnumerator_VTable,
}

IMMDeviceEnumerator_VTable :: struct {
    using iunknown_vtable:  windows.IUnknown_VTable,

    EnumAudioEndpoints: proc "system" (
        This: ^IMMDeviceEnumerator,
        dataFlow: EDataFlow,
        dwStateMask: windows.DWORD,
        ppDevices: [^]IMMDeviceCollection, // Out
    ) -> windows.HRESULT,

    GetDefaultAudioEndpoint: proc "system" (
        This: ^IMMDeviceEnumerator,
        dataFlow: EDataFlow,
        role: ERole,
        ppEndpoint: [^]IMMDevice, // Out
    ) -> windows.HRESULT,

    GetDevice: proc "system" (
        This: ^IMMDeviceEnumerator,
        pwstrId: windows.LPCWSTR,
        ppDevice: [^]IMMDevice, // Out
    ) -> windows.HRESULT,

    RegisterEndpointNotificationCallback: proc "system" (
        This: ^IMMDeviceEnumerator,
        pClient: ^IMMNotificationClient, // In
    ) -> windows.HRESULT,

    UnregisterEndpointNotificationCallback: proc "system" (
        This: ^IMMDeviceEnumerator,
        pClient: ^IMMNotificationClient, // In
    ) -> windows.HRESULT,
}



// MARK: IMMDevice

IMMDevice :: struct #raw_union {
    #subtype iunknown: windows.IUnknown,
    using immdevice_vtable: ^IMMDevice_VTable,
}

IMMDevice_VTable :: struct {
    using iunknown_vtable:  windows.IUnknown_VTable,

    Activate: proc "system" (
        This: ^IMMDevice,
        iid: windows.REFIID, // In
        dwClsCtx: windows.DWORD, // In
        pActivationParams: ^rawptr, // In Optional PROPVARIANT
        ppInterface: [^]rawptr, // Out
    ) -> windows.HRESULT,

    OpenPropertyStore: proc "system" (
        This: ^IMMDevice,
        stgmAccess: windows.DWORD, // In
        ppProperties: [^]^IPropertyStore, // Out
    ) -> windows.HRESULT,

    GetId: proc "system" (
        This: ^IMMDevice,
        ppstrId: ^LPWSTR, // Out
    ) -> windows.HRESULT,

    GetState: proc "system" (
        This: ^IMMDevice,
        pdwState: ^windows.DWORD, // Out
    ) -> windows.HRESULT,
}



// MARK: IAudioClient

IAudioClient :: struct #raw_union {
    #subtype iunknown: windows.IUnknown,
    using iaudioclient_vtable: ^IAudioClient_VTable,
}

IAudioClient_VTable :: struct {
    using iunknown_vtable:  windows.IUnknown_VTable,

    Initialize: proc "system" (
        This: ^IAudioClient,
        ShareMode: AUDCLNT_SHAREMODE,
        StreamFlags: windows.DWORD,
        hnsBufferDuration: REFERENCE_TIME,
        hnsPeriodicity: REFERENCE_TIME,
        pFormat: ^WAVEFORMATEX, // Const In
        AudioSessionGuid: LPCGUID, // In Optional
    ) -> windows.HANDLE,

    GetBufferSize: proc "system" (
        This: ^IAudioClient,
        pNumBufferFrames: ^u32, // Out
    ) -> windows.HANDLE,

    GetStreamLatency: proc "system" (
        This: ^IAudioClient,
        phnsLatency: ^REFERENCE_TIME, // Out
    ) -> windows.HANDLE,

    GetCurrentPadding: proc "system" (
        This: ^IAudioClient,
        pNumPaddingFrames: ^u32, // Out
    ) -> windows.HANDLE,

    IsFormatSupported: proc "system" (
        This: ^IAudioClient,
        ShareMode: AUDCLNT_SHAREMODE, // In
        pFormat: ^WAVEFORMATEX, // Const In
        ppClosestMatch: ^^WAVEFORMATEX, // Out Optional
    ) -> windows.HANDLE,

    GetMixFormat: proc "system" (
        This: ^IAudioClient,
        ppDeviceFormat: ^^WAVEFORMATEX, // Out
    ) -> windows.HANDLE,

    GetDevicePeriod: proc "system" (
        This: ^IAudioClient,
        phnsDefaultDevicePeriod: ^REFERENCE_TIME, // Out Optional
        phnsMinimumDevicePeriod: ^REFERENCE_TIME, // Out Optional
    ) -> windows.HANDLE,

    Start: proc "system" (This: ^IAudioClient) -> windows.HANDLE,
    Stop: proc "system" (This: ^IAudioClient) -> windows.HANDLE,
    Reset: proc "system" (This: ^IAudioClient) -> windows.HANDLE,

    SetEventHandle: proc "system" (
        This: ^IAudioClient,
        eventHandle: windows.HANDLE,
    ) -> windows.HANDLE,

    GetService: proc "system" (
        This: ^IAudioClient,
        riid: windows.REFIID, // In
        ppv: ^rawptr, // Out
    ) -> windows.HANDLE,
}



// MARK: IAudioClient2

IAudioClient2 :: struct #raw_union {
    #subtype iunknown: windows.IUnknown,
    using iaudioclient2_vtable: ^IAudioClient2_VTable,
}

IAudioClient2_VTable :: struct {
    using iunknown_vtable:      windows.IUnknown_VTable,
    using iaudioclient_vtable:  IAudioClient_VTable,

    IsOffloadCapable: proc "system" (
        This: ^IAudioClient2,
        Category: AUDIO_STREAM_CATEGORY,
        pbOffloadCapable: ^windows.BOOL, // Out
    ) -> windows.HRESULT,

    SetClientProperties: proc "system" (
        This: ^IAudioClient2,
        pProperties: ^AudioClientProperties, // Const In
    ) -> windows.HRESULT,

    GetBufferSizeLimits: proc "system" (
        This: ^IAudioClient2,
        pFormat: ^WAVEFORMATEX, // Const In
        bEventDriven: windows.BOOL,
        phnsMinBufferDuration: ^REFERENCE_TIME, // Out
        phnsMaxBufferDuration: ^REFERENCE_TIME, // Out
    ) -> windows.HRESULT,
}



// MARK: IAudioClient3

IAudioClient3 :: struct #raw_union {
    #subtype iunknown: windows.IUnknown,
    using iaudioclient3_vtable: ^IAudioClient3_VTable,
}

IAudioClient3_VTable :: struct {
    using iunknown_vtable:  windows.IUnknown_VTable,
    using iaudioclient_vtable: IAudioClient_VTable,
    using iaudioclient2_vtable: IAudioClient2_VTable,

    GetSharedModeEnginePeriod: proc "system" (
        This: ^IAudioClient3,
        pFormat: ^WAVEFORMATEX, // Const In
        pDefaultPeriodInFrames: ^u32, // Out
        pFundamentalPeriodInFrames: ^u32, // Out
        pMinPeriodInFrames: ^u32, // Out
        pMaxPeriodInFrames: ^u32, // Out
    ) -> windows.HRESULT,

    GetCurrentSharedModeEnginePeriod: proc "system" (
        This: ^IAudioClient3,
        ppFormat: ^^WAVEFORMATEX, // Out
        pCurrentPeriodInFrames: ^u32, // Out
    ) -> windows.HRESULT,

    InitializeSharedAudioStream: proc "system" (
        This: ^IAudioClient3,
        StreamFlags: windows.DWORD,
        PeriodInFrames: u32,
        pFormat: ^WAVEFORMATEX, // Const In
        AudioSessionGuid: windows.LPCGUID, // In Optional
    ) -> windows.HRESULT,
}



// MARK: IAudioRenderClient

IAudioRenderClient :: struct #raw_union {
    #subtype iunknown: windows.IUnknown,
    using iaudiorenderclient_vtable: ^IAudioRenderClient_VTable,
}

IAudioRenderClient_VTable :: struct {
    GetBuffer: proc "system" (
        This: ^IAudioRenderClient,
        NumFramesRequested: u32,
        ppData: ^[^]byte, // NumFramesRequested * pFormat->nBlockAlign
    ) -> windows.HRESULT,

    ReleaseBuffer: proc "system" (
        This: ^IAudioRenderClient,
        NumFramesWritten: u32,
        dwFlags: windows.DWORD,
    ) -> windows.HRESULT,
}
