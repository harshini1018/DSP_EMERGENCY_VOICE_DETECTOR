# DSP-Based Emergency Sound Detector

A MATLAB-based audio classification system that uses Digital Signal Processing (DSP) techniques and a custom multiclass Support Vector Machine (SVM) to identify emergency-related sounds.

The system analyses audio recordings, extracts meaningful time-domain and frequency-domain features, and classifies sounds into four categories: **Siren, Glass, Noise, and Speech**.

---

## Project Overview

The **DSP-Based Emergency Sound Detector** is a software-based project developed using MATLAB as part of a Digital Signal Processing course.

The system processes audio recordings through a series of DSP operations, including preprocessing, digital filtering, framing, FFT, STFT, and feature extraction. The extracted features are converted into a fixed-length numerical vector and passed to a custom multiclass linear SVM classifier.

The system identifies:

- **Siren** – Emergency-related sound
- **Glass** – Emergency-related sound
- **Noise** – Normal environmental sound
- **Speech** – Normal human speech

The project also includes a MATLAB-based real-time microphone detection interface.

## Objectives

- Process audio signals using MATLAB.
- Apply preprocessing and digital filtering techniques.
- Analyse audio in time and frequency domains.
- Implement FFT and STFT analysis.
- Extract meaningful DSP features from audio frames.
- Construct fixed-length feature vectors.
- Implement a custom multiclass linear SVM classifier.
- Evaluate classification performance using standard metrics.
- Demonstrate sound classification through real-time microphone input.

---

## System Architecture

The complete processing pipeline is:

```text
             Audio Dataset
                   |
                   v
              Audio Loading
                   |
                   v
              Preprocessing
        (Mono, DC Removal, Resampling,
              Normalization)
                   |
                   v
           Butterworth Band-Pass
                Filtering
             (100–7500 Hz)
                   |
                   v
             Framing & Windowing
          (25 ms, 50% Overlap,
              Hamming Window)
                   |
                   v
              FFT / STFT
                Analysis
                   |
                   v
             Feature Extraction
       (Energy, ZCR, Centroid,
         Bandwidth, Roll-Off)
                   |
                   v
          Feature Summarization
          (Mean + Standard Deviation)
                   |
                   v
          10-Dimensional Feature Vector
                   |
                   v
          Custom Multiclass Linear SVM
                   |
                   v
             Sound Classification
                   |
          +--------+--------+
          |        |        |
        Siren    Glass   Noise / Speech
```

---

## Technologies Used

| Component | Technology |
|---|---|
| Programming Language | MATLAB |
| Signal Processing | Digital Signal Processing |
| Audio Format | WAV |
| Dataset | ESC-50 and selected audio recordings |
| Frequency Analysis | FFT and STFT |
| Digital Filter | Butterworth Band-Pass Filter |
| Windowing | Hamming Window |
| Classification | Custom Linear SVM |
| Evaluation | Confusion Matrix, Accuracy, Precision, Recall, F1-score |
| Interface | MATLAB Real-Time Microphone Detector |

---

## Dataset

The project uses audio recordings organised into four sound categories:

| Class | Category |
|---|---|
| Siren | Emergency |
| Glass | Emergency |
| Noise | Normal |
| Speech | Normal |

The final dataset contains **161 audio recordings**.

### Dataset Distribution

| Sound Class | Recordings |
|---|---:|
| Glass | 40 |
| Noise | 41 |
| Siren | 40 |
| Speech | 40 |
| **Total** | **161** |

The ESC-50 environmental sound dataset is used as a primary audio source, with recordings organised into class-wise folders for processing.

---

## DSP Methodology

### 1. Audio Loading

- Audio recordings are loaded using MATLAB's `audioread`.
- Stereo recordings are converted into mono.
- The sampling frequency and recording duration are identified.

### 2. Preprocessing

The audio signals undergo:

- DC-offset removal.
- Resampling to a common sampling frequency.
- Amplitude normalization.
- Mono conversion where required.

### 3. Digital Band-Pass Filtering

A fourth-order Butterworth band-pass filter is applied.

**Filter parameters:**
- Lower cutoff frequency: 100 Hz
- Upper cutoff frequency: 7500 Hz
- Sampling frequency: 16 kHz

