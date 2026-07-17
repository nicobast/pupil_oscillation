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
│   ├── 02_extract_hippus_power.r         # Apply hippus power analysis across subjects and blocks
│   └── fun_hippus_power.r                # Function for hippus power analysis
├── data/
│   ├── df_list_sample.rds                # Sample data (seed 123)
│   ├── df_list_sample1.rds               # Sample data (seed 111, n=30)
│   ├── df_list_sample2.rds               # Sample data (seed 666)
│   └── df_list_sample3.rds               # Sample data (seed 444)
├── README.md
└── Rplots.pdf                            # Generated plots
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
- `psych` - For descriptive statistics

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
- Random seed for reproducibility (111 for df_list_sample1.rds)

### 2. Frequency Analysis (`fun_hippus_power.r`)

The `func_hippus_power()` function:
- Applies the full preprocessing pipeline to pupil data
- Splits the filtered signal into 2 chunks
- Detrends and normalizes each chunk (z-scoring)
- Computes FFT and Power Spectral Density for each chunk
- Calculates relative power in frequency bands:
  - **Noise**: 0 to `frequency_noise_threshold` Hz
  - **Low Power**: `frequency_noise_threshold` to 0.04 Hz
  - **Mid Power**: 0.04 to 0.15 Hz
  - **High Power**: >0.15Hz up to 10Hz
- Returns a data frame with power metrics for each chunk plus average

**Frequency Bands:**
- Hippus oscillations typically occur in the 0.05-0.4 Hz range
- Signal-to-noise ratio is calculated as: `(high_power + mid_power) / noise`

### 3. Comparison Across Blocks (`02_extract_hippus_power.r`)

This script:
- Loads multiple subjects from RDS files
- Applies `func_hippus_power()` to each subject across 4 different blocks
- Blocks analyzed: 3, 5, 10, 12
- Computes hippus power (SNR) for each block
- Aggregates results for comparison across conditions
- Calculates descriptive statistics (mean, SD) for each block using `psych::describe()`

**Utility Function:** `extract_power_by_block()` - Runs `func_hippus_power` for a selected block across all participants

## Usage

### Basic Workflow

```r
# Load packages
source("code/packages.R")

# Option 1: Sample new data from raw files (requires access to network paths)
source("code/01_sample_data_from_raw.R")

# Option 2: Use existing sample data
df_list <- readRDS("data/df_list_sample1.rds")

# Analyze a single subject (example from block 3)
source("code/fun_hippus_power.r")
data <- df_list[[1]]
data_block <- data[data$block_counter == 3, ]
power_results <- func_hippus_power(data_block)
print(power_results)
```

### Batch Analysis Across Subjects and Blocks

```r
# Run analysis across all subjects and blocks
source("code/02_extract_hippus_power.r")

# Results are stored in:
# - power_hippus_first_block    (block 3)
# - power_hippus_second_block   (block 5)
# - power_hippus_third_block    (block 10)
# - power_hippus_fourth_block   (block 12)

# Calculate descriptive statistics
psych::describe(unlist(power_hippus_fourth_block))
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
- **Signal-to-Noise Ratio**: Compares mid+high frequency power to noise

### Custom Functions
- `func_hippus_power()` - Complete preprocessing and frequency analysis pipeline
- `extract_power_by_block()` - Batch processing utility for analyzing multiple subjects by block

### Data Processing Features
- **Progress Monitoring**: Real-time progress tracking during data loading and analysis
- **Error Handling**: Robust error handling for HDF5 file reading
- **Memory Efficiency**: Uses list-based processing for large datasets
- **Reproducibility**: Random seeds for consistent data sampling

## Data Format

### Input Data
- **Eye-tracking**: HDF5 files containing `BinocularEyeSampleEvent` with:
  - `logged_time` - Timestamp for each eye-tracking sample
  - `left_pupil_measure1` - Left pupil diameter
  - `right_pupil_measure1` - Right pupil diameter
- **Task**: CSV files with trial information including:
  - `timestamp_exp` - Trial start timestamp
  - `block_counter` - Block number
  - Trial-level variables (`.thisRepN`, `.thisTrialN`, `stimulus_duration`, etc.)

### Output Data
- **RDS Files**: List of data frames, one per subject, with merged ET and task data
- **Power Metrics**: Data frame with relative power values for:
  - `noise` - Power in noise frequency band
  - `low_power` - Power in low frequency band
  - `mid_power` - Power in mid frequency band (0.04-0.15 Hz)
  - `high_power` - Power in high frequency band (0.15-0.4 Hz)

## Experimental Design

The analysis is performed on data from an auditory oddball task (Studie_SEGA):
- **Blocks Analyzed**: 3, 5, 10, 12
- **Sample Size**: 30 subjects (for df_list_sample1.rds)
- **Multiple Random Seeds**: 111, 123, 444, 666 for different sample subsets

## Analysis Output

The hippus power analysis outputs:
1. **Individual Subject Results**: Power metrics for each chunk (2 chunks per subject)
2. **Block-level Aggregates**: Hippus power (SNR) for each block
3. **Descriptive Statistics**: Mean, SD, and other statistics across participants

Example output includes:
```r
mean(unlist(power_hippus_first_block))   # Average SNR for block 3
sd(unlist(power_hippus_first_block))     # SD of SNR for block 3
psych::describe(unlist(power_hippus_fourth_block))  # Full descriptive stats
```

## Author

**Nico Bast**  
Email: nbast@med.uni-frankfurt.de

## Notes

- The project uses data from an auditory oddball task (Studie_SEGA)
- Raw data paths are network-specific and may require VPN/access to the Frankfurt network
- Sample data files are generated with different random seeds (111, 444, 666, 123)
- df_list_sample1.rds uses seed 111 with n=30 subjects
- Chunking strategy may need adjustment based on signal length and frequency resolution requirements
- Frequency noise threshold is dynamically calculated based on chunk duration
- Baseline trials (baseline_trial_counter == "6") include all data from trial start onward

## TODO

- Define manipulation checks and validity metrics for hippus detection
- Expand validation across more participants
- Optimize chunking strategy for different signal lengths
- Add automated quality control checks
- Document preprocessing parameters in more detail
- Create visualization functions for power spectra