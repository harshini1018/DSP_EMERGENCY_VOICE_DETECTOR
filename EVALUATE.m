clc;
clear;
close all;

%% ==========================================
% MODEL EVALUATION
%% ==========================================

load('splitDataset.mat');

load('trainedModel.mat');

%% Normalize test data

XTestNorm = ...
    (XTest - mu)./sigma;

%% Predict

YPred = predict( ...
    SVMModel, ...
    XTestNorm);

%% ==========================================
% ACCURACY
%% ==========================================

accuracy = ...
    mean(YPred == YTest);

fprintf('============================================\n');
fprintf('         MODEL EVALUATION\n');
fprintf('============================================\n\n');

fprintf('Overall Accuracy: %.2f %%\n', ...
    accuracy*100);

%% ==========================================
% CONFUSION MATRIX
%% ==========================================

figure;

cm = confusionchart(YTest,YPred);

cm.Title = 'Emergency Sound Detector';
cm.RowSummary = 'row-normalized';
cm.ColumnSummary = 'column-normalized';

%% ==========================================
% CLASS-WISE METRICS
%% ==========================================

classes = categories(YTest);

precisionValues = zeros(length(classes),1);

recallValues = zeros(length(classes),1);

f1Values = zeros(length(classes),1);

fprintf('\n');
fprintf('============================================\n');
fprintf('CLASS-WISE RESULTS\n');
fprintf('============================================\n');

for i = 1:length(classes)

    currentClass = classes{i};

    actual = YTest == currentClass;

    predicted = YPred == currentClass;

    TP = sum(actual & predicted);

    FP = sum(~actual & predicted);

    FN = sum(actual & ~predicted);

    %% Precision

    if TP + FP == 0

        precision = 0;

    else

        precision = TP/(TP+FP);

    end

    %% Recall

    if TP + FN == 0

        recall = 0;

    else

        recall = TP/(TP+FN);

    end

    %% F1

    if precision + recall == 0

        F1 = 0;

    else

        F1 = 2*precision*recall ...
            /(precision+recall);

    end

    precisionValues(i) = precision;

    recallValues(i) = recall;

    f1Values(i) = F1;

    fprintf('\n%s\n',currentClass);

    fprintf('Precision : %.2f %%\n', ...
        precision*100);

    fprintf('Recall    : %.2f %%\n', ...
        recall*100);

    fprintf('F1 Score  : %.2f %%\n', ...
        F1*100);

end

%% ==========================================
% MACRO AVERAGE
%% ==========================================

fprintf('\n');
fprintf('============================================\n');

fprintf('Average Precision: %.2f %%\n', ...
    mean(precisionValues)*100);

fprintf('Average Recall: %.2f %%\n', ...
    mean(recallValues)*100);

fprintf('Average F1 Score: %.2f %%\n', ...
    mean(f1Values)*100);

fprintf('============================================\n');

%% ==========================================
% EMERGENCY VS NORMAL PERFORMANCE
%% ==========================================

emergencyClasses = { ...
    'Siren', ...
    'Glass', ...
    'BabyCry'};

emergencyActual = ...
    ismember(string(YTest),emergencyClasses);

emergencyPredicted = ...
    ismember(string(YPred),emergencyClasses);

emergencyAccuracy = ...
    mean(emergencyActual == emergencyPredicted)*100;

fprintf('\n');
fprintf('Emergency/Normal binary accuracy: %.2f %%\n', ...
    emergencyAccuracy);