MATLAB's `filtfilt` function is used for forward-reverse filtering to reduce phase distortion.

### 4. Framing and Windowing

The audio is divided into short overlapping frames.

| Parameter | Value |
|---|---:|
| Sampling Frequency | 16 kHz |
| Frame Duration | 25 ms |
| Frame Length | 400 samples |
| Overlap | 50% |
| Hop Length | 200 samples |
| Window | Hamming |
| FFT Size | 1024 points |

The Hamming window is applied to each frame to reduce spectral leakage.

### 5. FFT Analysis

The Fast Fourier Transform converts each windowed frame from the time domain into the frequency domain.

It helps identify the frequency components and their relative magnitudes.

### 6. STFT Analysis

The Short-Time Fourier Transform performs frequency analysis over successive overlapping frames.

The resulting spectrogram illustrates how the frequency content changes over time.

---

## Feature Extraction

Five DSP features are calculated for every audio frame.

| Feature | Description |
|---|---|
| Short-Time Energy | Measures the signal energy in a frame. |
| Zero-Crossing Rate (ZCR) | Measures how frequently the waveform crosses zero. |
| Spectral Centroid | Represents the spectral centre or brightness. |
| Spectral Bandwidth | Measures the spread of frequency components. |
| Spectral Roll-Off | Represents the frequency below which a specified proportion of spectral magnitude is concentrated. |

### Feature Vector Formation

Since recordings may contain different numbers of frames, the project calculates the mean and standard deviation of each feature across all frames.

This produces a fixed-length **10-dimensional feature vector** for every recording.

```text
Feature Vector =

[Mean Energy,
 Std Energy,
 Mean ZCR,
 Std ZCR,
 Mean Centroid,
 Std Centroid,
 Mean Bandwidth,
 Std Bandwidth,
 Mean Roll-Off,
 Std Roll-Off]
```

The resulting feature vectors are stored along with their corresponding class labels.

---

## Classification Using Custom SVM

The project implements a custom multiclass linear Support Vector Machine classifier.

### Classification approach

- One-vs-Rest (OvR) multiclass classification.
- Linear SVM decision functions.
- Squared hinge loss.
- Gradient-descent-based training.
- Feature standardization using training-set statistics.

Each binary classifier distinguishes one sound class from the remaining classes. The classifier with the strongest decision score determines the predicted category.

### Training and Testing Split

The dataset is divided at the recording level.

| Dataset | Percentage | Recordings |
|---|---:|---:|
| Training | 70% | 113 |
| Testing | 30% | 48 |
| **Total** | **100%** | **161** |

A fixed random seed (`rng(42)`) is used to make the split reproducible.

Recording-level splitting ensures that frames from the same recording are not distributed across both training and testing sets.

---

## Performance Evaluation

The classifier is evaluated using the held-out testing dataset.

### Overall Results

| Evaluation Metric | Result |
|---|---:|
| Accuracy | **91.67%** |
| Macro Precision | **91.85%** |
| Macro Recall | **91.67%** |
| Macro F1-score | **91.45%** |

### Class-wise F1-score

| Sound Class | F1-score |
|---|---:|
| Glass | 91.67% |
| Noise | 81.82% |
| Siren | 92.31% |
| Speech | 100.00% |

A confusion matrix is also generated to examine correct classifications and misclassifications across the four sound classes.

*These are the reported results for the current held-out test set.*

---

## Real-Time Sound Detection

The project includes a MATLAB real-time microphone detector that uses the trained SVM model.

### Working

1. Captures audio through a microphone.
2. Processes incoming audio in short chunks.
3. Applies preprocessing and filtering.
4. Extracts the same five DSP features.
5. Forms a 10-dimensional feature vector.
6. Standardizes the features using the saved training parameters.
7. Predicts the sound class using the trained SVM.
8. Displays the prediction through the MATLAB interface.

Recent predictions are combined using majority voting to provide more stable displayed classifications.

The system identifies Siren and Glass as emergency-related categories, while Noise and Speech are treated as normal categories.

---

## Project Files

The MATLAB project is organised into separate scripts for each processing stage.

