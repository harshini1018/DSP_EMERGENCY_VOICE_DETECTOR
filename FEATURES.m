clc;
clear;
close all;

%% ==========================================
% STEP 5: FEATURE EXTRACTION
% ==========================================

targetFs = 16000;

%% ==========================================
% LOAD AUDIO
% ==========================================

[file,path] = uigetfile('*.wav', ...
    'Select siren WAV file');

if isequal(file,0)
    disp('No file selected.');
    return;
end

[x,Fs] = audioread(fullfile(path,file));

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
% NORMALIZATION
% ==========================================

x = x/(max(abs(x))+eps);

%% ==========================================
% BAND-PASS FILTER
% ==========================================

[b,a] = butter(4,[100 7500]/(Fs/2),'bandpass');

x = filtfilt(b,a,x);

%% ==========================================
% FRAME PARAMETERS
% ==========================================

frameDuration = 0.025;      % 25 ms
frameLength = round(frameDuration*Fs);

overlap = 0.5;

hopLength = round(frameLength*(1-overlap));

%% Number of frames

numFrames = floor((length(x)-frameLength)/hopLength)+1;

fprintf('Sampling frequency: %d Hz\n',Fs);
fprintf('Frame length: %d samples\n',frameLength);
fprintf('Number of frames: %d\n',numFrames);

%% ==========================================
% PREALLOCATE FEATURES
% ==========================================

energy = zeros(numFrames,1);
zcr = zeros(numFrames,1);
centroid = zeros(numFrames,1);
bandwidth = zeros(numFrames,1);
rolloff = zeros(numFrames,1);

%% ==========================================
% FRAME-BY-FRAME PROCESSING
% ==========================================

for i = 1:numFrames

    %% Frame starting position

    startIndex = (i-1)*hopLength + 1;

    endIndex = startIndex + frameLength - 1;

    %% Extract frame

    frame = x(startIndex:endIndex);

    %% ======================================
    % HAMMING WINDOW
    % =======================================

    window = hamming(frameLength);

    windowedFrame = frame .* window;

    %% ======================================
    % FEATURE 1: ENERGY
    % =======================================

    energy(i) = mean(frame.^2);

    %% ======================================
    % FEATURE 2: ZERO CROSSING RATE
    % =======================================

    zcr(i) = ...
        sum(abs(diff(sign(frame)))) ...
        /(2*length(frame));

    %% ======================================
    % FFT
    % ======================================

    NFFT = 1024;

    spectrum = abs(fft(windowedFrame,NFFT));

    %% Keep positive frequencies

    spectrum = spectrum(1:NFFT/2+1);

    %% Frequency axis

    frequencies = ...
        (0:NFFT/2)'*Fs/NFFT;

    %% ======================================
    % FEATURE 3: SPECTRAL CENTROID
    % ======================================

    spectrumSum = sum(spectrum)+eps;

    centroid(i) = ...
        sum(frequencies.*spectrum) ...
        /spectrumSum;

    %% ======================================
    % FEATURE 4: SPECTRAL BANDWIDTH
    % ======================================

    bandwidth(i) = sqrt( ...
        sum(((frequencies-centroid(i)).^2).*spectrum) ...
        /spectrumSum);

    %% ======================================
    % FEATURE 5: SPECTRAL ROLLOFF
    % ======================================

    cumulativeSpectrum = cumsum(spectrum);

    threshold = 0.85*cumulativeSpectrum(end);

    rolloffIndex = ...
        find(cumulativeSpectrum >= threshold,1);

    if isempty(rolloffIndex)
        rolloff(i) = 0;
    else
        rolloff(i) = frequencies(rolloffIndex);
    end

end

%% ==========================================
% DISPLAY RESULTS
% ==========================================

fprintf('\n');
fprintf('====================================\n');
fprintf('FEATURE EXTRACTION RESULTS\n');
fprintf('====================================\n');

fprintf('Average Energy       : %.6f\n',mean(energy));
fprintf('Average ZCR          : %.6f\n',mean(zcr));
fprintf('Average Centroid     : %.2f Hz\n',mean(centroid));
fprintf('Average Bandwidth    : %.2f Hz\n',mean(bandwidth));
fprintf('Average Rolloff      : %.2f Hz\n',mean(rolloff));

fprintf('====================================\n');

%% ==========================================
% PLOT FEATURES
% ==========================================

frameTime = ((0:numFrames-1)*hopLength + frameLength/2)/Fs;

%% Energy

figure;

plot(frameTime,energy);

xlabel('Time (seconds)');
ylabel('Energy');

title('Short-Time Energy');

grid on;

%% ZCR

figure;

plot(frameTime,zcr);

xlabel('Time (seconds)');
ylabel('ZCR');

title('Zero Crossing Rate');

grid on;

%% Spectral Centroid

figure;

plot(frameTime,centroid);

xlabel('Time (seconds)');
ylabel('Frequency (Hz)');

title('Spectral Centroid');

grid on;

%% Spectral Bandwidth

figure;

plot(frameTime,bandwidth);

xlabel('Time (seconds)');
ylabel('Bandwidth (Hz)');

title('Spectral Bandwidth');

grid on;

%% Spectral Rolloff

figure;

plot(frameTime,rolloff);

xlabel('Time (seconds)');
ylabel('Frequency (Hz)');

title('Spectral Rolloff');

grid on;