
clc;
clear;
close all;

%% =========================================================
%       DSP-BASED EMERGENCY SOUND DETECTOR
%                  LIVE MICROPHONE
% ==========================================================

%% 1. LOAD TRAINED SVM MODEL

modelFile = 'trainedModel.mat';

if ~isfile(modelFile)
    error(['trainedModel.mat not found. Run SVM.m first ' ...
           'to train and save the classifier.']);
end

loadedData = load(modelFile);

requiredVariables = {'SVMModel','mu','sigma'};

for k = 1:length(requiredVariables)
    if ~isfield(loadedData, requiredVariables{k})
        error('Missing variable %s in trainedModel.mat.', ...
              requiredVariables{k});
    end
end

SVMModel = loadedData.SVMModel;
mu = loadedData.mu;
sigma = loadedData.sigma;

sigma(sigma == 0) = 1;

fprintf('\n============================================\n');
fprintf('       DSP EMERGENCY SOUND DETECTOR\n');
fprintf('============================================\n');
fprintf('Trained model loaded successfully.\n');

%% 2. MICROPHONE SETTINGS

Fs = 16000;              % Sampling frequency
bits = 16;               % Recording resolution
channels = 1;            % Mono recording

chunkDuration = 2;       % Record 2 seconds each time
numberOfVotes = 5;       % Majority voting over 5 chunks
minimumEmergencyVotes = 3;

% Emergency classes
emergencyClasses = ["Siren","Glass","BabyCry"];

% Store recent predictions
predictionHistory = strings(numberOfVotes,1);
historyCount = 0;
historyIndex = 1;

%% 3. CREATE DISPLAY FIGURE

fig = figure( ...
    'Name','Live Emergency Sound Detector', ...
    'NumberTitle','off', ...
    'Color','w', ...
    'Position',[300 200 800 450]);

statusText = uicontrol(fig, ...
    'Style','text', ...
    'String','MICROPHONE READY', ...
    'FontSize',18, ...
    'FontWeight','bold', ...
    'ForegroundColor',[0 0.3 0.7], ...
    'BackgroundColor','w', ...
    'Position',[100 350 600 45]);

classText = uicontrol(fig, ...
    'Style','text', ...
    'String','Waiting for sound...', ...
    'FontSize',15, ...
    'BackgroundColor','w', ...
    'Position',[100 290 600 40]);

ax = axes('Parent',fig, ...
    'Position',[0.12 0.12 0.78 0.40]);

title(ax,'Live Microphone Signal');
xlabel(ax,'Time (seconds)');
ylabel(ax,'Amplitude');
grid(ax,'on');

%% 4. START LIVE DETECTION

disp(' ');
disp('Microphone detection started.');
disp('Close the display window or press Ctrl+C to stop.');
disp(' ');

try

    while ishandle(fig)

        %% RECORD AUDIO

        recorder = audiorecorder(Fs,bits,channels);

        fprintf('\nListening for %.1f seconds...\n', ...
                chunkDuration);

        recordblocking(recorder,chunkDuration);

        audio = getaudiodata(recorder,'double');

        if isempty(audio)
            continue;
        end

        %% DISPLAY WAVEFORM

        timeAxis = (0:length(audio)-1)/Fs;

        if ishandle(ax)
            plot(ax,timeAxis,audio);
            title(ax,'Recorded Microphone Signal');
            xlabel(ax,'Time (seconds)');
            ylabel(ax,'Amplitude');
            grid(ax,'on');
            drawnow limitrate;
        end

        %% PROCESS AND CLASSIFY

        predictedClass = classifySound( ...
            audio,Fs,SVMModel,mu,sigma);

        fprintf('Predicted sound: %s\n', ...
                char(predictedClass));

        %% UPDATE PREDICTION HISTORY

        predictionHistory(historyIndex) = predictedClass;

        historyIndex = historyIndex + 1;

        if historyIndex > numberOfVotes
            historyIndex = 1;
        end

        historyCount = min(historyCount+1,numberOfVotes);

        %% MAJORITY VOTING

        recentPredictions = predictionHistory(1:historyCount);

        emergencyVotes = sum( ...
            ismember(lower(recentPredictions), ...
                     lower(emergencyClasses)));

        fprintf('Emergency votes: %d/%d\n', ...
                emergencyVotes,historyCount);

        %% EMERGENCY / NORMAL DECISION

        if emergencyVotes >= minimumEmergencyVotes

            statusMessage = 'EMERGENCY SOUND DETECTED!';
            classMessage = ['Detected: ' char(predictedClass)];

            set(statusText, ...
                'String',statusMessage, ...
                'ForegroundColor',[0.85 0 0]);

            set(classText, ...
                'String',classMessage);

            fprintf('\n*** EMERGENCY SOUND DETECTED! ***\n');

        else

            set(statusText, ...
                'String','NORMAL / NO CONFIRMED EMERGENCY', ...
                'ForegroundColor',[0 0.5 0]);

            set(classText, ...
                'String',['Latest sound: ' char(predictedClass)]);

            fprintf('Status: No confirmed emergency.\n');

        end

        drawnow;

    end

