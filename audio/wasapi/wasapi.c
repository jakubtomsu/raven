#include <windows.h>
#include <mmdeviceapi.h>
#include <audioclient.h>
#include <math.h>
#include <stdio.h>

#define PI 3.1415926535f
#define FREQ 440.0f
#define SAMPLE_RATE 48000

int main() {
    HRESULT hr;
    CoInitializeEx(NULL, COINIT_MULTITHREADED);

    // 1. Get the default audio output device
    IMMDeviceEnumerator *enumerator = NULL;
    IMMDevice *device = NULL;
    CoCreateInstance(&CLSID_MMDeviceEnumerator, NULL, CLSCTX_ALL, &IID_IMMDeviceEnumerator, (void**)&enumerator);
    enumerator->lpVtbl->GetDefaultAudioEndpoint(enumerator, eRender, eConsole, &device);

    // 2. Initialize the Audio Client
    IAudioClient *audioClient = NULL;
    device->lpVtbl->Activate(device, &IID_IAudioClient, CLSCTX_ALL, NULL, (void**)&audioClient);

    // Define f32 Stereo Format
    WAVEFORMATEX *pwfx = NULL;
    WAVEFORMATEXTENSIBLE wfx = {0};
    wfx.Format.wFormatTag = WAVE_FORMAT_EXTENSIBLE;
    wfx.Format.nChannels = 2;
    wfx.Format.nSamplesPerSec = SAMPLE_RATE;
    wfx.Format.wBitsPerSample = 32;
    wfx.Format.nBlockAlign = (wfx.Format.nChannels * wfx.Format.wBitsPerSample) / 8;
    wfx.Format.nAvgBytesPerSec = wfx.Format.nSamplesPerSec * wfx.Format.nBlockAlign;
    wfx.Format.cbSize = sizeof(WAVEFORMATEXTENSIBLE) - sizeof(WAVEFORMATEX);
    wfx.Samples.wValidBitsPerSample = 32;
    wfx.dwChannelMask = SPEAKER_FRONT_LEFT | SPEAKER_FRONT_RIGHT;
    wfx.SubFormat = KSDATAFORMAT_SUBTYPE_IEEE_FLOAT;

    REFERENCE_TIME bufferDuration = 10000000 / 10; // 100ms buffer
    hr = audioClient->lpVtbl->Initialize(audioClient, AUDCLNT_SHAREMODE_SHARED,
         AUDCLNT_STREAMFLAGS_EVENTCALLBACK, bufferDuration, 0, (WAVEFORMATEX*)&wfx, NULL);

    // 3. Set up the event handle for low-latency sync
    HANDLE bufferEvent = CreateEvent(NULL, FALSE, FALSE, NULL);
    audioClient->lpVtbl->SetEventHandle(audioClient, bufferEvent);

    IAudioRenderClient *renderClient = NULL;
    audioClient->lpVtbl->GetService(audioClient, &IID_IAudioRenderClient, (void**)&renderClient);

    UINT32 bufferFrameCount;
    audioClient->lpVtbl->GetBufferSize(audioClient, &bufferFrameCount);

    audioClient->lpVtbl->Start(audioClient);

    float phase = 0;
    printf("Playing 440Hz Sine Wave... Press Ctrl+C to stop.\n");

    while (1) {
        WaitForSingleObject(bufferEvent, INFINITE);

        UINT32 padding;
        audioClient->lpVtbl->GetCurrentPadding(audioClient, &padding);
        UINT32 framesAvailable = bufferFrameCount - padding;

        float *data;
        renderClient->lpVtbl->GetBuffer(renderClient, framesAvailable, (BYTE**)&data);

        // 4. Fill the buffer
        for (UINT32 i = 0; i < framesAvailable; i++) {
            float sample = sinf(phase);
            data[i * 2] = sample;     // Left
            data[i * 2 + 1] = sample; // Right

            phase += 2.0f * PI * FREQ / SAMPLE_RATE;
            if (phase > 2.0f * PI) phase -= 2.0f * PI;
        }

        renderClient->lpVtbl->ReleaseBuffer(renderClient, framesAvailable, 0);
    }

    // Cleanup (Omitted for brevity, but crucial in full apps)
    return 0;
}