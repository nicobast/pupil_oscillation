# ===========================================================
# Script purpose: Read raw data from the ET and task data folder, merge them and save a sample of 5 subjects to the data folder
# Author: Nico Bast
# Date Created: `r paste(Sys.Date())`
# Email: nbast@med.uni-frankfurt.de
# ===========================================================

## SETUP ####

#required packages
if (!requireNamespace("BiocManager", quietly = TRUE))
  install.packages("BiocManager")
if (!requireNamespace("rhdf5", quietly = TRUE))
  BiocManager::install("rhdf5")
library(rhdf5, warn.conflicts = FALSE) # read hdf files
library(pbapply) # progress bar for lapply

#paths
pupil_path <- "\\\\192.168.88.212\\daten\\KJP_Studien\\Studie_SEGA\\5_Versuchsdaten\\ET-Daten\\Auditory Oddball"
task_data_path <- "\\\\192.168.88.212\\daten\\KJP_Studien\\Studie_SEGA\\5_Versuchsdaten\\Task Auditory Oddball"

## READ PUPIL DATA ####

#list all pupil data files in the directory
data_files_et <- list.files(
  path = pupil_path,
  pattern = "\\.hdf5$",
  full.names = TRUE
)

# use function: extracts subject ID for file naming
extract_ids <- function(filename) {
  match <- regmatches(basename(filename),
                      regexpr("[0-9]{1,3}_",
                              basename(filename)))
  gsub("_", "", match)}


# read sample data
set.seed(444)  # For reproducible results
selected_files <- sample(data_files_et, size = min(5, length(data_files_et)), replace = FALSE)


#create empty list and assign names to the list based on the extracted IDs
list_et_data <- vector("list", length(selected_files))
names(list_et_data) <- sapply(selected_files, extract_ids)
    
# read data from hdf5 files and store in a list, with error handling for files that can't be read
for (i in seq_along(selected_files)) {
  cat("Now reading:", selected_files[i], "\n")
  # Error handling in case some files still can't be read
  tryCatch({
    list_et_data[[i]] <- h5read(
      file = selected_files[i],
      name = "data_collection/events/eyetracker/BinocularEyeSampleEvent"
    )
  }, error = function(e) {
    warning(sprintf("Failed to read file: %s\nError: %s",
                    selected_files[i], e$message))
    list_et_data[[i]] <- NULL
  })
}
h5closeAll()

# Keep only these variables:
cols_to_keep_et <- c("logged_time",
                     "left_pupil_measure1",
                     "right_pupil_measure1")
list_et_data <- lapply(list_et_data, function(df) {
  df[ , intersect(cols_to_keep_et, names(df)), drop = FALSE]
})

## READ TASK DATA ####
data_files_task <- list.files(path = task_data_path, pattern = "\\.csv$",
                              full.names = TRUE)
list_task_data <- pblapply(data_files_task, read.csv)

# Data frame names are unique subject IDs from file names
names(list_task_data) <- sapply(data_files_task, extract_ids)

# Keep only these variables:
cols_to_keep_task <- c(".thisRepN",
                       ".thisTrialN",
                       ".thisN",
                       "phase",
                       "block_counter",
                       "stimulus_duration",
                       "baseline_trial_counter",
                       "trial",
                       "timestamp_exp",
                       "practice_trial_counter",
                       "responses_timestamp",
                       "ISI_duration",
                       "responses_rt",
                       "responses_median",
                       "oddball_trial_counter",
                       "feedback",
                       "id")
list_task_data <- pblapply(list_task_data, function(df) {
  df[ , intersect(cols_to_keep_task, names(df)), drop = FALSE]
})

## CHECK FILE MATCHING ####
et_names <- names(list_et_data)
task_names <- names(list_task_data)
common_names <- intersect(et_names, task_names)
et_only <- setdiff(et_names, task_names)
task_only <- setdiff(task_names, et_names)
if (length(et_only) > 0) {
  cat("REMOVED THE FOLLOWING SUBJECTS FROM LIST_ET_DATA:\n")
  cat(paste0("  - ", et_only), sep = "\n")
  list_et_data <- list_et_data[common_names]
}
if (length(task_only) > 0) {
  cat("REMOVED THE FOLLOWING SUBJECTS FROM LIST_TASK_DATA:\n")
  cat(paste0("  - ", task_only), sep = "\n")
  list_task_data <- list_task_data[common_names]}

df_trial <- plyr::rbind.fill(list_task_data)

## MERGE EYE TRACKING AND TASK DATA ####
# Goal:assign each eye-tracking row to the trial it belongs to based on timestamps.
fun_merge_all_ids <- function(et_data, trial_data) {
  # Time variables: eye tracking (logged_time) + trial data (timestamp_exp)
  start_ts <- trial_data$timestamp_exp # trial start
  end_ts <- c(trial_data$timestamp_exp[-1], NA) # trial end
  et_ts <- et_data$logged_time
  split_trial_data <- split(trial_data, seq(nrow(trial_data)))

  fun_merge_data <- function(ts_1, ts_2, trial_data_splitted) {
    matched_time <- which(et_ts >= ts_1 & et_ts < ts_2)
    if (trial_data_splitted$baseline_trial_counter == "6" & !is.na(trial_data_splitted$baseline_trial_counter)) {
      matched_time <- which(et_ts >= ts_1)
    }
    selected_et_data <- et_data[matched_time, ] # et data for trial duration
    # trial data: 1 row == 1 trial -> is repeated for each eye tracking event
    repeated_trial_data <- data.frame(
      sapply(trial_data_splitted, function(x) {
        rep(x, length(matched_time))}, simplify = FALSE))
    merged_data <- data.frame(repeated_trial_data, selected_et_data)}
  print(paste0("merge: ", unique(trial_data$id)))

  df_one_id <- mapply(
    fun_merge_data,
    ts_1 = start_ts,
    ts_2 = end_ts,
    trial_data_splitted = split_trial_data,
    SIMPLIFY = FALSE)
  df_one_id <- dplyr::bind_rows(df_one_id) # faster than rbind.fill
}

# Calling function
df_list <- pbmapply(
  fun_merge_all_ids,
  et_data = list_et_data,
  trial_data = list_task_data, SIMPLIFY = FALSE)

#save sample data
#saveRDS(df_list, file = "data/df_list_sample.rds") #seed 123
#saveRDS(df_list, file = "data/df_list_sample2.rds") #seed 666
saveRDS(df_list, file = "data/df_list_sample3.rds") #seed 444
