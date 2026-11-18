
clc;
clear;
close all;

%% LOAD TRAINED MODEL
load('trainedModel.mat');

%% SETTINGS
Fs = 16000;
chunkDuration = 2;
chunkSize = Fs * chunkDuration;

historySize = 5;
requiredVotes = 3;

% IMPORTANT: Change these names to match your actual classNames.
disp('Available sound classes:');
disp(classNames);

emergencyClasses = ["Siren", "Glass", "BabyCry"];

%% MICROPHONE
recObj = audiorecorder(Fs, 16, 1);

%% GUI WINDOW
fig = uifigure('Name', 'Emergency Sound Detection', ...
    'Position', [300 150 650 480]);

fig.Color = [0.95 0.97 0.99];

% Title
titleLabel = uilabel(fig, ...
    'Text', 'EMERGENCY SOUND DETECTION SYSTEM', ...
    'Position', [40 420 570 35], ...
    'FontSize', 21, ...
    'FontWeight', 'bold', ...
    'HorizontalAlignment', 'center');

% Status
statusLabel = uilabel(fig, ...
    'Text', 'Status: Ready', ...
    'Position', [40 375 570 28], ...
    'FontSize', 15, ...
    'HorizontalAlignment', 'center');

% Prediction heading
uilabel(fig, ...
    'Text', 'DETECTION RESULT', ...
    'Position', [40 315 570 30], ...
    'FontSize', 15, ...
    'FontWeight', 'bold', ...
    'HorizontalAlignment', 'center');

% Prediction display
resultLabel = uilabel(fig, ...
    'Text', 'Waiting for audio...', ...
    'Position', [40 265 570 45], ...
    'FontSize', 22, ...
    'FontWeight', 'bold', ...
    'HorizontalAlignment', 'center');

% Voting information
voteLabel = uilabel(fig, ...
    'Text', 'Emergency votes: 0/5', ...
    'Position', [40 225 570 25], ...
    'FontSize', 14, ...
    'HorizontalAlignment', 'center');

% Prediction history
historyLabel = uitextarea(fig, ...
    'Position', [90 105 470 100], ...
    'Editable', 'off', ...
    'Value', {'Prediction history will appear here.'});

% Start button
startButton = uibutton(fig, 'push', ...
    'Text', 'START DETECTION', ...
    'Position', [100 40 190 45], ...
    'FontSize', 15, ...
    'FontWeight', 'bold', ...
    'BackgroundColor', [0.15 0.65 0.35], ...
    'FontColor', [1 1 1], ...
    'ButtonPushedFcn', @startDetection);

% Stop button
stopButton = uibutton(fig, 'push', ...
    'Text', 'STOP DETECTION', ...
    'Position', [360 40 190 45], ...
    'FontSize', 15, ...
    'FontWeight', 'bold', ...
    'BackgroundColor', [0.8 0.2 0.2], ...
    'FontColor', [1 1 1], ...
    'Enable', 'off', ...
    'ButtonPushedFcn', @stopDetection);

%% TIMER
detectionTimer = timer( ...
    'ExecutionMode', 'fixedSpacing', ...
    'Period', 0.15, ...
    'BusyMode', 'drop', ...
    'TimerFcn', @processAudio);

%% VARIABLES
predictionHistory = strings(0,1);
nextSample = 1;
isRunning = false;

%% START DETECTION
function startDetection(~,~)

    if isRunning
        return;
    end

    try
        % Reset variables
        predictionHistory = strings(0,1);
        nextSample = 1;

        resultLabel.Text = 'Listening...';
        resultLabel.FontColor = [0.1 0.3 0.7];

        voteLabel.Text = 'Emergency votes: 0/5';
        historyLabel.Value = {'Listening for sounds...'};

        statusLabel.Text = 'Status: Microphone ON';

        % Start asynchronous recording
        record(recObj);

        isRunning = true;

        startButton.Enable = 'off';
        stopButton.Enable = 'on';

        start(detectionTimer);

    catch ME

        statusLabel.Text = ['Error: ' ME.message];
        stopDetection([],[]);

    end

end

%% STOP DETECTION
function stopDetection(~,~)

    if isvalid(detectionTimer) && strcmp(detectionTimer.Running,'on')
        stop(detectionTimer);
    end

    if isrecording(recObj)
        stop(recObj);
    end

    isRunning = false;

    if isvalid(fig)
        statusLabel.Text = 'Status: Stopped';
        startButton.Enable = 'on';
        stopButton.Enable = 'off';
    end

