#compare hippus power
source("code/fun_hippus_power.R") #loads predefined function
source("code/packages.R") #loads required packages
source("code/exclude_size_outlier_rolling.R") #loads update size_outlier funciton

# Read an RDS file in R
# Use the readRDS() function to load the RDS file
#three random sets
df_list <- readRDS(file = "data/df_list_sample1.rds")

#loop across participants - first block
power_list_first_block<-list()
for(i in 1:length(df_list)){
current_time<-Sys.time()
data<-df_list[[i]] #select data of one participant
data_firstblock<-data[data$block==3,] #select data of second block
print(paste('processing participant',i))
power_output<-func_hippus_power(data_firstblock)
power_list_first_block[[i]]<-power_output
print(paste('time processing',i,Sys.time()-current_time))
}

#loop across participants - second block
power_list_second_block<-list()
for(i in 1:length(df_list)){
current_time<-Sys.time()
data<-df_list[[i]] #select data of one participant
data_firstblock<-data[data$block==5,] #select data of second block
print(paste('processing participant',i))
power_output<-func_hippus_power(data_firstblock)
power_list_second_block[[i]]<-power_output
print(paste('time processing',i,Sys.time()-current_time))
}

#loop across participants - third block
power_list_third_block<-list()
for(i in 1:length(df_list)){
current_time<-Sys.time()
data<-df_list[[i]] #select data of one participant
data_firstblock<-data[data$block==10,] #select data of second block
print(paste('processing participant',i))
power_output<-func_hippus_power(data_firstblock)
power_list_third_block[[i]]<-power_output
print(paste('time processing',i,Sys.time()-current_time))
}

#loop across participants - fourth block
power_list_fourth_block<-list()
for(i in 1:length(df_list)){
current_time<-Sys.time()
data<-df_list[[i]] #select data of one participant
data_firstblock<-data[data$block==12,] #select data of second block
print(paste('processing participant',i))
power_output<-func_hippus_power(data_firstblock)
power_list_fourth_block[[i]]<-power_output
print(paste('time processing',i,Sys.time()-current_time))
}

# INFO from fun_hippus_power
# noise <- sum(data[frequencies >= 0 & frequencies <= frequency_noise_threshold])
# low_power <- sum(data[frequencies > frequency_noise_threshold & frequencies <= 0.04])
# mid_power <- sum(data[frequencies > 0.04 & frequencies <= 0.15])
# high_power <- sum(data[frequencies > 0.15 & frequencies <= 0.4])

test<-power_list_first_block[[1]]


#checks relative power of high + mid frequency (0.05 - 0.4 Hz) versus noise (ca. 0.05 Hz)
#equals a signal to noise ratio
power_hippus_first_block<-sapply(power_list_first_block,function(x){x<-(x[1,4]+x[1,3])/x[1,1]})
power_hippus_second_block<-sapply(power_list_second_block,function(x){x<-(x[1,4]+x[1,3])/x[1,1]})
power_hippus_third_block<-sapply(power_list_third_block,function(x){x<-(x[1,4]+x[1,3])/x[1,1]})
power_hippus_fourth_block<-sapply(power_list_fourth_block,function(x){x<-(x[1,4]+x[1,3])/x[1,1]})


power_hippus_first_block
power_hippus_second_block
power_hippus_third_block
power_hippus_fourth_block

df_hippus_first_block<-c(df_hippus_first_block,power_hippus_first_block)
df_hippus_second_block<-c(df_hippus_second_block,power_hippus_second_block)
df_hippus_third_block<-c(df_hippus_third_block,power_hippus_third_block)
df_hippus_fourth_block<-c(df_hippus_fourth_block,power_hippus_fourth_block)

sd(df_hippus_first_block)
sd(df_hippus_second_block)
sd(df_hippus_third_block)
sd(df_hippus_fourth_block)

#TODO:
#- how can i define a manipulaiton check and validity of hippus?
#- check across many participants
