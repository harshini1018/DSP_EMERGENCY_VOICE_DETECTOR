

clc;
clear;
close all;

%% ==========================================
% SVM TRAINING AND EVALUATION
%% ==========================================

load('splitDataset.mat');

fprintf('============================================\n');
fprintf('       SVM CLASSIFIER\n');
fprintf('============================================\n');

%% ==========================================
% CHECK DATA
%% ==========================================

if isempty(XTrain) || isempty(XTest)
    error('Training or testing data is empty.');
end

fprintf('\nTraining samples: %d\n',size(XTrain,1));
fprintf('Testing samples: %d\n',size(XTest,1));
fprintf('Number of features: %d\n',size(XTrain,2));

%% ==========================================
% FEATURE NORMALIZATION
%% ==========================================

mu = mean(XTrain,1);
sigma = std(XTrain,[],1);

sigma(sigma == 0) = 1;

% Normalize training data
XTrainNorm = (XTrain-mu)./sigma;

% Normalize testing data using training parameters
XTestNorm = (XTest-mu)./sigma;

%% ==========================================
% TRAIN MULTICLASS SVM
%% ==========================================

fprintf('\nTraining SVM...\n');

SVMModel = fitcecoc( ...
    XTrainNorm, ...
    YTrain, ...
    'Learners','linear');

fprintf('SVM training completed!\n');

%% ==========================================
% PREDICTION
%% ==========================================

fprintf('\nPredicting test recordings...\n');

YPred = predict(SVMModel,XTestNorm);

%% ==========================================
% OVERALL ACCURACY
%% ==========================================

accuracy = mean(YPred == YTest)*100;

fprintf('\n============================================\n');
fprintf('       SVM CLASSIFICATION RESULTS\n');
fprintf('============================================\n');

fprintf('\nOverall Accuracy: %.2f %%\n',accuracy);

%% ==========================================
% CONFUSION MATRIX
%% ==========================================

classNames = categories(YTest);

confMat = confusionmat(YTest,YPred, ...
    'Order',categorical(classNames));

figure;

confusionchart(confMat,classNames);

title('SVM Confusion Matrix');

%% ==========================================
% PRECISION, RECALL AND F1 SCORE
%% ==========================================

numClasses = numel(classNames);

precision = zeros(numClasses,1);
recall = zeros(numClasses,1);
F1 = zeros(numClasses,1);

for i = 1:numClasses

    TP = confMat(i,i);

    FP = sum(confMat(:,i))-TP;

    FN = sum(confMat(i,:))-TP;

    precision(i) = TP/(TP+FP+eps);

    recall(i) = TP/(TP+FN+eps);

    F1(i) = 2*precision(i)*recall(i)/ ...
        (precision(i)+recall(i)+eps);

end

fprintf('\n============================================\n');
fprintf('       CLASS-WISE PERFORMANCE\n');
fprintf('============================================\n');

for i = 1:numClasses

    fprintf('\nClass: %s\n',classNames{i});

    fprintf('Precision: %.2f %%\n',precision(i)*100);

    fprintf('Recall: %.2f %%\n',recall(i)*100);

    fprintf('F1 Score: %.2f %%\n',F1(i)*100);

end

%% ==========================================
% MACRO AVERAGE METRICS
%% ==========================================

macroPrecision = mean(precision)*100;
macroRecall = mean(recall)*100;
macroF1 = mean(F1)*100;

fprintf('\n============================================\n');
fprintf('       MACRO AVERAGE PERFORMANCE\n');
fprintf('============================================\n');

fprintf('Macro Precision: %.2f %%\n',macroPrecision);
fprintf('Macro Recall: %.2f %%\n',macroRecall);
fprintf('Macro F1 Score: %.2f %%\n',macroF1);

%% ==========================================
% EMERGENCY VS NORMAL CLASSIFICATION
%% ==========================================

% Emergency classes:
% BabyCry, Glass, Siren
%
% Normal classes:
% Speech, Noise

%% EMERGENCY VS NORMAL CLASSIFICATION

% Emergency: Siren, Glass
% Normal: Speech, Noise

trueEmergency = ismember(string(YTest), ...
    ["Siren","Glass"]);

predEmergency = ismember(string(YPred), ...
    ["Siren","Glass"]);

emergencyAccuracy = ...
    mean(trueEmergency == predEmergency)*100;

fprintf('\nEmergency vs Normal Accuracy: %.2f%%\n', ...
    emergencyAccuracy);


%% ==========================================
% SAVE TRAINED MODEL
%% ==========================================

save('trainedModel.mat', ...
    'SVMModel', ...
    'mu', ...
    'sigma', ...
    'accuracy', ...
    'precision', ...
    'recall', ...
    'F1', ...
    'macroPrecision', ...
    'macroRecall', ...
    'macroF1', ...
    'emergencyAccuracy', ...
    'classNames');

fprintf('\n============================================\n');
fprintf('MODEL SAVED SUCCESSFULLY!\n');
fprintf('File: trainedModel.mat\n');
fprintf('============================================\n');

fprintf('\nSVM TRAINING AND EVALUATION COMPLETED!\n');