| File | Purpose |
|---|---|
| `LOAD_AUDIO.m` | Loads and displays audio recordings. |
| `PREPROCESSING.m` | Performs audio preprocessing and filtering. |
| `FFT.m` | Performs FFT analysis. |
| `STFT.m` | Generates STFT and spectrogram outputs. |
| `FEATURES.m` | Extracts the five DSP features. |
| `import_ESC50.m` | Imports and organises ESC-50 recordings. |
| `IMPORT_NOISE.m` | Imports noise recordings. |
| `BUILD_DATASET.m` | Builds the feature dataset. |
| `CHECK_DATASET.m` | Verifies dataset structure and feature values. |
| `train.m` | Trains the classification model. |
| `SVM.m` | Implements custom SVM classification. |
| `EVALUATE.m` | Evaluates the trained classifier. |
| `REALTIME_DETECTOR.m` | Runs the real-time microphone detector. |

### Generated MATLAB Files

| File | Description |
|---|---|
| `featureDataset.mat` | Extracted feature vectors and class labels. |
| `splitDataset.mat` | Training and testing data split. |
| `trainedModel.mat` | Saved trained SVM model and normalization parameters. |
| `evaluationResults.mat` | Saved classification evaluation results. |

---

## Installation and Setup

### Requirements

- MATLAB
- Audio Toolbox or compatible MATLAB audio functionality as required by the scripts.
- WAV audio recordings organised into the required class-wise folders.
- Microphone access for real-time detection.

### Step 1: Clone the Repository

```bash
git clone <YOUR_GITHUB_REPOSITORY_URL>
```

### Step 2: Open MATLAB

Open MATLAB and navigate to the downloaded project folder.

### Step 3: Prepare the Dataset

Place the required audio recordings in the expected dataset folders.

Ensure the dataset paths in the import scripts match your local directory structure.

### Step 4: Run the Processing Pipeline

Run the scripts in the appropriate order:

```matlab
LOAD_AUDIO
PREPROCESSING
FFT
STFT
FEATURES
```

### Step 5: Build and Verify the Dataset

```matlab
import_ESC50
IMPORT_NOISE
BUILD_DATASET
CHECK_DATASET
```

Ensure that the final four classes are available and the feature dataset contains valid values.

### Step 6: Train the Model

```matlab
train
SVM
```

The trained model is saved for later evaluation and real-time use.

### Step 7: Evaluate the Model

```matlab
EVALUATE
```

This generates classification results and performance metrics.

### Step 8: Run Real-Time Detection

```matlab
REALTIME_DETECTOR
```

Allow MATLAB to access the microphone and speak or play an audio recording near the microphone to test the detector.

*Note: Run scripts according to their actual dependencies and ensure that the required `.mat` files have been generated before running evaluation or real-time detection.*

---

## Limitations

- The dataset contains a limited number of recordings.
- Background noise may affect classification.
- Microphone quality and recording distance can influence predictions.
- Similar sound characteristics may cause misclassification.
- Real-time performance depends on audio capture and processing conditions.
- The system is an academic prototype and is not a certified safety-monitoring device.

## Future Improvements

- Expand the dataset with more diverse recordings.
- Improve background-noise reduction.
- Explore additional DSP features.
- Compare the custom SVM with other classification algorithms.
- Optimise real-time processing speed.
- Test the system using independent real-world recordings.

---

## Conclusion

The DSP-Based Emergency Sound Detector demonstrates how digital signal processing and machine learning can be combined for environmental audio classification.

By using preprocessing, Butterworth filtering, framing, FFT, STFT, five DSP features and a custom multiclass linear SVM, the project converts audio recordings into meaningful numerical representations and classifies them into four sound categories.

The project also demonstrates a real-time microphone-based classification interface, providing an end-to-end MATLAB implementation of the proposed system.

---

## References

1. K. J. Piczak, "ESC: Dataset for Environmental Sound Classification," Proceedings of the 23rd ACM International Conference on Multimedia, 2015.
2. MathWorks, MATLAB `audioread` Documentation.
3. MathWorks, MATLAB `spectrogram` Documentation.
4. MathWorks, MATLAB Signal Processing Documentation.

---

**DSP Course Project Team**

- Siri Chandana
- Amulya
- Harshini
- Savita 

**Course:** Digital Signal Processing  
**Software Platform:** MATLAB  
**Project:** DSP-Based Emergency Sound Detector
