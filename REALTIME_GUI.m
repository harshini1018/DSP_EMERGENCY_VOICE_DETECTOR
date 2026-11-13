
function REALTIME_GUI

clc;

%% ==========================================
% LOAD TRAINED MODEL
%% ==========================================

modelFile = 'trainedModel.mat';

if ~isfile(modelFile)
    error('trainedModel.mat not found. Run SVM.m first.');
end

data = load(modelFile);

SVMModel = data.SVMModel;
mu = data.mu;
sigma = data.sigma;

sigma(sigma == 0) = 1;

%% ==========================================
% SETTINGS
%% ==========================================

Fs = 16000;
bits = 16;
channels = 1;

chunkDuration = 2;
numberOfVotes = 5;
minimumEmergencyVotes = 3;

emergencyClasses = ["Siren","Glass","BabyCry"];

predictionHistory = strings(numberOfVotes,1);
historyCount = 0;
historyIndex = 1;

recorder = [];
isRunning = false;
isBusy = false;

%% ==========================================
% CREATE GUI
%% ==========================================

fig = figure( ...
    'Name','DSP Emergency Sound Detector', ...
    'NumberTitle','off', ...
    'Color',[0.94 0.96 0.98], ...
    'Position',[250 120 950 650], ...
    'MenuBar','none', ...
    'CloseRequestFcn',@closeGUI);

% Main heading
uicontrol(fig, ...
    'Style','text', ...
    'String','DSP-BASED EMERGENCY SOUND DETECTOR', ...
    'FontSize',20, ...
    'FontWeight','bold', ...
    'ForegroundColor',[0.1 0.2 0.4], ...
    'BackgroundColor',[0.94 0.96 0.98], ...
    'Position',[100 580 750 40]);

% Status
statusText = uicontrol(fig, ...
    'Style','text', ...
    'String','SYSTEM READY', ...
    'FontSize',20, ...
    'FontWeight','bold', ...
    'ForegroundColor',[0 0.3 0.7], ...
    'BackgroundColor','w', ...
    'Position',[180 490 590 65]);

% Predicted class
classText = uicontrol(fig, ...
    'Style','text', ...
    'String','Predicted Sound: Waiting...', ...
    'FontSize',16, ...
    'BackgroundColor',[0.94 0.96 0.98], ...
    'Position',[200 440 550 35]);

% Emergency votes
voteText = uicontrol(fig, ...
    'Style','text', ...
    'String','Emergency Votes: 0/0', ...
    'FontSize',14, ...
    'BackgroundColor',[0.94 0.96 0.98], ...
    'Position',[200 405 550 30]);

% Axes
ax = axes('Parent',fig, ...
    'Position',[0.12 0.40 0.78 0.25]);

title(ax,'Live Microphone Waveform');
xlabel(ax,'Time (seconds)');
ylabel(ax,'Amplitude');
grid(ax,'on');

% Start button
startButton = uicontrol(fig, ...
    'Style','pushbutton', ...
    'String','START DETECTION', ...
    'FontSize',15, ...
    'FontWeight','bold', ...
    'ForegroundColor','w', ...
    'BackgroundColor',[0.1 0.55 0.25], ...
    'Position',[220 320 220 55], ...
    'Callback',@startDetection);

% Stop button
stopButton = uicontrol(fig, ...
    'Style','pushbutton', ...
    'String','STOP DETECTION', ...
    'FontSize',15, ...
    'FontWeight','bold', ...
    'ForegroundColor','w', ...
    'BackgroundColor',[0.8 0.15 0.15], ...
    'Position',[500 320 220 55], ...
    'Enable','off', ...
    'Callback',@stopDetection);

% Prediction history
historyLabel = uicontrol(fig, ...
    'Style','text', ...
    'String','RECENT PREDICTIONS', ...
    'FontSize',14, ...
    'FontWeight','bold', ...
    'BackgroundColor',[0.94 0.96 0.98], ...
    'Position',[200 265 550 30]);

historyBox = uicontrol(fig, ...
    'Style','listbox', ...
    'String',{'No predictions yet'}, ...
    'FontSize',12, ...
    'Position',[200 105 550 155]);

% Footer
uicontrol(fig, ...
    'Style','text', ...
    'String','Emergency Classes: Siren | Glass | BabyCry', ...
    'FontSize',11, ...
    'ForegroundColor',[0.4 0.4 0.4], ...
    'BackgroundColor',[0.94 0.96 0.98], ...
    'Position',[200 55 550 25]);

%% ==========================================
% START DETECTION CALLBACK
%% ==========================================

function startDetection(~,~)

    if isRunning
        return;
    end

    try
        recorder = audiorecorder(Fs,bits,channels);
    catch ME
        errordlg(ME.message,'Microphone Error');
        return;
    end

    isRunning = true;
    isBusy = false;

    predictionHistory(:) = "";
    historyCount = 0;
    historyIndex = 1;

    set(statusText,'String','LISTENING...', ...
        'ForegroundColor',[0 0.3 0.7]);

    set(classText,'String','Predicted Sound: Waiting...');

    set(voteText,'String','Emergency Votes: 0/0');

    set(startButton,'Enable','off');
    set(stopButton,'Enable','on');

    record(recorder);

    fprintf('\nLive detection started.\n');

    processNextChunk();

end

%% ==========================================
% PROCESS AUDIO CHUNK
%% ==========================================

