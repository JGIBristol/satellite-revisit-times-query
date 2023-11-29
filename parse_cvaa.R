# Date: 2020-05-05
# Author: Leo Gorman   

#' Description: This script parses the cvaa files
#' and extracts the pass information for each point.
#' As an example I calculate the revisit pass time for 
#' each point and plot it on a map.

library(magrittr)
library(tibble)
library(tidyr)
library(dplyr)
library(ggplot2)
library(viridis)

#--------------------------------------------
# Specifying File Path
#--------------------------------------------
# This is the path to the file. Please replace this with the path to your file.
file_path <- "./data/Accesses 1.cvaa"

#--------------------------------------------
# Defining Functions
#--------------------------------------------


radians_to_degrees <- function(radians, offset=F){
    if (offset) {
        radians[radians>pi] <- radians[radians>pi] - 2*pi
       
    }

    return(radians * 180 / pi)
}



#' Get Details for Single Point
#'
#' This function extracts the details for a single point.
#' A list of "point numbers" and a list of "new lines" is used.
#' This 
#' 
#' 
#' @param point_number_index The index of the current point to extract details for
#' Note that index refers to "first point" as it appears in the file, not the actual point number.
#' @param full_file The full file to search through.
#' @param all_points The vector of lines where the "point number" appears
#' @param all_newlines The vector of lines where the "new line" appears
#' @return A nested list containing the details for a single point
#' @export
get_details_for_single_point <- function(point_number_index,full_file, all_points, all_newlines){
    current_point <- all_points[point_number_index]

    
    point_number <- gsub("PointNumber\t\t", "",full_file[current_point]) %>% trimws() %>% as.numeric()
    lat <- gsub("Lat\t\t", "",full_file[current_point + 1]) %>% trimws() %>% as.numeric()
    lat <- radians_to_degrees(lat)
    lon <- gsub("Lon\t\t", "",full_file[current_point + 2]) %>% trimws() %>% as.numeric()
    lon <- radians_to_degrees(lon, offset=T)

    alt <- gsub("Alt\t\t", "",full_file[current_point + 3]) %>% trimws() %>% as.numeric()
    num_accesses <- gsub("NumberOfAccesses\t\t", "",full_file[current_point + 4]) %>% trimws() %>% as.numeric()

    end_of_access_points <- min( all_newlines[all_newlines > current_point] )
    time_accesses <- full_file[(current_point + 5):(end_of_access_points-1)]  %>% strsplit(., "  ")

    time_accesses <- sapply(time_accesses, function(x){
        return(
            list(
                'point_number' = point_number,
                'lat' = lat,
                'lon' = lon,
                'alt' = alt,
                'num_accesses' = num_accesses,
                'start_time' = as.numeric(x[2]),
                'end_time' = as.numeric(x[3])
            )
        )
    }) %>% t()
    return(time_accesses)
}

#' Get Pass Info
#' 
#' This function extracts information for all
#' the points in the cvaa file. 
#' It searches through the file for a "point number". 
#' and extracts all the relevant informaiton for that
#' point, using the "get_details_for_single_point" function.
#' 
#' @param file_path The path to the file
#' @return A tibble containing the pass information
#' @export
get_pass_info <- function(file_path){
    
    # Read the first 10 lines
    full_file <- readLines(file_path)

    all_points <- grep("PointNumber", full_file)
    all_newlines <- which(full_file=="")

    point_tibbles <- lapply(1:length(all_points), function(i){
       get_details_for_single_point(i,full_file, all_points, all_newlines) 
    }) 

    point_tibbles <- do.call(rbind, point_tibbles)

    point_tibbles[1:100,]
    point_tibbles <- as_tibble(point_tibbles, validate = NULL, .name_repair = NULL)
    point_tibbles <- point_tibbles %>% mutate_all(as.numeric)
    return(point_tibbles)
 
}

revisit_time_df <- function(pass_info){
    cols <- c('point_number', 'lat', 'lon', 'alt', 'start_time')
    df_1 <- pass_info[-1,cols]

    df_1$second_start_time <- as.numeric(pass_info$start_time)[-nrow(pass_info)]
    df_1$second_point_number <- pass_info[-nrow(pass_info),'point_number']

    df_1 <- df_1 %>% filter(point_number == second_point_number)

    df_1$revisit_time <- as.numeric(df_1$start_time) - as.numeric(df_1$second_start_time)

    df_1$start_time <- NULL
    df_1$second_start_time <- NULL

    return(df_1) 
}

#--------------------------------------------
# Extracting Information
#--------------------------------------------

# File path defined at the top
result <- get_pass_info(file_path)

#--------------------------------------------
# Summarising Information
#--------------------------------------------

revisit_time <- revisit_time_df(result)

revisit_time_distribution <- revisit_time %>% 
    group_by(point_number) %>% 
    summarise(
        revisit_time = mean(revisit_time),
        lat=mean(lat),
        lon=mean(lon)
    ) 
#--------------------------------------------
# Plotting
#--------------------------------------------


plot <- ggplot() + 
  geom_point(
    data = revisit_time_distribution, 
    aes(x = lon, y = lat, color = revisit_time),
    stroke=NA) +
  scale_color_viridis() 

ggsave("results/revisit_time.png", plot)
