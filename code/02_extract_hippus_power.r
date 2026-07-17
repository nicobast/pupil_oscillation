#compare hippus power
source("code/fun_hippus_power.R") #loads predefined function that applies custom pupil preprocessing and extracts power
source("code/packages.R") #loads required packages

# Read an RDS file in R
# Use the readRDS() function to load the RDS file
#three random sets
df_list <- readRDS(file = "data/df_list_sample1.rds")


# ----------------------------------------------------------------------
# Utility: run `func_hippus_power` for a selected block across all participants
# ----------------------------------------------------------------------
extract_power_by_block <- function(df_list, block_num) {
  # Pre‑allocate the list that will hold the results
  power_list <- vector("list", length(df_list))

  for (i in seq_along(df_list)) {
    current_time <- Sys.time()

    # #debugging
    # i=10
    # block_num=3

    # Grab the data for the current participant
    data <- df_list[[i]]

    # Sub‑set only the rows belonging to the desired block
    block_data <- data[data$block_counter == block_num, ]

    # Inform the user (mirrors the original script’s prints)
    message(sprintf('processing participant %d', i))

    # Run the original power‑extraction routine
    power_output <- func_hippus_power(block_data)

    # Store the result
    power_list[[i]] <- power_output

    # Report timing (again, mirrors the original script)
    message(sprintf('time processing %d %s', i,
                    Sys.time() - current_time))
  }

  power_list
}

# ----------------------------------------------------------------------
# Example usage – replaces the three hard‑coded loops in the original script
# ----------------------------------------------------------------------

table(df_list[[1]]["block_counter"])
table(df_list[[1]]["phase"])

test<-df_list[[1]]
names(test )

#compare blocks

# Block 3  (original “first block”)
power_list_first_block <- extract_power_by_block(df_list, 3)

# Block 5  (original “second block”)
power_list_second_block <- extract_power_by_block(df_list, 5)

# Block 10 (original “third block”)
power_list_third_block  <- extract_power_by_block(df_list, 10)

# Block 12 (original “fourth block”)
power_list_fourth_block <- extract_power_by_block(df_list, 12)


# INFO from fun_hippus_power
# noise <- sum(data[frequencies >= 0 & frequencies <= frequency_noise_threshold])
# low_power <- sum(data[frequencies > frequency_noise_threshold & frequencies <= 0.04])
# mid_power <- sum(data[frequencies > 0.04 & frequencies <= 0.15])
# high_power <- sum(data[frequencies > 0.15 & frequencies <= 0.4])


#checks relative power of high + mid frequency (0.05 - 0.4 Hz) versus noise (ca. 0.05 Hz)
#equals a signal to noise ratio
power_hippus_first_block<-sapply(power_list_first_block,function(x){x<-(x[1,4]+x[1,3])/x[1,1]})
power_hippus_second_block<-sapply(power_list_second_block,function(x){x<-(x[1,4]+x[1,3])/x[1,1]})
power_hippus_third_block<-sapply(power_list_third_block,function(x){x<-(x[1,4]+x[1,3])/x[1,1]})
power_hippus_fourth_block<-sapply(power_list_fourth_block,function(x){x<-(x[1,4]+x[1,3])/x[1,1]})


mean(unlist(power_hippus_first_block))
mean(unlist(power_hippus_second_block))
mean(unlist(power_hippus_third_block))
mean(unlist(power_hippus_fourth_block))

sd(unlist(power_hippus_first_block))
sd(unlist(power_hippus_second_block))
sd(unlist(power_hippus_third_block))
sd(unlist(power_hippus_fourth_block))


# compare baseline blocks
power_list_first_baseline <- extract_power_by_block(df_list, 2)
#power_list_second_baseline <- extract_power_by_block(df_list, 4)
#power_list_third_baseline  <- extract_power_by_block(df_list, 6)
#power_list_fourth_baseline <- extract_power_by_block(df_list, 9)
#power_list_fifth_baseline <- extract_power_by_block(df_list, 11)
power_list_sixth_baseline <- extract_power_by_block(df_list, 13)

power_hippus_first_baseline<-sapply(power_list_first_baseline,function(x){x<-(x[1,4]+x[1,3])/x[1,1]})
power_hippus_sixth_baseline<-sapply(power_list_sixth_baseline,function(x){x<-(x[1,4]+x[1,3])/x[1,1]})

sd(unlist(power_hippus_first_baseline))
sd(unlist(power_hippus_sixth_baseline))
