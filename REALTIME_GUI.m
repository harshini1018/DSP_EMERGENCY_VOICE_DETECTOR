
function REALTIME_GUI

clc;
close all;

%% ==========================================
% 1. LOAD TRAINED MODEL
% ==========================================

if ~isfile('trainedModel.mat')
    error('Run SVM.m first. trainedModel.mat not found.');
end

data = load('trainedModel.mat');

SVMModel = data.SVMModel;
mu = data.mu;
sigma = data.sigma;

sigma(sigma == 0) = 1;

fprintf('Trained SVM loaded successfully.\n');

%% ==========================================
% 2. SETTINGS
% ==========================================

Fs = 16000;
bits = 16;
channels = 1;

chunkDuration = 2;

numberOfVotes = 5;
minimumEmergencyVotes = 3;

emergencyClasses = ["Siren","Glass"];

predictionHistory = strings(numberOfVotes,1);

historyCount = 0;
historyIndex = 1;

recorder = [];
pollTimer = [];

isRunning = false;
chunkClock = [];

%% ==========================================
% 3. CREATE GUI
% ==========================================

fig = figure( ...
    'Name','DSP Emergency Sound Detector', ...
    'NumberTitle','off', ...
    'Color',[0.94 0.96 0.98], ...
    'Position',[200 100 1000 700], ...
    'MenuBar','none', ...
    'Resize','off', ...
    'CloseRequestFcn',@closeGUI);

%% TITLE

uicontrol(fig, ...
    'Style','text', ...
    'String','DSP-BASED EMERGENCY SOUND DETECTOR', ...
    'FontSize',21, ...
    'FontWeight','bold', ...
    'ForegroundColor',[0.1 0.2 0.4], ...
    'BackgroundColor',[0.94 0.96 0.98], ...
    'Position',[100 630 800 45]);

uicontrol(fig, ...
    'Style','text', ...
    'String','REAL-TIME AUDIO CLASSIFICATION USING SVM', ...
    'FontSize',12, ...
    'BackgroundColor',[0.94 0.96 0.98], ...
    'Position',[200 600 600 25]);

%% STATUS

statusText = uicontrol(fig, ...
    'Style','text', ...
    'String','SYSTEM READY', ...
    'FontSize',22, ...
    'FontWeight','bold', ...
    'ForegroundColor',[0 0.35 0.7], ...
    'BackgroundColor','w', ...
    'Position',[150 510 700 65]);

%% PREDICTED CLASS

classText = uicontrol(fig, ...
    'Style','text', ...
    'String','Predicted Sound: Waiting...', ...
    'FontSize',17, ...
    'FontWeight','bold', ...
    'BackgroundColor',[0.94 0.96 0.98], ...
    'Position',[200 465 600 35]);

%% EMERGENCY VOTES

voteText = uicontrol(fig, ...
    'Style','text', ...
    'String','Emergency Votes: 0/0', ...
    'FontSize',15, ...
    'BackgroundColor',[0.94 0.96 0.98], ...
    'Position',[200 430 600 30]);

%% WAVEFORM

ax = axes('Parent',fig, ...
    'Position',[0.12 0.42 0.78 0.22]);

title(ax,'Live Microphone Signal');
xlabel(ax,'Time (seconds)');
ylabel(ax,'Amplitude');
grid(ax,'on');
ylim(ax,[-1 1]);

%% START BUTTON

startButton = uicontrol(fig, ...
    'Style','pushbutton', ...
    'String','START DETECTION', ...
    'FontSize',15, ...
    'FontWeight','bold', ...
    'ForegroundColor','w', ...
    'BackgroundColor',[0.1 0.55 0.25], ...
    'Position',[220 340 220 60], ...
    'Callback',@startDetection);

%% STOP BUTTON

stopButton = uicontrol(fig, ...
    'Style','pushbutton', ...
    'String','STOP DETECTION', ...
    'FontSize',15, ...
    'FontWeight','bold', ...
    'ForegroundColor','w', ...
    'BackgroundColor',[0.8 0.15 0.15], ...
    'Position',[550 340 220 60], ...
    'Enable','off', ...
    'Callback',@stopDetection);

%% HISTORY TITLE

uicontrol(fig, ...
    'Style','text', ...
    'String','RECENT SOUND PREDICTIONS', ...
    'FontSize',14, ...
    'FontWeight','bold', ...
    'BackgroundColor',[0.94 0.96 0.98], ...
    'Position',[200 285 600 30]);

%% HISTORY BOX

historyBox = uicontrol(fig, ...
    'Style','listbox', ...
    'String',{'No predictions yet'}, ...
    'FontSize',12, ...
    'Position',[250 125 500 155]);

%% FOOTER