end

%% PROCESS AUDIO
function processAudio(~,~)

    if ~isRunning
        return;
    end

    try

        audioData = getaudiodata(recObj,'double');

        % Wait until a complete 2-second chunk is available
        if length(audioData) < nextSample + chunkSize - 1
            return;
        end

        % Extract next audio chunk
        x = audioData(nextSample:nextSample+chunkSize-1);

        nextSample = nextSample + chunkSize;

        % Check audio level
        if max(abs(x)) < 1e-6
            resultLabel.Text = 'No significant sound';
            return;
        end

        %% FEATURE EXTRACTION

        featureVector = extractLiveFeatures(x,Fs);

        %% NORMALIZATION

        featureVectorNorm = ...
            (featureVector - mu) ./ (sigma + eps);

        %% SVM PREDICTION

        predictedLabel = predict(SVMModel,featureVectorNorm);

        predictedClass = string(predictedLabel);

        %% UPDATE HISTORY

        predictionHistory(end+1,1) = predictedClass;

        if numel(predictionHistory) > historySize
            predictionHistory(1) = [];
        end

        emergencyVotes = sum( ...
            ismember(predictionHistory,emergencyClasses));

        %% DISPLAY PREDICTION

        resultLabel.Text = char(predictedClass);

        voteLabel.Text = sprintf( ...
            'Emergency votes: %d/%d', ...
            emergencyVotes,historySize);

        historyLabel.Value = cellstr( ...
            "Latest: " + predictionHistory);

        %% FINAL DECISION

        if emergencyVotes >= requiredVotes

            resultLabel.Text = ...
                ['EMERGENCY: ' char(predictedClass)];

            resultLabel.FontColor = [0.85 0.05 0.05];

        else

            resultLabel.Text = ...
                ['Detected: ' char(predictedClass)];

            resultLabel.FontColor = [0.1 0.4 0.7];

        end

        drawnow limitrate;

    catch ME

        statusLabel.Text = ['Detection error: ' ME.message];
        stopDetection([],[]);

    end

end

%% CLEANUP WHEN WINDOW CLOSES
fig.CloseRequestFcn = @closeGUI;

function closeGUI(~,~)

    stopDetection([],[]);

    if isvalid(detectionTimer)
        delete(detectionTimer);
    end

    delete(fig);

end


%% =========================================
% LIVE FEATURE EXTRACTION
% =========================================

function featureVector = extractLiveFeatures(x,Fs)

    x = x(:);

    % Remove DC component
    x = x - mean(x);

    % Normalize amplitude
    x = x/(max(abs(x))+eps);

    % Bandpass filter
    [b,a] = butter(4,[100 7500]/(Fs/2),'bandpass');

    x = filtfilt(b,a,x);

    % Frame settings
    frameLength = 400;
    hopLength = 200;
    NFFT = 1024;

    win = hamming(frameLength);

    numFrames = floor((length(x)-frameLength)/hopLength)+1;

    frameFeatures = zeros(numFrames,5);

    for k = 1:numFrames

        idx = (k-1)*hopLength+1;

        frame = x(idx:idx+frameLength-1);

        % 1. Energy
        energy = mean(frame.^2);

        % 2. Zero crossing rate
        zcr = sum(abs(diff(sign(frame))))/ ...
              (2*(length(frame)-1));

        % FFT
        Y = fft(frame.*win,NFFT);

        spectrum = abs(Y(1:NFFT/2+1));

        powerSpectrum = spectrum.^2;

        frequencies = (0:NFFT/2)'*Fs/NFFT;

        % 3. Spectral centroid
        centroid = sum(frequencies.*spectrum)/ ...
                   (sum(spectrum)+eps);

        % 4. Spectral bandwidth
        bandwidth = sqrt(sum( ...
            ((frequencies-centroid).^2).*spectrum)/ ...
            (sum(spectrum)+eps));

        % 5. Spectral rolloff
        cumulativePower = cumsum(powerSpectrum);

        rolloffIndex = find( ...
            cumulativePower >= 0.85*sum(powerSpectrum), ...
            1,'first');

        if isempty(rolloffIndex)
            rolloff = 0;
        else
            rolloff = frequencies(rolloffIndex);
        end

        frameFeatures(k,:) = ...
            [energy,zcr,centroid,bandwidth,rolloff];

    end

    % Mean and standard deviation
    featureMean = mean(frameFeatures,1);

    featureStd = std(frameFeatures,0,1);

    featureVector = [featureMean,featureStd];

end
