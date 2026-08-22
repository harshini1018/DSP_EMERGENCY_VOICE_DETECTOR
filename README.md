# DSP-Based Emergency Sound Detector

## 1. Project Overview

The DSP-Based Emergency Sound Detector is a MATLAB software-only audio
classification system. It processes audio using Digital Signal
Processing (DSP), extracts numerical audio features, and uses a Support
Vector Machine (SVM) classifier.

Final classes:

  Class     Decision
  --------- -----------
  Siren     EMERGENCY
  Glass     EMERGENCY
  BabyCry   EMERGENCY
  Speech    NORMAL
  Noise     NORMAL

Main pipeline:

``` text
Audio
  ↓
Mono conversion
  ↓
Resampling to 16 kHz
  ↓
Normalization
  ↓
Band-pass filtering
  ↓
Framing
  ↓
Hamming window
  ↓
FFT / frequency analysis
  ↓
STFT / spectrogram
  ↓
Feature extraction
  ↓
SVM classification
  ↓
Emergency / Normal decision
  ↓
Real-time microphone detector
```

## 2. Dataset

The final target dataset is:

``` text
Dataset/
├── Siren/       → 40 WAV files
├── Glass/       → 40 WAV files
├── BabyCry/     → 40 WAV files
├── Speech/      → 40 WAV files
└── Noise/       → 40 WAV files
```

Total: **200 recordings**.

ESC-50 is used for relevant environmental classes such as siren, glass
breaking, and crying baby. Speech is supplied from a speech dataset such
as FSDD, and Noise is supplied from suitable environmental recordings.

## 3. Module Summary

  Module                  Purpose
  ----------------------- ------------------------------------------------------
  `LOAD_AUDIO.m`          Load, plot and play WAV audio
  `PREPROCESSING.m`       Mono, resample, normalize and filter
  `FFT.m`                 Frequency-domain analysis
  `STFT.m`                Time-frequency analysis / spectrogram
  `FEATURES.m`            Calculate audio DSP features
  `import_ESC50.m`        Import selected ESC-50 emergency sounds
  `IMPORT_NOISE.m`        Import environmental noise
  `BUILD_DATASET.m`       Process all recordings and create feature matrix
  `CHECK_DATASET.m`       Verify feature dataset
  `TRAIN_TEST_SPLIT.m`    Split recordings into training and testing
  `SVM.m`                 Train multiclass SVM
  `EVALUATE.m`            Accuracy, precision, recall, F1 and confusion matrix
  `REALTIME_DETECTOR.m`   Final live microphone application

## 4. LOAD_AUDIO.m

Purpose:

1.  Select a WAV file.
2.  Load samples using `audioread`.
3.  Obtain sampling frequency.
4.  Calculate duration.
5.  Convert stereo to mono.
6.  Plot the time-domain waveform.
7.  Play the audio.

Important variables:

``` matlab
[x, Fs] = audioread(filename);
```

`x` is the digital signal and `Fs` is the sampling frequency.

## 5. PREPROCESSING.m

Pipeline:

``` text
Raw audio
 ↓
Mono
 ↓
16 kHz
 ↓
Normalization
 ↓
Band-pass filter
```

Current parameters:

``` text
Target sampling frequency = 16,000 Hz
Low cutoff = 100 Hz
High cutoff = 7,500 Hz
Filter = 4th-order Butterworth
```

Normalization approximately produces:

``` text
-1 ≤ x[n] ≤ 1
```

The band-pass filter removes very low and very high frequency components
outside the selected analysis range.

## 6. FFT.m

FFT converts the time-domain signal to the frequency domain.

``` text
Time domain
    ↓ FFT
Frequency domain
```

Main operation:

``` matlab
X = fft(x);
```

The magnitude spectrum is:

``` matlab
abs(X)
```

For `Fs = 16 kHz`, the Nyquist frequency is:

``` text
Fs/2 = 8 kHz
```

Therefore the positive spectrum is normally displayed from 0 to 8 kHz.

The FFT helps identify strong frequency components in emergency sounds.

## 7. STFT.m

A single FFT does not show when frequencies occur. STFT solves this by
applying FFT to short overlapping frames.

Current parameters:

``` text
Frame length = 25 ms
Overlap = 50%
FFT size = 1024
```

Output:

``` text
Spectrogram
```

The spectrogram displays:

``` text
X-axis = time
Y-axis = frequency
Intensity = signal strength
```

Siren frequency changes can be visualized clearly with the spectrogram.

## 8. FEATURES.m

The project extracts five basic DSP features from short frames:

1.  Energy
2.  Zero Crossing Rate (ZCR)
3.  Spectral Centroid
4.  Spectral Bandwidth
5.  Spectral Rolloff

These are the bridge between DSP and machine learning.

### Energy

``` text
E = (1/N) Σ x[n]^2
```

