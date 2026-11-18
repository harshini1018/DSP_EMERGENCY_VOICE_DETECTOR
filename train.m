
clc;
clear;
close all;

%% ==========================================
% TRAIN / TEST SPLIT
% Split audio recordings, not individual frames
%% ==========================================

% Load extracted features
load('featureDataset.mat');

fprintf('============================================\n');
fprintf('          TRAIN / TEST SPLIT\n');
fprintf('============================================\n');

%% Check dataset

if isempty(allFeatures) || isempty(allLabels)
    error('Dataset is empty. Run BUILD_DATASET.m first.');
end

fprintf('Total recordings: %d\n', size(allFeatures,1));

%% ==========================================
% 70% TRAIN / 30% TEST SPLIT
% Stratified split: each class is split separately
%% ==========================================

rng(42);

classes = categories(allLabels);

trainIndex = false(size(allLabels));
testIndex = false(size(allLabels));

for i = 1:numel(classes)

    classIdx = find(allLabels == classes{i});

    classIdx = classIdx(randperm(numel(classIdx)));

    nTrain = round(0.70 * numel(classIdx));

    trainIndex(classIdx(1:nTrain)) = true;
    testIndex(classIdx(nTrain+1:end)) = true;

end

%% ==========================================
% CREATE TRAINING DATA
%% ==========================================

XTrain = allFeatures(trainIndex,:);
YTrain = allLabels(trainIndex);

%% ==========================================
% CREATE TESTING DATA
%% ==========================================

XTest = allFeatures(testIndex,:);
YTest = allLabels(testIndex);

%% Keep recording names

trainFiles = allFiles(trainIndex);
testFiles = allFiles(testIndex);

%% Keep folds

trainFolds = allFolds(trainIndex);
testFolds = allFolds(testIndex);

%% ==========================================
% DISPLAY RESULTS
%% ==========================================

fprintf('\nTraining recordings: %d\n', size(XTrain,1));
fprintf('Testing recordings: %d\n', size(XTest,1));

fprintf('\nTraining classes:\n');

trainClasses = categories(YTrain);

for i = 1:numel(trainClasses)

    fprintf('%-15s : %d\n', ...
        trainClasses{i}, ...
        sum(YTrain == trainClasses{i}));

end

fprintf('\nTesting classes:\n');

testClasses = categories(YTest);

for i = 1:numel(testClasses)

    fprintf('%-15s : %d\n', ...
        testClasses{i}, ...
        sum(YTest == testClasses{i}));

end

%% ==========================================
% SAVE DATASET
%% ==========================================

save('splitDataset.mat', ...
    'XTrain', ...
    'YTrain', ...
    'XTest', ...
    'YTest', ...
    'trainFiles', ...
    'testFiles', ...
    'trainFolds', ...
    'testFolds');

fprintf('\nSaved: splitDataset.mat\n');
fprintf('\nTRAIN / TEST SPLIT COMPLETED!\n');