uicontrol(fig, ...
    'Style','text', ...
    'String','Emergency: Siren | Glass', ...
    'FontSize',12, ...
    'BackgroundColor',[0.94 0.96 0.98], ...
    'Position',[200 70 600 30]);

uicontrol(fig, ...
    'Style','text', ...
    'String','Normal: Speech | Noise', ...
    'FontSize',12, ...
    'BackgroundColor',[0.94 0.96 0.98], ...
    'Position',[200 40 600 25]);

%% ==========================================
% 4. START DETECTION
% ==========================================

function startDetection(~,~)

    if isRunning
        return;
    end

    try

        recorder = audiorecorder(Fs,bits,channels);

        isRunning = true;

        predictionHistory(:) = "";
        historyCount = 0;
        historyIndex = 1;

        set(statusText,'String','LISTENING...', ...
            'ForegroundColor',[0 0.35 0.7]);

        set(classText,'String','Predicted Sound: Waiting...');
        set(voteText,'String','Emergency Votes: 0/0');
        set(historyBox,'String',{'No predictions yet'});

        set(startButton,'Enable','off');
        set(stopButton,'Enable','on');

        startNewChunk();

        pollTimer = timer( ...
            'ExecutionMode','fixedSpacing', ...
            'Period',0.1, ...
            'BusyMode','drop', ...
            'TimerFcn',@checkRecording);

        start(pollTimer);

        fprintf('\nLive detection started.\n');

    catch ME

        stopDetection([],[]);
        errordlg(ME.message,'Microphone Error');

    end

end

%% ==========================================
% 5. START A FRESH RECORDING CHUNK
% ==========================================

function startNewChunk()

    if ~isRunning
        return;
    end

    recorder = audiorecorder(Fs,bits,channels);

    record(recorder);

    chunkClock = tic;

end

%% ==========================================
% 6. CHECK RECORDING AND PROCESS CHUNK
% ==========================================

function checkRecording(~,~)

    if ~isRunning || ~ishandle(fig)
        return;
    end

    if toc(chunkClock) < chunkDuration
        return;
    end

    try

        %% STOP CURRENT RECORDING

        stop(recorder);

        audio = getaudiodata(recorder,'double');

        if isempty(audio)
            startNewChunk();
            return;
        end

        %% MICROPHONE LEVEL CHECK

        rmsValue = sqrt(mean(audio.^2));

        fprintf('\nMicrophone RMS: %.6f\n',rmsValue);

        if rmsValue < 0.0001

            set(statusText,'String','LOW MICROPHONE SIGNAL', ...
                'ForegroundColor',[0.8 0.3 0]);

            set(classText,'String','Check microphone input.');

            startNewChunk();
            return;

        end

        %% WAVEFORM DISPLAY

        timeAxis = (0:length(audio)-1)/Fs;

        plot(ax,timeAxis,audio);

        title(ax,'Live Microphone Signal');
        xlabel(ax,'Time (seconds)');
        ylabel(ax,'Amplitude');

        grid(ax,'on');
        ylim(ax,[-1 1]);

        drawnow limitrate;

        %% CLASSIFY AUDIO

        predictedClass = classifySound( ...
            audio,Fs,SVMModel,mu,sigma);

        fprintf('Predicted sound: %s\n',predictedClass);

        %% UPDATE HISTORY

        predictionHistory(historyIndex) = predictedClass;

        historyIndex = historyIndex+1;

        if historyIndex > numberOfVotes
            historyIndex = 1;
        end

        historyCount = min(historyCount+1,numberOfVotes);

        recentPredictions = predictionHistory(1:historyCount);

        %% EMERGENCY VOTING

        emergencyVotes = sum( ...
            ismember(lower(recentPredictions), ...
            lower(emergencyClasses)));

        set(voteText,'String', ...
            sprintf('Emergency Votes: %d/%d', ...
            emergencyVotes,historyCount));

        %% DISPLAY STATUS

        if emergencyVotes >= minimumEmergencyVotes

            set(statusText, ...
                'String','EMERGENCY DETECTED!', ...
                'ForegroundColor',[0.85 0 0]);

        else

            set(statusText, ...
                'String','NORMAL / NO CONFIRMED EMERGENCY', ...
                'ForegroundColor',[0 0.5 0]);

        end

        set(classText,'String', ...
            ['Predicted Sound: ' char(predictedClass)]);

        %% UPDATE HISTORY BOX

        entries = cell(historyCount,1);

        for j = 1:historyCount
            entries{j} = char(recentPredictions(j));
        end

        set(historyBox,'String',entries);

        %% START NEXT CHUNK

        startNewChunk();

    catch ME

        fprintf('Detection error: %s\n',ME.message);

        stopDetection([],[]);

        errordlg(ME.message,'Detection Error');

    end

