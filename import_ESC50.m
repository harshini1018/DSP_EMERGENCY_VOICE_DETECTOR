
clc;
clear;
close all;

%% ==========================================
% STEP 6: IMPORT ESC-50 DATASET
% ==========================================

fprintf('==========================================\n');
fprintf('       ESC-50 DATASET IMPORTER\n');
fprintf('==========================================\n\n');

%% ==========================================
% STEP 1: SELECT ESC-50 FOLDER
% ==========================================

esc50Folder = uigetdir(pwd, ...
    'Select the ESC-50-master folder');

if isequal(esc50Folder, 0)

    error('ESC-50 folder was not selected.');

end

fprintf('ESC-50 folder selected:\n');
fprintf('%s\n\n', esc50Folder);

%% ==========================================
% STEP 2: DEFINE ESC-50 LOCATIONS
% ==========================================

audioFolder = fullfile(esc50Folder, 'audio');

csvFile = fullfile( ...
    esc50Folder, ...
    'meta', ...
    'esc50.csv');

%% ==========================================
% STEP 3: CHECK AUDIO FOLDER
% ==========================================

if ~isfolder(audioFolder)

    error(['Audio folder not found: ' ...
        newline ...
        '%s' ...
        newline ...
        'Make sure you selected the ESC-50-master folder.'], ...
        audioFolder);

end

%% ==========================================
% STEP 4: CHECK CSV FILE
% ==========================================

if ~isfile(csvFile)

    error(['ESC-50 metadata file not found:' ...
        newline ...
        '%s' ...
        newline ...
        'Make sure esc50.csv exists inside the meta folder.'], ...
        csvFile);

end

fprintf('Audio folder found successfully.\n');
fprintf('Metadata file found successfully.\n\n');

%% ==========================================
% STEP 5: READ ESC-50 METADATA
% ==========================================

metadata = readtable(csvFile);

fprintf('ESC-50 metadata loaded successfully.\n\n');

%% ==========================================
% DISPLAY COLUMN NAMES
% ==========================================

disp('Metadata columns:');

disp(metadata.Properties.VariableNames);

%% ==========================================
% DISPLAY FIRST 5 ROWS
% ==========================================

fprintf('\nFirst five rows of metadata:\n\n');

disp(metadata(1:min(5,height(metadata)),:));

%% ==========================================
% STEP 6: CREATE OUR DATASET FOLDER
% ==========================================

datasetFolder = 'Dataset';

if ~isfolder(datasetFolder)

    mkdir(datasetFolder);

end

%% ==========================================
% CREATE CLASS FOLDERS
% ==========================================

sirenFolder = fullfile(datasetFolder,'Siren');

glassFolder = fullfile(datasetFolder,'Glass');

babyFolder = fullfile(datasetFolder,'BabyCry');

%% Create folders if they don't exist

if ~isfolder(sirenFolder)
    mkdir(sirenFolder);
end

if ~isfolder(glassFolder)
    mkdir(glassFolder);
end

if ~isfolder(babyFolder)
    mkdir(babyFolder);
end

fprintf('\nDataset folders ready.\n');

%% ==========================================
% STEP 7: DISPLAY AVAILABLE ESC-50 CLASSES
% ==========================================

fprintf('\n==========================================\n');
fprintf('AVAILABLE ESC-50 CLASSES\n');
fprintf('==========================================\n');

availableClasses = unique(metadata.category);

disp(availableClasses);

%% ==========================================
% STEP 8: FIND SIREN FILES
% ==========================================

sirenRows = strcmpi( ...
    metadata.category, ...
    'siren');

%% ==========================================
% STEP 9: FIND GLASS BREAKING FILES
% ==========================================

glassRows = strcmpi( ...
    metadata.category, ...
    'glass_breaking');

%% ==========================================
% STEP 10: FIND CRYING BABY FILES
% ==========================================

babyRows = strcmpi( ...
    metadata.category, ...
    'crying_baby');

%% ==========================================
% DISPLAY NUMBER OF FILES FOUND
% ==========================================

fprintf('\n==========================================\n');
fprintf('REQUIRED CLASSES FOUND\n');
fprintf('==========================================\n');

fprintf('Siren files:         %d\n', ...
    sum(sirenRows));

fprintf('Glass breaking:      %d\n', ...
    sum(glassRows));

