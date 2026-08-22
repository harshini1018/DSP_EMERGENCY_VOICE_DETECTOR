clc;
clear;
close all;

%% =========================================================
% BUILD DATASET
%
% One row = ONE audio recording
%
% Features:
% 1. Mean Energy
% 2. Std Energy
% 3. Mean ZCR
% 4. Std ZCR
% 5. Mean Spectral Centroid
% 6. Std Spectral Centroid
% 7. Mean Spectral Bandwidth
% 8. Std Spectral Bandwidth
% 9. Mean Spectral Rolloff
% 10. Std Spectral Rolloff
%
% Classes:
% Siren
% Glass
% BabyCry
% Speech
% Noise
%% =========================================================

clc;
clear;
close all;

fprintf('============================================\n');
fprintf('       BUILDING FINAL FEATURE DATASET\n');
fprintf('============================================\n');

%% ---------------------------------------------------------
% SETTINGS
%% ---------------------------------------------------------

targetFs = 16000;

datasetFolder = 'Dataset';

classes = {
    'Siren'
    'Glass'
    'BabyCry'
    'Speech'
    'Noise'
};

%% ---------------------------------------------------------
% CHECK DATASET FOLDERS
%% ---------------------------------------------------------

for c = 1:length(classes)

    folder = fullfile(datasetFolder, classes{c});

    if ~isfolder(folder)

        error(['Missing dataset folder: ', folder, ...
            newline, ...
            'Create the folder and add WAV files before running this program.']);

    end

end

%% ---------------------------------------------------------
% FEATURE STORAGE
%% ---------------------------------------------------------

allFeatures = [];

allLabels = {};

allFiles = {};

allFolds = [];

%% ---------------------------------------------------------
% PROCESS EACH CLASS
%% ---------------------------------------------------------

