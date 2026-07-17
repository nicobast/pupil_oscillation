# pupil_oscillation
project: Pupil Oscillation Analysis

A project to benchmark a pupillary hippus/oscillation workflow. This project processes eye-tracking data from an auditory oddball task to analyze pupil oscillations and compute power spectral density (PSD) in different frequency bands.

## Overview

This workflow:
1. Reads and merges raw eye-tracking (ET) data with task data from an auditory oddball paradigm
2. Preprocesses pupil diameter signals (artifact removal, filtering, smoothing)
3. Splits signals into chunks for frequency analysis
4. Computes Fast Fourier Transform (FFT) and Power Spectral Density (PSD)
5. Calculates relative power in different frequency bands (noise, low, mid, high)
6. Compares hippus power across different experimental blocks

## Project Structure

```
pupil_oscillation/
├── code/
│   ├── packages.R                         # Package installation and loading
│   ├── 01_sample_data_from_raw.R         # Reads and merges ET & task data
│   ├── 02_preprocessing.R                # Preprocessing pipeline (single subject demo)
│   ├── fun_hippus_power.r                # Function for hippus power analysis
│   ├── compare_hippus_power.r            # Apply hippus power analysis across subjects
│   └── exclude_size_outlier_rolling.R    # Custom size outlier detection function
├── data/
│   ├── df_list_sample.rds
│   ├── df_list_sample1.rds
│   ├── df_list_sample2.rds
│   └── df_list_sample3.rds
└── README.md
```

## Dependencies

The project requires the following R packages:

### CRAN Packages
- `signal` - For digital filtering and signal processing
- `tuneR` - For audio signal processing
- `seewave` - For spectral analysis
- `zoo` - For time series operations
- `remotes` - For installing packages from GitHub
- `plyr`, `dplyr` - For data manipulation
- `pbapply` - For progress bar in apply functions

### GitHub Packages
- `PupilPreprocess` (from `nicobast/PupilPreprocess`) - Custom pupil preprocessing package

### Bioconductor Packages
- `rhdf5` - For reading HDF5 eye-tracking data files

Run the following to install all dependencies:
```r
source("code/packages.R")
```

## Workflow

### 1. Data Sampling and Merging (`01_sample_data_from_raw.R`)

This script:
- Reads raw eye-tracking data from HDF5 files
- Reads task data from CSV files
- Extracts subject IDs from filenames
- Matches ET and task data by subject ID
- Merges datasets based on timestamps (assigns each eye-tracking sample to a trial)
- Saves a sample of subjects as RDS files

**Key Parameters:**
- `number_of_files = 30` - Number of subjects to sample
- Random seed for reproducibility

### 2. Preprocessing Pipeline (`02_preprocessing.R`)

This script demonstrates the preprocessing steps for a single subject:

1. **Invalid Value Exclusion** - Removes negative pupil diameters and other invalid values
2. **Blink Correction** - Detects and corrects blink artifacts
3. **Speed Outlier Exclusion** - Removes samples with unrealistic velocity changes
4. **Size Outlier Exclusion** - Removes samples with unrealistic size values (using rolling median)
5. **Savitzky-Golay Filtering** - Smooths the signal (p=3, n=21)
6. **Low-pass Butterworth Filter** - Removes high-frequency noise (cutoff at 10 Hz, 4th order)

### 3. Frequency Analysis (`fun_hippus_power.r`)

The `func_hippus_power()` function:
- Applies the full preprocessing pipeline to pupil data
- Splits the filtered signal into 2 chunks
- Detrends and normalizes each chunk (z-scoring)
- Computes FFT and Power Spectral Density for each chunk
- Calculates relative power in frequency bands:
  - **Noise**: 0 to `frequency_noise_threshold` Hz
  - **Low Power**: `frequency_noise_threshold` to 0.04 Hz
  - **Mid Power**: 0.04 to 0.15 Hz
  - **High Power**: 0.15 to 0.4 Hz
- Returns a data frame with power metrics for each chunk plus average

**Frequency Bands:**
- Hippus oscillations typically occur in the 0.05-0.4 Hz range
- Signal-to-noise ratio is calculated as: `(high_power + mid_power) / noise`

### 4. Comparison Across Blocks (`compare_hippus_power.r`)

This script:
- Loads multiple subjects from RDS files
- Applies `func_hippus_power()` to each subject across 4 different blocks
- Blocks analyzed: 3, 5, 10, 12
- Computes hippus power (SNR) for each block
- Aggregates results for comparison across conditions

## Usage

### Basic Workflow

```r
# Load packages
source("code/packages.R")

# Option 1: Sample new data from raw files
source("code/01_sample_data_from_raw.R")

# Option 2: Use existing sample data
df_list <- readRDS("data/df_list_sample1.rds")

# Analyze a single subject (example from second block)
source("code/fun_hippus_power.r")
data <- df_list[[1]]
data_block <- data[data$block == 3, ]
power_results <- func_hippus_power(data_block)
print(power_results)
```

### Batch Analysis Across Subjects

```r
# Run analysis across all subjects and blocks
source("code/compare_hippus_power.r")

# Results are stored in:
# - power_hippus_first_block
# - power_hippus_second_block
# - power_hippus_third_block
# - power_hippus_fourth_block
```

## Key Features

### Signal Processing
- **Artifact Removal**: Invalid values, blink artifacts, speed/size outliers
- **Smoothing**: Savitzky-Golay filter for noise reduction
- **Filtering**: Zero-phase low-pass Butterworth filter to remove high-frequency noise
- **Edge Artifact Minimization**: Signal padding before filtering

### Frequency Analysis
- **Chunk-based Analysis**: Splits signals into segments for better frequency resolution
- **FFT-based PSD**: Computes power spectrum using Fast Fourier Transform
- **Multi-band Power**: Calculates relative power across different frequency ranges

### Custom Functions
- `exclude_size_outlier_rolling()` - Two-pass rolling median outlier detection
- `func_hippus_power()` - Complete preprocessing and frequency analysis pipeline

## Data Format

### Input Data
- **Eye-tracking**: HDF5 files containing `BinocularEyeSampleEvent` with `logged_time`, `left_pupil_measure1`, `right_pupil_measure1`
- **Task**: CSV files with trial information and timestamps

### Output Data
- **RDS Files**: List of data frames, one per subject, with merged ET and task data
- **Power Metrics**: Data frame with relative power values for noise, low, mid, and high frequency bands

## Author

**Nico Bast**  
Email: nbast@med.uni-frankfurt.de

## Notes

- The project uses data from an auditory oddball task (Studie_SEGA)
- Sample data files are generated with different random seeds (111, 444, 666, 123)
- Chunking strategy may need adjustment based on signal length and frequency resolution requirements
- Frequency noise threshold is dynamically calculated based on chunk duration

## TODO

- Define manipulation checks and validity metrics for hippus detection
- Expand validation across more participants
- Optimize chunking strategy for different signal lengths
- Add automated quality control checksto benchmark a pupillary hippus/oscillation workflow

