clc;
clear;
close all;

%% ==========================================
% STEP 2: AUDIO PREPROCESSING
% ===========================================

% Target sampling frequency
targetFs = 16000;

%% ==========================================
% LOAD AUDIO
% ===========================================

[file, path] = uigetfile('*.wav', ...
    'Select the siren WAV file');

if isequal(file, 0)
    disp('No file selected.');
    return;
end

[x, Fs] = audioread(fullfile(path, file));

fprintf('Original sampling frequency: %d Hz\n', Fs);
fprintf('Original number of samples: %d\n', length(x));
fprintf('Original duration: %.2f seconds\n', length(x)/Fs);

%% ==========================================
% STEP 1: CONVERT STEREO TO MONO
% ==========================================

if size(x,2) == 2
    x = mean(x,2);
    disp('Stereo audio converted to mono.');
else
    disp('Audio is already mono.');
end

%% ==========================================
% STEP 2: RESAMPLE TO 16 kHz
% ==========================================

if Fs ~= targetFs

    x = resample(x, targetFs, Fs);

    Fs = targetFs;

    fprintf('Audio resampled to %d Hz.\n', Fs);

else

    disp('Audio is already 16 kHz.');

end

%% ==========================================
% STEP 3: NORMALIZATION
% ==========================================

x_normalized = x / (max(abs(x)) + eps);

fprintf('Maximum amplitude after normalization: %.3f\n', ...
    max(abs(x_normalized)));

%% ==========================================
% STEP 4: DESIGN BAND-PASS FILTER
% ==========================================

lowCut = 100;
highCut = 7500;

filterOrder = 4;

[b, a] = butter( ...
    filterOrder, ...
    [lowCut highCut]/(Fs/2), ...
    'bandpass');

%% ==========================================
% STEP 5: APPLY FILTER
% ==========================================

x_filtered = filtfilt(b, a, x_normalized);

disp('Band-pass filtering completed.');

%% ==========================================
% TIME AXIS
% ==========================================

t = (0:length(x_filtered)-1)/Fs;

%% ==========================================
% PLOT 1: ORIGINAL SIGNAL
% ==========================================

figure;

plot((0:length(x)-1)/Fs, x);

xlabel('Time (seconds)');
ylabel('Amplitude');

title('Original Audio Signal');

grid on;

%% ==========================================
% PLOT 2: NORMALIZED SIGNAL
% ==========================================

figure;

plot((0:length(x_normalized)-1)/Fs, x_normalized);

xlabel('Time (seconds)');
ylabel('Amplitude');

title('Normalized Audio Signal');

grid on;

%% ==========================================
% PLOT 3: FILTERED SIGNAL
% ==========================================

figure;

plot(t, x_filtered);

xlabel('Time (seconds)');
ylabel('Amplitude');

title('Band-pass Filtered Siren');

grid on;

%% ==========================================
% FILTER FREQUENCY RESPONSE
% ==========================================

figure;

freqz(b, a, 2048, Fs);

title('Band-pass Filter Frequency Response');

%% ==========================================
% PLAY FILTERED AUDIO
% ==========================================

disp('Playing processed siren...');

sound(x_filtered, Fs);