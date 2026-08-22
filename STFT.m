clc;
clear;
close all;

%% ==========================================
% STEP 4 : STFT & SPECTROGRAM
% ==========================================

targetFs = 16000;

%% Load Audio
[file,path] = uigetfile('*.wav','Select siren WAV file');

if isequal(file,0)
    return;
end

[x,Fs] = audioread(fullfile(path,file));

%% Convert to mono
if size(x,2)==2
    x = mean(x,2);
end

%% Resample
if Fs ~= targetFs
    x = resample(x,targetFs,Fs);
    Fs = targetFs;
end

%% Normalize
x = x/(max(abs(x))+eps);

%% Band-pass filter
[b,a] = butter(4,[100 7500]/(Fs/2),'bandpass');
x = filtfilt(b,a,x);

%% ==========================================
% STFT PARAMETERS
% ==========================================

windowLength = round(0.025*Fs);      % 25 ms
overlap = round(0.5*windowLength);   % 50% overlap
nfft = 1024;

%% Spectrogram
figure;

spectrogram(x,...
            hamming(windowLength),...
            overlap,...
            nfft,...
            Fs,...
            'yaxis');

ylim([0 8]);

title('Siren Spectrogram');

xlabel('Time (Seconds)');
ylabel('Frequency (kHz)');

colorbar;