end

%% ==========================================
% 7. STOP DETECTION
% ==========================================

function stopDetection(~,~)

    isRunning = false;

    if ~isempty(pollTimer) && isvalid(pollTimer)

        stop(pollTimer);
        delete(pollTimer);

        pollTimer = [];

    end

    if ~isempty(recorder)

        try
            stop(recorder);
        catch
        end

        recorder = [];

    end

    if ishandle(statusText)

        set(statusText,'String','DETECTION STOPPED', ...
            'ForegroundColor',[0.4 0.4 0.4]);

        set(startButton,'Enable','on');
        set(stopButton,'Enable','off');

    end

    fprintf('\nDetection stopped.\n');

end

%% ==========================================
% 8. CLOSE GUI
% ==========================================

function closeGUI(~,~)

    stopDetection([],[]);

    if ishandle(fig)
        delete(fig);
    end

end

end

%% =========================================================
% 9. AUDIO PREPROCESSING AND FEATURE EXTRACTION
%    MATCHES BUILD_DATASET.m
%% =========================================================

function predictedClass = classifySound(audio,Fs, ...
    SVMModel,mu,sigma)

    %% LOAD AUDIO

    x = audio;

    %% CONVERT TO MONO

    if size(x,2) > 1
        x = mean(x,2);
    end

    x = x(:);

    %% REMOVE DC OFFSET

    x = x - mean(x);

    %% RESAMPLE TO 16 kHz

    targetFs = 16000;

    if Fs ~= targetFs
        x = resample(x,targetFs,Fs);
        Fs = targetFs;
    end

    %% NORMALIZATION

    maxValue = max(abs(x));

    if maxValue > 0
        x = x/maxValue;
    end

    %% BUTTERWORTH BAND-PASS FILTER

    lowCut = 100;
    highCut = 7500;

    [b,a] = butter(4, ...
        [lowCut highCut]/(Fs/2), ...
        'bandpass');

    x = filtfilt(b,a,x);

    %% FRAME PARAMETERS

    frameLength = round(0.025*Fs);
    hopLength = round(0.0125*Fs);

    if length(x) < frameLength
        error('Audio chunk too short.');
    end

    numFrames = floor( ...
        (length(x)-frameLength)/hopLength)+1;

    %% FEATURE ARRAYS

    energy = zeros(numFrames,1);
    zcr = zeros(numFrames,1);
    centroid = zeros(numFrames,1);
    bandwidth = zeros(numFrames,1);
    rolloff = zeros(numFrames,1);

    %% FFT SETTINGS

    NFFT = 1024;

    window = hamming(frameLength);

    frequencies = ...
        (0:NFFT/2)'*Fs/NFFT;

    %% FRAME-BY-FRAME FEATURE EXTRACTION

    for i = 1:numFrames

        startIndex = (i-1)*hopLength+1;
        endIndex = startIndex+frameLength-1;

        frame = x(startIndex:endIndex);

        %% HAMMING WINDOW

        windowedFrame = frame.*window;

        %% FEATURE 1: ENERGY

        energy(i) = mean(frame.^2);

        %% FEATURE 2: ZERO CROSSING RATE

        zcr(i) = sum(abs(diff(sign(frame)))) ...
            /(2*length(frame));

        %% FFT

        spectrum = abs(fft(windowedFrame,NFFT));

        spectrum = spectrum(1:NFFT/2+1);

        spectrumSum = sum(spectrum)+eps;

        %% FEATURE 3: SPECTRAL CENTROID

        centroid(i) = ...
            sum(frequencies.*spectrum)/spectrumSum;

        %% FEATURE 4: SPECTRAL BANDWIDTH

        bandwidth(i) = sqrt( ...
            sum(((frequencies-centroid(i)).^2).*spectrum) ...
            /spectrumSum);

        %% FEATURE 5: SPECTRAL ROLLOFF

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

    %% RECORDING-LEVEL FEATURES

    featureVector = [ ...
        mean(energy), ...
        std(energy), ...
        mean(zcr), ...
        std(zcr), ...
        mean(centroid), ...
        std(centroid), ...
        mean(bandwidth), ...
        std(bandwidth), ...
        mean(rolloff), ...
        std(rolloff)];

    %% NORMALIZATION USING TRAINING PARAMETERS

    featureVector = (featureVector-mu)./sigma;

    %% DEBUG: DISPLAY FEATURE VECTOR

    fprintf('\nExtracted feature vector:\n');
    disp(featureVector);

    %% SVM PREDICTION

    predictedClass = predict(SVMModel,featureVector);

    predictedClass = string(predictedClass);

end