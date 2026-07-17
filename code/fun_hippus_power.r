#code/fun_hippus_power.r
func_hippus_power<-function(data,signalname='left_pupil_measure1',timestampname='logged_time'){

#description:
#' Compute Hippus‑related pupil‑power metrics for a participant
#'
#' This high‑level wrapper runs the complete preprocessing‑and‑analysis
#' pipeline on a single participant’s pupil‑diameter time‑series.
#'
#' **Main steps**  
#' 1. **Extract raw data** – selects the pupil signal (`signalname`) and its
#'    timestamps (`timestampname`).  
#' 2. **Pre‑processing** – removes invalid values, corrects blinks,
#'    excludes speed and size outliers, and smooths the signal with a
#'    Savitzky‑Golay filter. NA‑percentages are reported after each step.  
#' 3. **Resampling** – builds a regular time vector (linear interpolation) and
#'    applies a zero‑phase low‑pass Butterworth filter while minimizing edge
#'    artifacts.  
#' 4. **Chunking** – splits the filtered signal into two equal‑length chunks
#'    (or a smaller last chunk) and discards chunks shorter than 1000 samples.  
#' 5. **Detrending & normalization** – removes the mean of each chunk and
#'    scales it to zero mean & unit variance. All chunks are truncated to the
#'    length of the shortest chunk so that FFTs have identical lengths.  
#' 6. **Frequency analysis** – computes the FFT of each chunk, converts it to a
#'    power‑spectral density (PSD), and averages the PSD across chunks.  
#' 7. **Power band extraction** – integrates the PSD over four frequency bands:  
#'    *noise* (0 – `frequency_noise_threshold`), *low* (0.04 – 0.15 Hz),  
#'    *mid* (0.15 – 0.4 Hz) and *high* (above 0.4 Hz). Relative power for each
#'    band is returned.  
#' 8. **Output** – a data frame whose first row contains the participant‑wide
#'    average band powers and subsequent rows contain the per‑chunk band powers.
#'
#' @param data A data frame containing at least an `id` column, the pupil
#'   signal column (default `left_pupil_measure1`) and a timestamp column
#'   (default `logged_time`).
#' @param signalname Name of the column that holds the pupil‑diameter signal.
#' @param timestampname Name of the column that holds the time stamps (in
#'   the same units as the original recording).
#' @return A data frame with columns `noise`, `low_power`, `mid_power`,
#'   `high_power` (relative power values). The first row corresponds to the
#'   participant‑wide average, and additional rows correspond to each chunk.
#' @examples
#' # Assuming `df` holds one participant’s data:
#' power_df <- func_hippus_power(df)
#' head(power_df)
#'
#' @export

participant_id<-unique(data$id)
signal<-data[[signalname]]
timestamp<-data[[timestampname]]

#convert to simple numeric vector
signal <- as.numeric(signal)
timestamp <- as.numeric(timestamp)

## preprocesing steps ####

#exclude invalid values (e.g., negative pupil diameters)
total_samples <- length(signal)
cat('initial_NA_pct =', sprintf('%.4f%%', 100 * sum(is.na(signal)) / total_samples), '\n')
signal <- PupilPreprocess::exclude_invalid(signal)
cat('after_exclude_invalid_NA_pct =', sprintf('%.4f%%', 100 * sum(is.na(signal)) / total_samples), '\n')

#blink correction
signal <- PupilPreprocess::blink_correction(signal)
cat('after_blink_correction_NA_pct =', sprintf('%.4f%%', 100 * sum(is.na(signal)) / total_samples), '\n')

#exclude speed outliers
signal <- PupilPreprocess::exclude_speed_outlier(signal, timestamp)
cat('after_exclude_speed_outlier_NA_pct =', sprintf('%.4f%%', 100 * sum(is.na(signal)) / total_samples), '\n')

#exclude size outliers
signal <- PupilPreprocess::exclude_size_outlier(signal, timestamp)
#signal <- exclude_size_outlier_rolling(signal, timestamp)
cat('after_exclude_size_outlier_NA_pct =', sprintf('%.4f%%', 100 * sum(is.na(signal)) / total_samples), '\n')

# Smooth the signal with a Savitzky-Golay filter
# Helper to compute safe percentages (avoids NaN/Inf)
calc_pct <- function(num, den) {
  if (den == 0) return(0)
  round(100 * num / den, 2)
}

# ---- NA‑percentage reporting (replace the original cat() calls) ----
initial_NA_pct               <- calc_pct(sum(is.na(signal)), length(signal))
cat('initial_NA_pct =', sprintf('%.4f%%', initial_NA_pct), '\n')

signal <- PupilPreprocess::exclude_invalid(signal)
after_exclude_invalid_NA_pct  <- calc_pct(sum(is.na(signal)), length(signal))
cat('after_exclude_invalid_NA_pct =', sprintf('%.4f%%', after_exclude_invalid_NA_pct), '\n')

signal <- PupilPreprocess::blink_correction(signal)
after_blink_correction_NA_pct <- calc_pct(sum(is.na(signal)), length(signal))
cat('after_blink_correction_NA_pct =', sprintf('%.4f%%', after_blink_correction_NA_pct), '\n')

signal <- PupilPreprocess::exclude_speed_outlier(signal, timestamp)
after_exclude_speed_outlier_NA_pct <- calc_pct(sum(is.na(signal)), length(signal))
cat('after_exclude_speed_outlier_NA_pct =', sprintf('%.4f%%', after_exclude_speed_outlier_NA_pct), '\n')

signal <- PupilPreprocess::exclude_size_outlier(signal, timestamp)
after_exclude_size_outlier_NA_pct <- calc_pct(sum(is.na(signal)), length(signal))
cat('after_exclude_size_outlier_NA_pct =', sprintf('%.4f%%', after_exclude_size_outlier_NA_pct), '\n')

# -----------------------------------------------------------------
#  Build valid vectors
# -----------------------------------------------------------------
valid_idx   <- which(!is.na(signal) & !is.na(timestamp))
time_valid  <- timestamp[valid_idx]
signal_valid<- signal[valid_idx]

# ---- Early‑exit if nothing left after exclusions ----
if (length(time_valid) == 0L) {
  message(sprintf(
    "Participant %s – no valid time points left after exclusions. Skipping.",
    participant_id
  ))
  return(data.frame(
    participant = participant_id,
    power       = numeric(0),
    hippus      = numeric(0)   # adjust column names as needed
  ))
}

# -----------------------------------------------------------------
#  Safe regular time vector (replaces the original seq call)
# -----------------------------------------------------------------
dt <- median(diff(time_valid))
seq_start <- time_valid[1L]
seq_end   <- time_valid[length(time_valid)]

if (any(is.na(c(seq_start, seq_end))) || any(is.infinite(c(seq_start, seq_end)))) {
  warning(sprintf(
    "Participant %s – time bounds contain NA/Inf. Skipping.",
    participant_id
  ))
  return(data.frame())
}

regular_time   <- seq(from = seq_start, to = seq_end, by = dt)
regular_signal <- approx(x = time_valid,
                         y = signal_valid,
                         xout = regular_time,
                         method = "linear",
                         rule = 2)$y
smoothed_signal <- sgolayfilt(regular_signal, p = 3, n = 21)
cat('after_sgolay_filter_NA_pct =', sprintf('%.4f%%', 100 * sum(is.na(smoothed_signal)) / total_samples), '\n')

# function to minimize edge artifacts that would occur for zero-phase filtering (filtfilt) by padding the signal with its edge values before filtering and then removing the padding afterward
minimize_edge_artifacts <- function(signal, filter_coeffs, pad_factor = 0.1) {
  # Calculate padding length
  pad_length <- ceiling(length(signal) * pad_factor)
  pad_length <- max(1, pad_length)
  
  # Create symmetric padding using signal mean or edge values
  left_pad <- rep(signal[1], pad_length)
  right_pad <- rep(signal[length(signal)], pad_length)
  
  # Pad the signal
  padded_signal <- c(left_pad, signal, right_pad)
  
  # Apply zero-phase filtering
  filtered_padded <- filtfilt(filter_coeffs, padded_signal)
  
  # Remove padding
  filtered_signal <- filtered_padded[(pad_length+1):(length(filtered_padded)-pad_length)]
  
  return(filtered_signal)
}

# Apply low-pass filter to remove high-frequency noise
low_pass_cutoff_Hz <- 10
sampling_rate <- 1/median(diff(timestamp))  # Change this to your actual sampling rate
cutoff_factor <- low_pass_cutoff_Hz / sampling_rate * 2 # proportion of Nyquist frequency
filter_coeffs <- butter(4, cutoff_factor, "low")  # 4th order, normalized cutoff
filtered_signal <- minimize_edge_artifacts(smoothed_signal, filter_coeffs)

#check the filtered signal
par(mfrow=c(3,1))
plot(signal, type="l", main="Original Signal")
plot(smoothed_signal, type="l", main="After Savitzky-Golay Smoothing")
plot(filtered_signal, type="l", main="After Filtering")
par(mfrow=c(1,1))

## splitting to normalized chunks ####
number_of_chunks <- 2
sampling_rate <- 1/median(diff(timestamp)) 
estimated_length <- length(filtered_signal) * median(diff(timestamp))
chunk_length <- estimated_length / number_of_chunks

#below this threshold, no power can be reliably detected
# (5 times the duration of a frequency cycle)
frequency_noise_threshold<-1/chunk_length*5

# Alternative approach that keeps all samples but makes the last chunk smaller
samples_per_chunk <- chunk_length * sampling_rate

# Total length of signal
total_samples <- length(filtered_signal)

# Split into chunks
chunks <- split(filtered_signal, ceiling(seq_along(filtered_signal) / samples_per_chunk))
chunks <- chunks[lapply(chunks, length) > 1000]

# Verify chunk sizes
chunk_sizes <- sapply(chunks, length)
print(paste("Chunk sizes:", paste(chunk_sizes, collapse = ", ")))
print(paste("Number of chunks:", length(chunks)))
## detrending and normalization chunks ####
chunk_means <- sapply(chunks, mean)
chunks_detrended <- mapply("-", chunks, chunk_means, SIMPLIFY = FALSE)
chunks_normalized <- lapply(chunks_detrended, scale)

# Truncate all chunks to the shortest one for consistent FFT length
min_length <- min(chunk_sizes)
chunks_normalized <- lapply(chunks_normalized, function(chunk) {
  if (length(chunk) > min_length) {
    chunk[1:min_length]
  } else {
    chunk
  }
})

# # histogram of normalized chunk values
# par(mfrow=c(length(chunks), 1))
# for (i in seq_along(chunks_normalized)) {
#   hist(chunks_normalized[[i]], xlim = c(-3, 3), breaks=30, main = paste0("Chunk ", i, " values"))
# }
# par(mfrow=c(1,1))

## final FFT/power spectrum ####

# Now proceed with FFT - fast fourier transform
# FFT: signal is decinstructed into frequency components
fft_results <- lapply(chunks_normalized, function(chunk) {
  fft_data <- fft(chunk)
  power_spectrum <- Mod(fft_data)^2
  power_spectrum <- power_spectrum[1:(length(power_spectrum)/2 + 1)]
  return(power_spectrum)
})

#check the filtered signal
par(mfrow=c(length(chunks),1))

for(i in 1:length(chunks)){
  plot(fft_results[[i]][1:50], type="l", main=paste0(i,". chunk"))
}
par(mfrow=c(1,1))

# Calculate average PSD
avg_psd <- rowMeans(do.call(cbind, fft_results))
# plot(avg_psd[1:50],type="l",)

# Get frequency axis
frequencies <- seq(0, low_pass_cutoff_Hz, length.out = length(fft_results[[1]]))
range(frequencies)

# Plot power spectrum
# plot(frequencies, avg_psd, type = "l", 
#      xlab = "Frequency (Hz)", ylab = "Power", 
#      main = "Average Power Spectral Density")

#calculate POWE 
fun_pupilpower<-function(data,frequencies){

noise <- sum(data[frequencies >= 0 & frequencies <= frequency_noise_threshold])
low_power <- sum(data[frequencies > frequency_noise_threshold & frequencies <= 0.04])
mid_power <- sum(data[frequencies > 0.04 & frequencies <= 0.15])
high_power <- sum(data[frequencies > 0.15])

# Relative power in each band
total_power <- sum(data)
relative_power <- c(noise = noise/total_power,
                  low_power = low_power/total_power,
                   mid_power = mid_power/total_power,
                   high_power = high_power/total_power)

return(relative_power)
}

avg_power<-fun_pupilpower(avg_psd,frequencies = frequencies)

chunks_power<-lapply(fft_results,fun_pupilpower,frequencies = frequencies)
power_compare<-do.call(rbind,chunks_power)
power_compare<-data.frame(rbind(avg_power,power_compare))

return(power_compare)
}