function processNextChunk()

    if ~isRunning || ~ishandle(fig) || isBusy
        return;
    end

    isBusy = true;

    try

        % Wait for the next audio chunk
        pause(chunkDuration);

        if ~isRunning || ~ishandle(fig)
            isBusy = false;
            return;
        end

        audio = getaudiodata(recorder,'double');

        if isempty(audio)
            isBusy = false;
            processNextChunk();
            return;
        end

        % Keep only the latest 2 seconds
        requiredSamples = Fs*chunkDuration;

        if length(audio) > requiredSamples
            audio = audio(end-requiredSamples+1:end);
        end

        if length(audio) < requiredSamples
            isBusy = false;
            processNextChunk();
            return;
        end

        %% DISPLAY WAVEFORM

        timeAxis = (0:length(audio)-1)/Fs;

        plot(ax,timeAxis,audio);

        title(ax,'Live Microphone Waveform');

        drawnow;

        %% CLASSIFY AUDIO

        predictedClass = classifySound( ...
            audio,Fs,SVMModel,mu,sigma);

        fprintf('Predicted sound: %s\n',predictedClass);

        %% UPDATE HISTORY

        predictionHistory(historyIndex) = predictedClass;

        historyIndex = historyIndex + 1;

        if historyIndex > numberOfVotes
            historyIndex = 1;
        end

        historyCount = min(historyCount+1,numberOfVotes);

        recentPredictions = predictionHistory(1:historyCount);

        emergencyVotes = sum( ...
            ismember(lower(recentPredictions), ...
            lower(emergencyClasses)));

        set(voteText,'String', ...
            sprintf('Emergency Votes: %d/%d', ...
            emergencyVotes,historyCount));

        %% EMERGENCY DECISION

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

        %% UPDATE HISTORY LIST

        historyEntries = cell(historyCount,1);

        for j = 1:historyCount
            historyEntries{j} = char(recentPredictions(j));
        end

        set(historyBox,'String',historyEntries);

    catch ME

        fprintf('Detection error: %s\n',ME.message);

        stopDetection([],[]);

        errordlg(ME.message,'Detection Error');

        return;

    end

    isBusy = false;

    if isRunning && ishandle(fig)
        processNextChunk();
    end

end

%% ==========================================
% STOP DETECTION CALLBACK
%% ==========================================

function stopDetection(~,~)

    isRunning = false;

    if ~isempty(recorder)
        try
            stop(recorder);
        catch
        end
    end

    set(statusText,'String','DETECTION STOPPED', ...
        'ForegroundColor',[0.4 0.4 0.4]);

    set(startButton,'Enable','on');
    set(stopButton,'Enable','off');

    fprintf('\nDetection stopped.\n');

end

%% ==========================================
% CLOSE GUI
%% ==========================================

function closeGUI(~,~)

    isRunning = false;

    if ~isempty(recorder)
        try
            stop(recorder);
        catch
        end
    end

    delete(fig);

end

end

%% =========================================================
% AUDIO FEATURE EXTRACTION AND CLASSIFICATION
%% =========================================================

function predictedClass = classifySound(audio,Fs, ...
                                        SVMModel,mu,sigma)

    x = audio(:);

    % Remove DC offset
    x = x-mean(x);

    % Normalize
    x = x/(max(abs(x))+eps);

    % Bandpass filter
    [b,a] = butter(4,[100 7500]/(Fs/2),'bandpass');

    x = filtfilt(b,a,x);

    %% FRAMING

    frameLength = round(0.025*Fs);
    hopLength = round(frameLength*0.5);

    if length(x) < frameLength
        error('Audio chunk too short.');
    end

    numFrames = floor( ...
        (length(x)-frameLength)/hopLength)+1;

    energy = zeros(numFrames,1);
    zcr = zeros(numFrames,1);
    centroid = zeros(numFrames,1);
    bandwidth = zeros(numFrames,1);
    rolloff = zeros(numFrames,1);

    window = hamming(frameLength);

    NFFT = 1024;

    frequencies = (0:NFFT/2)'*Fs/NFFT;

    %% FEATURE EXTRACTION

    for i = 1:numFrames

        startIndex = (i-1)*hopLength+1;

        frame = x(startIndex:startIndex+frameLength-1);

        windowedFrame = frame.*window;

        energy(i) = mean(frame.^2);

        zcr(i) = sum(abs(diff(sign(frame)))) ...
            /(2*length(frame));

        spectrum = abs(fft(windowedFrame,NFFT));

        spectrum = spectrum(1:NFFT/2+1);

        spectrumSum = sum(spectrum)+eps;

        centroid(i) = sum(frequencies.*spectrum) ...
            /spectrumSum;

        bandwidth(i) = sqrt( ...
            sum(((frequencies-centroid(i)).^2).*spectrum) ...
            /spectrumSum);

        cumulativeSpectrum = cumsum(spectrum);

        threshold = 0.85*cumulativeSpectrum(end);

        rolloffIndex = find( ...
            cumulativeSpectrum >= threshold,1);

        rolloff(i) = frequencies(rolloffIndex);

    end

    %% RECORDING LEVEL FEATURES

    featureVector = [ ...
        mean(energy),std(energy), ...
        mean(zcr),std(zcr), ...
        mean(centroid),std(centroid), ...
        mean(bandwidth),std(bandwidth), ...
        mean(rolloff),std(rolloff)];

    %% NORMALIZATION

    featureVector = (featureVector-mu)./sigma;

    %% PREDICTION

    predictedClass = predict(SVMModel,featureVector);

    predictedClass = string(predictedClass);

end