Measures signal strength.

### ZCR

Measures how frequently the waveform changes sign.

### Spectral Centroid

Approximates the center of gravity of the frequency spectrum.

### Spectral Bandwidth

Measures how widely the spectrum is distributed around the centroid.

### Spectral Rolloff

Uses the frequency below which approximately 85% of the spectral
magnitude is contained.

## 9. import_ESC50.m

Reads:

``` text
ESC-50-master/meta/esc50.csv
```

and uses the metadata to find selected categories.

It copies:

``` text
siren
glass_breaking
crying_baby
```

into:

``` text
Dataset/Siren/
Dataset/Glass/
Dataset/BabyCry/
```

This avoids manually copying those files.

## 10. IMPORT_NOISE.m

Reads the ESC-50 metadata and copies selected environmental recordings
into:

``` text
Dataset/Noise/
```

The purpose is to create a normal/background sound class.

## 11. BUILD_DATASET.m

This is the main dataset-processing module.

For every WAV recording:

``` text
WAV
 ↓
Mono
 ↓
Remove DC offset
 ↓
16 kHz
 ↓
Normalize
 ↓
Band-pass filter
 ↓
25-ms frames
 ↓
Hamming window
 ↓
FFT
 ↓
5 frame-level features
 ↓
Mean + standard deviation
 ↓
One feature vector per recording
```

The new design uses **one row per recording**, rather than one row per
frame. This helps prevent data leakage when recordings are separated
into training and testing.

### Final 10 features

``` text
1.  MeanEnergy
2.  StdEnergy
3.  MeanZCR
4.  StdZCR
5.  MeanCentroid
6.  StdCentroid
7.  MeanBandwidth
8.  StdBandwidth
9.  MeanRolloff
10. StdRolloff
```

Each recording therefore becomes:

``` text
[10 numerical features] + [class label]
```

The module creates:

``` text
featureDataset.mat
```

## 12. featureDataset.mat

Contains:

``` text
allFeatures
allLabels
allFiles
allFolds
featureNames
```

`allFeatures` is the numerical feature matrix.

`allLabels` contains:

``` text
Siren
Glass
BabyCry
Speech
Noise
```

## 13. CHECK_DATASET.m

Checks:

-   Total recordings
-   Number of features
-   Class names
-   Number of recordings per class
-   NaN values
-   Infinite values
-   Fold information

Expected target:

``` text
Siren       40
Glass       40
BabyCry     40
Speech      40
Noise       40
```

and:

``` text
Features per recording = 10
```

## 14. TRAIN_TEST_SPLIT.m

Splits the **recordings** into:

``` text
70% training
30% testing
```

This is done at recording level, not frame level.

Outputs:

``` text
XTrain
YTrain
XTest
YTest
```

and saves:

``` text
splitDataset.mat
```

The training set is used to train the classifier. The test set remains
unseen during training.

## 15. SVM.m

The SVM receives the ten DSP features.

Before training, features are standardized using the training data:

``` text
z = (x - mean) / standard deviation
```

The same training mean and standard deviation are then applied to the
test data.

MATLAB uses:

``` matlab
fitcecoc(...)
```

to implement multiclass SVM classification.

Possible outputs:

``` text
Siren
Glass
BabyCry
Speech
Noise
```

The trained model is saved as:

``` text
trainedModel.mat
```

## 16. EVALUATE.m

Evaluates the trained model on unseen test recordings.

It calculates:

-   Accuracy
-   Precision
-   Recall
-   F1-score
-   Confusion matrix
-   Emergency/Normal binary accuracy

### Accuracy

``` text
Correct predictions / Total predictions
```

### Precision

``` text
TP / (TP + FP)
```

Answers:

> When the system predicts a class, how often is it correct?

### Recall

``` text
TP / (TP + FN)
```

Answers:

> Of the actual examples of a class, how many were detected?

### F1-score

``` text
2 × Precision × Recall / (Precision + Recall)
```

### Confusion matrix

The diagonal contains correct predictions. Off-diagonal entries show
class confusion.

## 17. Emergency / Normal Logic

The five-class prediction is converted into the application decision:

``` text
Siren
Glass
BabyCry
   ↓
EMERGENCY
```

and:

``` text
Speech
Noise
   ↓
NORMAL
```

Therefore the application can display:

``` text
EMERGENCY SOUND DETECTED
```

or:

``` text
NORMAL SOUND
```

## 18. Final Real-Time Detector

The final module will use the laptop microphone.

Architecture:

``` text
Laptop microphone
       ↓
Audio buffer
       ↓
16 kHz
       ↓
Mono
       ↓
Normalization
       ↓
Band-pass filter
       ↓
25-ms framing
       ↓
Hamming window
       ↓
FFT
       ↓
10 feature vector
       ↓
Training normalization parameters
       ↓
Trained SVM
       ↓
Predicted class
       ↓
Emergency / Normal
       ↓
Alert
```