fprintf('Crying baby:         %d\n', ...
    sum(babyRows));

%% ==========================================
% CHECK THAT FILES WERE FOUND
% ==========================================

if sum(sirenRows) == 0

    warning('No siren files were found.');

end

if sum(glassRows) == 0

    warning('No glass-breaking files were found.');

end

if sum(babyRows) == 0

    warning('No crying-baby files were found.');

end

%% ==========================================
% STEP 11: COPY SIREN FILES
% ==========================================

fprintf('\n==========================================\n');
fprintf('COPYING SIREN FILES\n');
fprintf('==========================================\n');

sirenTable = metadata(sirenRows,:);

for i = 1:height(sirenTable)

    sourceFile = fullfile( ...
        audioFolder, ...
        sirenTable.filename{i});

    destinationFile = fullfile( ...
        sirenFolder, ...
        sirenTable.filename{i});

    if isfile(sourceFile)

        copyfile(sourceFile,destinationFile);

        fprintf('Copied %d/%d: %s\n', ...
            i, ...
            height(sirenTable), ...
            sirenTable.filename{i});

    else

        warning('File not found: %s',sourceFile);

    end

end

%% ==========================================
% STEP 12: COPY GLASS FILES
% ==========================================

fprintf('\n==========================================\n');
fprintf('COPYING GLASS-BREAKING FILES\n');
fprintf('==========================================\n');

glassTable = metadata(glassRows,:);

for i = 1:height(glassTable)

    sourceFile = fullfile( ...
        audioFolder, ...
        glassTable.filename{i});

    destinationFile = fullfile( ...
        glassFolder, ...
        glassTable.filename{i});

    if isfile(sourceFile)

        copyfile(sourceFile,destinationFile);

        fprintf('Copied %d/%d: %s\n', ...
            i, ...
            height(glassTable), ...
            glassTable.filename{i});

    else

        warning('File not found: %s',sourceFile);

    end

end

%% ==========================================
% STEP 13: COPY BABY-CRY FILES
% ==========================================

fprintf('\n==========================================\n');
fprintf('COPYING CRYING-BABY FILES\n');
fprintf('==========================================\n');

babyTable = metadata(babyRows,:);

for i = 1:height(babyTable)

    sourceFile = fullfile( ...
        audioFolder, ...
        babyTable.filename{i});

    destinationFile = fullfile( ...
        babyFolder, ...
        babyTable.filename{i});

    if isfile(sourceFile)

        copyfile(sourceFile,destinationFile);

        fprintf('Copied %d/%d: %s\n', ...
            i, ...
            height(babyTable), ...
            babyTable.filename{i});

    else

        warning('File not found: %s',sourceFile);

    end

end

%% ==========================================
% STEP 14: COUNT FINAL FILES
% ==========================================

sirenFiles = dir( ...
    fullfile(sirenFolder,'*.wav'));

glassFiles = dir( ...
    fullfile(glassFolder,'*.wav'));

babyFiles = dir( ...
    fullfile(babyFolder,'*.wav'));

%% ==========================================
% FINAL RESULTS
% ==========================================

fprintf('\n');
fprintf('==========================================\n');
fprintf('       ESC-50 IMPORT COMPLETE\n');
fprintf('==========================================\n');

fprintf('\nFiles in Dataset/Siren:   %d\n', ...
    length(sirenFiles));

fprintf('Files in Dataset/Glass:   %d\n', ...
    length(glassFiles));

fprintf('Files in Dataset/BabyCry: %d\n', ...
    length(babyFiles));

fprintf('\nTotal imported files:     %d\n', ...
    length(sirenFiles) + ...
    length(glassFiles) + ...
    length(babyFiles));

fprintf('\n==========================================\n');
fprintf('Dataset location:\n');
fprintf('%s\n',fullfile(pwd,'Dataset'));
fprintf('==========================================\n');

%% ==========================================
% SHOW FINAL FOLDER STRUCTURE
% ==========================================

fprintf('\nYour dataset now contains:\n\n');

fprintf('Dataset/\n');
fprintf('   ├── Siren/   → %d WAV files\n', ...
    length(sirenFiles));

fprintf('   ├── Glass/   → %d WAV files\n', ...
    length(glassFiles));

fprintf('   └── BabyCry/ → %d WAV files\n', ...
    length(babyFiles));

fprintf('\nESC-50 import finished successfully!\n');