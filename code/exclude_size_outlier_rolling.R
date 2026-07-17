#exclude_size_outlier_rolling.R

exclude_size_outlier_rolling <- function(signal, timestamp,
                                         MAD_constant = 3,
                                         smooth_length = 0.150) {
  signal <- as.numeric(signal)
  timestamp <- as.numeric(timestamp)

  if (length(signal) != length(timestamp)) {
    stop("signal and timestamp must have the same length")
  }

  if (length(signal) == 0) {
    return(signal)
  }

  dt <- median(diff(timestamp), na.rm = TRUE)
  if (!is.finite(dt) || dt <= 0) {
    return(signal)
  }

  # Window size in samples
  smooth.size <- round(smooth_length / dt)
  smooth.size <- max(3, smooth.size)
  if (smooth.size %% 2 == 0) {
    smooth.size <- smooth.size + 1
  }

  # Fill missing values once
  signal_filled <- zoo::na.approx(signal, x = timestamp, na.rm = FALSE, rule = 2)

  # Helper: rolling median with centered window
  rolling_median <- function(x, k) {
    n <- length(x)
    if (n < k) {
      return(rep(stats::median(x, na.rm = TRUE), n))
    }

    half <- floor(k / 2)
    out <- numeric(n)

    for (i in seq_len(n)) {
      lo <- max(1, i - half)
      hi <- min(n, i + half)
      out[i] <- stats::median(x[lo:hi], na.rm = TRUE)
    }

    out
  }

  # First pass
  trend1 <- rolling_median(signal_filled, smooth.size)
  mad1 <- median(abs(signal_filled - trend1), na.rm = TRUE)

  if (!is.finite(mad1) || mad1 <= 0) {
    return(signal)
  }

  threshold1 <- MAD_constant * mad1
  signal_pass1 <- signal
  outlier_idx1 <- which((signal_pass1 > trend1 + threshold1) |
                          (signal_pass1 < trend1 - threshold1))
  signal_pass1[outlier_idx1] <- NA

  # Second pass
  signal_filled2 <- zoo::na.approx(signal_pass1, x = timestamp, na.rm = FALSE, rule = 2)
  trend2 <- rolling_median(signal_filled2, smooth.size)
  mad2 <- median(abs(signal_filled2 - trend2), na.rm = TRUE)

  if (!is.finite(mad2) || mad2 <= 0) {
    return(signal_pass1)
  }

  threshold2 <- MAD_constant * mad2
  signal_pass2 <- signal
  outlier_idx2 <- which((signal_pass2 > trend2 + threshold2) |
                          (signal_pass2 < trend2 - threshold2))
  signal_pass2[outlier_idx2] <- NA

  signal_pass2
}