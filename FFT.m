clc;
clear;
close all;

%% ==========================================
% STEP 3: FFT ANALYSIS
% ===========================================

%% Target sampling frequency

targetFs = 16000;

%% ==========================================
% LOAD AUDIO
% ==========================================

[file, path] = uigetfile('*.wav', ...
    'Select the siren WAV file');

if isequal(file, 0)
    disp('No file selected.');
    return;
end

[x, Fs] = audioread(fullfile(path, file));

%% ==========================================
% CONVERT TO MONO
% ==========================================

if size(x,2) == 2
    x = mean(x,2);
end

%% ==========================================
% RESAMPLE
% ==========================================

if Fs ~= targetFs

    x = resample(x,targetFs,Fs);

    Fs = targetFs;

end

%% ==========================================
% NORMALIZE
% ==========================================

x = x/(max(abs(x)) + eps);

%% ==========================================
% BAND-PASS FILTER
% ==========================================

lowCut = 100;
highCut = 7500;

[b,a] = butter(4, ...
    [lowCut highCut]/(Fs/2), ...
    'bandpass');

x_filtered = filtfilt(b,a,x);

%% ==========================================
% FFT
% ==========================================

N = length(x_filtered);

X = fft(x_filtered);

%% ==========================================
% MAGNITUDE SPECTRUM
% ==========================================

P2 = abs(X/N);

%% Keep only positive frequencies

P1 = P2(1:floor(N/2)+1);

%% Double amplitude except DC and Nyquist

P1(2:end-1) = 2*P1(2:end-1);

%% ==========================================
% FREQUENCY AXIS
% ==========================================

f = Fs*(0:floor(N/2))/N;

%% ==========================================
% PLOT FFT
% ==========================================

figure;

plot(f,P1);

xlabel('Frequency (Hz)');
ylabel('Magnitude');

title('Frequency Spectrum of Siren');

xlim([0 8000]);

grid on;

%% ==========================================
% FIND DOMINANT FREQUENCY
% ==========================================

[peakMagnitude,peakIndex] = max(P1);

dominantFrequency = f(peakIndex);

fprintf('\n');
fprintf('====================================\n');
fprintf('FFT ANALYSIS RESULTS\n');
fprintf('====================================\n');

fprintf('Sampling frequency: %d Hz\n',Fs);

fprintf('Number of samples: %d\n',N);

fprintf('Dominant frequency: %.2f Hz\n', ...
    dominantFrequency);

fprintf('Peak magnitude: %.4f\n', ...
    peakMagnitude);

fprintf('====================================\n');