# -------------------------------------------------------------------------
# Setup: Load required packages
# -------------------------------------------------------------------------
library(tidyverse)

# 1. Define the input and output paths
input_dir <- "~/Desktop/input"
output_file <- "~/Desktop/combined_cell_data.csv"

# 2. Get a list of all morphology files in the input folder
# We use these as the "base" files to search from
morph_files <- list.files(path = input_dir, pattern = "-morph\\.txt$", full.names = TRUE)

# 3. Define a function to process each cell's files
process_cell_data <- function(morph_path) {
  
  # Extract the raw file name (e.g., "HCY2111_...-Cell001-morph.txt")
  file_name <- basename(morph_path)
  
  # Use Regular Expressions to cleanly split the Image Name and the Cell ID
  # This looks for everything before "-Cell" and extracts the Cell number
  match_data <- str_match(file_name, "^(.*)-(Cell\\d+)-morph\\.txt$")
  image_name <- match_data[1, 2]
  cell_id <- match_data[1, 3]
  
  # Read the morphology data
  # read_tsv is used because these FIJI/ImageJ outputs are tab-separated
  df_morph <- read_tsv(morph_path, show_col_types = FALSE) %>%
    # Remove the un-named first column which just contains row numbers
    select(-1)
  
  # Construct the expected path for the matching volume file
  vol_filename <- paste0(image_name, "-", cell_id, "vol.txt")
  vol_path <- file.path(input_dir, vol_filename)
  
  # Initialize volume variables as NA in case the file is missing
  cell_vol <- NA
  mito_vol <- NA
  mito_ratio <- NA
  
  # If the volume file exists, read it and extract the numbers
  if (file.exists(vol_path)) {
    vol_lines <- readLines(vol_path, warn = FALSE)
    
    # Loop through the lines and extract the value after the colon
    for (line in vol_lines) {
      if (str_detect(line, "Cell Volume")) {
        cell_vol <- as.numeric(str_split(line, ":")[[1]][2])
      } else if (str_detect(line, "Sum mito Volume")) {
        mito_vol <- as.numeric(str_split(line, ":")[[1]][2])
      } else if (str_detect(line, "mito vol ratio")) {
        mito_ratio <- as.numeric(str_split(line, ":")[[1]][2])
      }
    }
  }
  
  # Combine the identifiers, morphology data, and volume data into one row
  df_combined <- tibble(
    Image = image_name,
    Cell_ID = cell_id
  ) %>%
    bind_cols(df_morph) %>%
    mutate(
      Cell_Volume = cell_vol,
      Sum_Mito_Volume = mito_vol,
      Mito_Vol_Ratio = mito_ratio
    )
  
  return(df_combined)
}

# 4. Apply the function to all morph files and stack them into one large dataframe
final_dataset <- map_dfr(morph_files, process_cell_data)

# 5. Save the final compiled data
write_csv(final_dataset, output_file)

cat("Success! Processed", nrow(final_dataset), "cells.\n")
cat("Data saved to:", output_file, "\n")