clc;
clear;
close all;

% ==========================================
% STEP 1: LOAD AN AUDIO FILE
% ==========================================

% Select an audio file
[file, path] = uigetfile('*.wav', 'Select a WAV audio file');

% Check if the user selected a file
if isequal(file, 0)
    disp('No file selected.');
    return;
end

% Read the audio file
[x, Fs] = audioread(fullfile(path, file));

% Display information
fprintf('Audio file: %s\n', file);
fprintf('Sampling frequency: %d Hz\n', Fs);
fprintf('Number of samples: %d\n', length(x));
fprintf('Duration: %.2f seconds\n', length(x)/Fs);

% ==========================================
% CONVERT STEREO TO MONO
% ==========================================

if size(x,2) == 2
    x = mean(x,2);
end

% ==========================================
% CREATE TIME AXIS
% ==========================================

t = (0:length(x)-1) / Fs;

% ==========================================
% PLOT AUDIO SIGNAL
% ==========================================

figure;

plot(t, x);

xlabel('Time (seconds)');
ylabel('Amplitude');

title('Original Audio Signal');

grid on;

% ==========================================
% PLAY AUDIO
% ==========================================

disp('Playing audio...');

sound(x, Fs);