clc;
clear;
close all;

%% ==========================================
% TRAIN / TEST SPLIT
%
% IMPORTANT:
% We split AUDIO RECORDINGS, not individual
% frames.
%% ==========================================

load('featureDataset.mat');

fprintf('============================================\n');
fprintf('       TRAIN / TEST SPLIT\n');
fprintf('============================================\n');

%% Random seed

rng(42);

%% ==========================================
% 70% TRAIN / 30% TEST
%% ==========================================

cv = cvpartition(allLabels, ...
    'HoldOut',0.30);

trainIndex = training(cv);

testIndex = test(cv);

%% Training

XTrain = allFeatures(trainIndex,:);

YTrain = allLabels(trainIndex);

%% Testing

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

fprintf('\nTraining recordings: %d\n', ...
    size(XTrain,1));

fprintf('Testing recordings: %d\n', ...
    size(XTest,1));

fprintf('\nTraining classes:\n');

trainClasses = categories(YTrain);

for i = 1:length(trainClasses)

    fprintf('%-15s : %d\n', ...
        trainClasses{i}, ...
        sum(YTrain == trainClasses{i}));

end

fprintf('\nTesting classes:\n');

testClasses = categories(YTest);

for i = 1:length(testClasses)

    fprintf('%-15s : %d\n', ...
        testClasses{i}, ...
        sum(YTest == testClasses{i}));

end

%% ==========================================
% SAVE
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