The real-time detector must use the **same preprocessing and feature
definitions** as the training pipeline.

## 19. Majority Voting

For a more reliable real-time detector, do not trigger an emergency from
one prediction alone.

Example:

``` text
Window 1 → Siren
Window 2 → Siren
Window 3 → Speech
Window 4 → Siren
Window 5 → Siren
```

Four out of five predictions are emergency.

Therefore:

``` text
EMERGENCY DETECTED
```

This reduces false alarms.

## 20. Complete Project Flow

``` text
                    DATASET
                       ↓
          Siren / Glass / BabyCry
             Speech / Noise
                       ↓
                 LOAD AUDIO
                       ↓
                PREPROCESSING
                       ↓
             ┌─────────┴─────────┐
             ↓                   ↓
            FFT                 STFT
             ↓                   ↓
       Frequency spectrum    Spectrogram
             └─────────┬─────────┘
                       ↓
              FEATURE EXTRACTION
                       ↓
                10 DSP FEATURES
                       ↓
                BUILD DATASET
                       ↓
               CHECK DATASET
                       ↓
              TRAIN/TEST SPLIT
                       ↓
                    SVM
                       ↓
              MODEL EVALUATION
                       ↓
          Accuracy / Precision / Recall
              F1 / Confusion Matrix
                       ↓
             REAL-TIME MICROPHONE
                       ↓
               EMERGENCY / NORMAL
```

## 21. Execution Order

Run the project in this order:

### Dataset

``` text
1. import_ESC50.m
2. IMPORT_NOISE.m
3. Add Speech WAV files
```

### DSP demonstration

``` text
4. LOAD_AUDIO.m
5. PREPROCESSING.m
6. FFT.m
7. STFT.m
8. FEATURES.m
```

### Dataset creation

``` text
9. BUILD_DATASET.m
10. CHECK_DATASET.m
```

### Machine learning

``` text
11. TRAIN_TEST_SPLIT.m
12. SVM.m
13. EVALUATE.m
```

### Final application

``` text
14. REALTIME_DETECTOR.m
15. Add majority voting
16. Test with unseen sounds
```

## 22. Important Project Parameters

``` text
Sampling frequency       = 16 kHz
Band-pass range          = 100–7500 Hz
Filter                   = 4th-order Butterworth
Frame duration           = 25 ms
Frame overlap            = 50%
FFT size                 = 1024
Spectral rolloff         = 85%
Features per recording   = 10
Classes                  = 5
Emergency classes        = 3
Normal classes           = 2
```

## 23. What to Show in the Final Report

### Introduction

-   Motivation
-   Problem statement
-   Objectives
-   Scope

### DSP methodology

Show:

``` text
Original waveform
Filtered waveform
Filter frequency response
FFT spectrum
STFT spectrogram
Feature plots
```

### Dataset

Report:

``` text
Siren       40
Glass       40
BabyCry     40
Speech      40
Noise       40
Total      200
```

### Classification

Explain:

-   Feature normalization
-   SVM
-   Training/test split
-   Five-class prediction
-   Emergency/Normal decision

### Results

Include:

-   Accuracy
-   Precision
-   Recall
-   F1-score
-   Confusion matrix
-   Emergency/Normal performance

### Real-time system

Show:

``` text
Microphone
 ↓
DSP
 ↓
Feature extraction
 ↓
SVM
 ↓
Emergency/Normal
```

## 24. Key Point for the Viva/Presentation

This is primarily a **DSP project with machine learning as the final
classification stage**.

The important contribution is:

``` text
RAW AUDIO
   ↓
DIGITAL SIGNAL PROCESSING
   ↓
FILTERING
   ↓
FFT / STFT
   ↓
DSP FEATURE EXTRACTION
   ↓
SVM CLASSIFICATION
```

The SVM does not directly receive raw audio. It receives features
produced by the DSP pipeline.

## 25. Current Status

Completed:

``` text
Dataset import                    ✓
Emergency sound folders           ✓
Speech and Noise folders          ✓
Audio loading                     ✓
Preprocessing                     ✓
FFT                               ✓
STFT                              ✓
Feature extraction                ✓
New recording-level dataset code ✓
Dataset checking code             ✓
Train/test split code             ✓
SVM code                          ✓
Evaluation code                   ✓
```

Next:

``` text
RUN BUILD_DATASET.m
       ↓
RUN CHECK_DATASET.m
       ↓
Verify:
200 recordings
10 features
5 classes
       ↓
RUN TRAIN_TEST_SPLIT.m
       ↓
RUN SVM.m
       ↓
RUN EVALUATE.m
       ↓
Build REALTIME_DETECTOR.m
```

Do not skip `CHECK_DATASET.m`. Verify the dataset before training the
SVM.
