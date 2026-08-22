clc;
clear;
close all;

%% ==========================================
% SVM TRAINING
%% ==========================================

load('splitDataset.mat');

fprintf('============================================\n');
fprintf('          SVM CLASSIFIER\n');
fprintf('============================================\n');

%% ==========================================
% FEATURE NORMALIZATION
%% ==========================================

mu = mean(XTrain,1);

sigma = std(XTrain,[],1);

sigma(sigma == 0) = 1;

%% Normalize training

XTrainNorm = ...
    (XTrain - mu)./sigma;

%% Normalize testing using TRAINING parameters

XTestNorm = ...
    (XTest - mu)./sigma;

%% ==========================================
% TRAIN MULTICLASS SVM
%% ==========================================

fprintf('\nTraining SVM...\n');

SVMModel = fitcecoc( ...
    XTrainNorm, ...
    YTrain, ...
    'Learners','linear');

fprintf('SVM training completed.\n');

%% ==========================================
% TEST
%% ==========================================

YPred = predict( ...
    SVMModel, ...
    XTestNorm);

%% ==========================================
% ACCURACY
%% ==========================================

accuracy = ...
    mean(YPred == YTest)*100;

fprintf('\n============================================\n');

fprintf('SVM TEST ACCURACY: %.2f %%\n', ...
    accuracy);

fprintf('============================================\n');

%% ==========================================
% CONFUSION MATRIX
%% ==========================================

figure;

confusionchart(YTest,YPred);

title('SVM Confusion Matrix');

%% ==========================================
% SAVE MODEL
%% ==========================================

save('trainedModel.mat', ...
    'SVMModel', ...
    'mu', ...
    'sigma');

fprintf('\nModel saved as:\n');
fprintf('trainedModel.mat\n');