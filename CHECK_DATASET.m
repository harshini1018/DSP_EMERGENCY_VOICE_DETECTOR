clc;
clear;
close all;

%% ==========================================
% CHECK FINAL FEATURE DATASET
%% ==========================================

load('featureDataset.mat');

fprintf('============================================\n');
fprintf('        FEATURE DATASET CHECK\n');
fprintf('============================================\n\n');

%% Dataset size

fprintf('Total recordings: %d\n', ...
    size(allFeatures,1));

fprintf('Number of features: %d\n\n', ...
    size(allFeatures,2));

%% Feature names

fprintf('Features:\n');

for i = 1:length(featureNames)

    fprintf('%2d. %s\n', ...
        i,featureNames{i});

end

%% Classes

fprintf('\nClasses:\n');

classes = categories(allLabels);

disp(classes);

%% Class counts

fprintf('Class distribution:\n\n');

for i = 1:length(classes)

    count = sum(allLabels == classes{i});

    fprintf('%-15s : %d\n', ...
        classes{i},count);

end

%% NaN check

nanCount = sum(isnan(allFeatures),'all');

fprintf('\nNaN values: %d\n',nanCount);

%% Infinite check

infCount = sum(isinf(allFeatures),'all');

fprintf('Infinite values: %d\n',infCount);

%% Fold information

fprintf('\nESC-50 fold information:\n');

uniqueFolds = unique(allFolds);

disp(uniqueFolds');

%% First 5 recordings

fprintf('\nFirst 5 recordings:\n');

for i = 1:min(5,length(allFiles))

    fprintf('%s --> %s\n', ...
        allFiles{i}, ...
        string(allLabels(i)));

end

%% Plot class distribution

figure;

histogram(allLabels);

xlabel('Sound Class');

ylabel('Number of Recordings');

title('Dataset Class Distribution');

grid on;

fprintf('\nDataset check complete.\n');