for c = 1:length(classes)

    className = classes{c};

    classFolder = fullfile(datasetFolder,className);

    files = dir(fullfile(classFolder,'*.wav'));

    fprintf('\n');
    fprintf('--------------------------------------------\n');
    fprintf('Class: %s\n',className);
    fprintf('Files: %d\n',length(files));
    fprintf('--------------------------------------------\n');

    if isempty(files)

        warning('No WAV files found in %s',classFolder);
        continue;

    end

    %% -----------------------------------------------------
    % PROCESS EACH RECORDING
    %% -----------------------------------------------------

    for k = 1:length(files)

        filename = files(k).name;

        fullFilename = fullfile( ...
            classFolder,filename);

        fprintf('Processing %d/%d: %s\n', ...
            k,length(files),filename);

        try

            %% =============================================
            % LOAD AUDIO
            %% =============================================

            [x,Fs] = audioread(fullFilename);

            %% =============================================
            % CONVERT TO MONO
            %% =============================================

            if size(x,2) > 1

                x = mean(x,2);

            end

            %% =============================================
            % REMOVE DC OFFSET
            %% =============================================

            x = x - mean(x);

            %% =============================================
            % RESAMPLE
            %% =============================================

            if Fs ~= targetFs

                x = resample(x,targetFs,Fs);

                Fs = targetFs;

            end

            %% =============================================
            % NORMALIZE
            %% =============================================

            maxValue = max(abs(x));

            if maxValue > 0

                x = x/maxValue;

            end

            %% =============================================
            % BAND-PASS FILTER
            %% =============================================

            lowCut = 100;
            highCut = 7500;

            [b,a] = butter(4, ...
                [lowCut highCut]/(Fs/2), ...
                'bandpass');

            x = filtfilt(b,a,x);

            %% =============================================
            % FRAME PARAMETERS
            %% =============================================

            frameLength = round(0.025*Fs);

            hopLength = round(0.0125*Fs);

            %% Make sure recording is long enough

            if length(x) < frameLength

                warning('Recording too short: %s',filename);

                continue;

            end

            %% Number of frames

            numFrames = floor( ...
                (length(x)-frameLength)/hopLength) + 1;

            %% =============================================
            % FEATURE ARRAYS FOR THIS RECORDING
            %% =============================================

            energy = zeros(numFrames,1);

            zcr = zeros(numFrames,1);

            centroid = zeros(numFrames,1);

            bandwidth = zeros(numFrames,1);

            rolloff = zeros(numFrames,1);

            %% =============================================
            % FRAME-BY-FRAME FEATURE EXTRACTION
            %% =============================================

            for frameNumber = 1:numFrames

                %% Frame indexes

                startIndex = ...
                    (frameNumber-1)*hopLength + 1;

                endIndex = ...
                    startIndex + frameLength - 1;

                frame = x(startIndex:endIndex);

                %% =========================================
                % HAMMING WINDOW
                %% =========================================

                window = hamming(frameLength);

                windowedFrame = frame .* window;

                %% =========================================
                % 1. SHORT-TIME ENERGY
                %% =========================================

                energy(frameNumber) = ...
                    mean(frame.^2);

                %% =========================================
                % 2. ZERO CROSSING RATE
                %% =========================================

                zcr(frameNumber) = ...
                    sum(abs(diff(sign(frame)))) ...
                    /(2*length(frame));

                %% =========================================
                % FFT
                %% =========================================

                NFFT = 1024;

                spectrum = abs( ...
                    fft(windowedFrame,NFFT));

                %% Positive frequencies only

                spectrum = ...
                    spectrum(1:NFFT/2+1);

                %% Frequency vector

                frequencies = ...
                    (0:NFFT/2)'*Fs/NFFT;

                %% =========================================
                % 3. SPECTRAL CENTROID
                %% =========================================

                spectrumSum = ...
                    sum(spectrum) + eps;

                centroid(frameNumber) = ...
                    sum(frequencies.*spectrum) ...
                    /spectrumSum;

                %% =========================================
                % 4. SPECTRAL BANDWIDTH
                %% =========================================

                bandwidth(frameNumber) = sqrt( ...
                    sum(((frequencies ...
                    - centroid(frameNumber)).^2) ...
                    .* spectrum) ...
                    /spectrumSum);

                %% =========================================
                % 5. SPECTRAL ROLLOFF
                %% =========================================

                cumulativeSpectrum = ...
                    cumsum(spectrum);

                threshold = ...
                    0.85*cumulativeSpectrum(end);

                rolloffIndex = ...
                    find(cumulativeSpectrum ...
                    >= threshold,1);

                if isempty(rolloffIndex)

                    rolloff(frameNumber) = 0;

                else

                    rolloff(frameNumber) = ...
                        frequencies(rolloffIndex);

                end

            end

            %% =============================================
            % RECORDING-LEVEL FEATURES
            %
            % Mean + standard deviation
            %% =============================================

            recordingFeatures = [ ...
                mean(energy), ...
                std(energy), ...
                mean(zcr), ...
                std(zcr), ...
                mean(centroid), ...
                std(centroid), ...
                mean(bandwidth), ...
                std(bandwidth), ...
                mean(rolloff), ...
                std(rolloff) ...
            ];

            %% =============================================
            % ADD TO DATASET
            %% =============================================

            allFeatures = ...
                [allFeatures; recordingFeatures];

            allLabels = ...
                [allLabels; {className}];

            allFiles = ...
                [allFiles; {filename}];

            %% =============================================
            % ESC-50 FOLD
            %
            % ESC-50 filenames begin with:
            %
            % 1-xxxxx...
            % 2-xxxxx...
            %
            % First number = fold
            %% =============================================

            dashPosition = strfind(filename,'-');

            if ~isempty(dashPosition)

                firstPart = ...
                    filename(1:dashPosition(1)-1);

                foldNumber = str2double(firstPart);

                if isnan(foldNumber)

                    foldNumber = 0;

                end

            else

                foldNumber = 0;

            end

            allFolds = ...
                [allFolds; foldNumber];

        catch ME

            fprintf('\nERROR processing:\n');
            fprintf('%s\n',fullFilename);
            fprintf('%s\n',ME.message);

        end

    end

end

%% =========================================================
% CONVERT LABELS TO CATEGORICAL
%% =========================================================

allLabels = categorical(allLabels);

%% =========================================================
% FEATURE NAMES
%% =========================================================

featureNames = {
    'MeanEnergy'
    'StdEnergy'
    'MeanZCR'
    'StdZCR'
    'MeanCentroid'
    'StdCentroid'
    'MeanBandwidth'
    'StdBandwidth'
    'MeanRolloff'
    'StdRolloff'
};

%% =========================================================
% DISPLAY RESULTS
%% =========================================================

fprintf('\n');
fprintf('============================================\n');
fprintf('       DATASET CREATION COMPLETE\n');
fprintf('============================================\n');

fprintf('Total recordings: %d\n', ...
    size(allFeatures,1));

fprintf('Features per recording: %d\n', ...
    size(allFeatures,2));

%% =========================================================
% DISPLAY CLASS COUNTS
%% =========================================================

fprintf('\nClass distribution:\n\n');

classList = categories(allLabels);

for c = 1:length(classList)

    count = sum(allLabels == classList{c});

    fprintf('%-15s : %d recordings\n', ...
        classList{c},count);

end

%% =========================================================
% SAVE DATASET
%% =========================================================

save('featureDataset.mat', ...
    'allFeatures', ...
    'allLabels', ...
    'allFiles', ...
    'allFolds', ...
    'featureNames');

fprintf('\n');
fprintf('Saved:\n');
fprintf('featureDataset.mat\n');

fprintf('\n============================================\n');
fprintf('DONE\n');
fprintf('============================================\n');