catch ME

    fprintf('\nDetection stopped or an error occurred:\n');
    fprintf('%s\n',ME.message);

end

disp('Live microphone detection stopped.');

%% =========================================================
%              LOCAL FUNCTION 1
%              AUDIO CLASSIFICATION
% ==========================================================

function predictedClass = classifySound(audio,Fs, ...
                                        SVMModel,mu,sigma)

    %% PREPROCESSING

    x = audio(:);

    % Convert to mono if necessary
    if size(x,2) > 1
        x = mean(x,2);
    end

    % Resample to 16 kHz
    targetFs = 16000;

    if Fs ~= targetFs
        x = resample(x,targetFs,Fs);
        Fs = targetFs;
    end

    % Remove DC offset
    x = x - mean(x);

    % Normalize
    x = x/(max(abs(x))+eps);

    % Butterworth band-pass filter
    [b,a] = butter(4,[100 7500]/(Fs/2),'bandpass');

    x = filtfilt(b,a,x);

    %% FRAMING

    frameDuration = 0.025;
    frameLength = round(frameDuration*Fs);

    hopLength = round(frameLength*0.5);

    if length(x) < frameLength
        error('Audio chunk is too short for framing.');
    end

    numFrames = floor((length(x)-frameLength)/hopLength)+1;

    %% FEATURE ARRAYS

    energy = zeros(numFrames,1);
    zcr = zeros(numFrames,1);
    centroid = zeros(numFrames,1);
    bandwidth = zeros(numFrames,1);
    rolloff = zeros(numFrames,1);

    window = hamming(frameLength);
    NFFT = 1024;

    frequencies = (0:NFFT/2)'*Fs/NFFT;

    %% FRAME-BY-FRAME FEATURE EXTRACTION

    for i = 1:numFrames

        startIndex = (i-1)*hopLength+1;
        endIndex = startIndex+frameLength-1;

        frame = x(startIndex:endIndex);

        % Hamming window
        windowedFrame = frame.*window;

        % Feature 1: Short-time energy
        energy(i) = mean(frame.^2);

        % Feature 2: Zero crossing rate
        zcr(i) = sum(abs(diff(sign(frame)))) ...
                 /(2*length(frame));

        % FFT magnitude
        spectrum = abs(fft(windowedFrame,NFFT));

        % Positive frequency spectrum
        spectrum = spectrum(1:NFFT/2+1);

        spectrumSum = sum(spectrum)+eps;

        % Feature 3: Spectral centroid
        centroid(i) = sum(frequencies.*spectrum) ...
                      /spectrumSum;

        % Feature 4: Spectral bandwidth
        bandwidth(i) = sqrt( ...
            sum(((frequencies-centroid(i)).^2).*spectrum) ...
            /spectrumSum);

        % Feature 5: Spectral rolloff (85%)
        cumulativeSpectrum = cumsum(spectrum);

        threshold = 0.85*cumulativeSpectrum(end);

        rolloffIndex = find( ...
            cumulativeSpectrum >= threshold,1);

        if isempty(rolloffIndex)
            rolloff(i) = 0;
        else
            rolloff(i) = frequencies(rolloffIndex);
        end

    end

    %% RECORDING-LEVEL FEATURE VECTOR

    % IMPORTANT:
    % Feature ordering must match BUILD_DATASET.m.

    featureVector = [ ...
        mean(energy),std(energy), ...
        mean(zcr),std(zcr), ...
        mean(centroid),std(centroid), ...
        mean(bandwidth),std(bandwidth), ...
        mean(rolloff),std(rolloff)];

    %% FEATURE NORMALIZATION

    featureVector = (featureVector-mu)./sigma;

    %% SVM PREDICTION

    predictedClass = predict(SVMModel,featureVector);

    predictedClass = string(predictedClass);

end
