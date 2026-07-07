# -------------------------------------------------------------------------
# Setup: Install required packages if you don't have them installed yet
# install.packages(c("tidyverse", "writexl"))
# -------------------------------------------------------------------------

library(tidyverse)
library(writexl)

# 1. Define the input and output paths (Update the username if necessary)
# "~" is a shortcut for your user home directory on Mac/Linux. On Windows, 
# you might need to use the full path like "C:/Users/YourName/Desktop/input"
input_dir <- "~/Desktop/input"
output_file <- "~/Desktop/input/combined_quantification.xlsx"

# 2. Get a list of all "measure" files in the input folder
measure_files <- list.files(path = input_dir, pattern = "_measure\\.csv$", full.names = TRUE)

# 3. Define a function to process and merge a pair of files
process_image_files <- function(measure_path) {
  
  # Extract the base name of the image (e.g., "SCbG_007_ratio-3D")
  base_name <- str_remove(basename(measure_path), "_measure\\.csv$")
  
  # Construct the expected path for the matching "quantif" file
  quantif_path <- file.path(input_dir, paste0(base_name, "_quantif.csv"))
  
  # Skip if the matching quantif file is missing
  if (!file.exists(quantif_path)) {
    warning(paste("Matching quantif file not found for:", base_name))
    return(NULL)
  }
  
  # Read both CSVs
  # show_col_types = FALSE keeps the console output clean
  df_measure <- read_csv(measure_path, show_col_types = FALSE)
  df_quantif <- read_csv(quantif_path, show_col_types = FALSE)
  
  # Clean up trailing empty columns that sometimes appear in these CSVs 
  # (e.g., an empty column at the end because of a trailing comma)
  df_measure <- df_measure %>% select(where(~!all(is.na(.))))
  df_quantif <- df_quantif %>% select(where(~!all(is.na(.))))
  
  # Merge the files safely by their common identifier columns.
  # This prevents having duplicate "Nb", "Name", "Label", and "Type" columns.
  df_combined <- full_join(df_measure, df_quantif, by = c("Nb", "Name", "Label", "Type"))
  
  # Add 'Image' and 'treatment' columns to the beginning of the dataframe
  df_combined <- df_combined %>%
    mutate(Image = base_name, .before = 1) %>%
    mutate(treatment = case_when(
      str_detect(Image, "KCN") ~ "KCN",
      str_detect(Image, "G_") ~ "glucose",
      TRUE ~ "Unknown" # Default if neither is found
    ), .after = Image)
  
  return(df_combined)
}

# 4. Apply the function to all measure files and bind the rows together into one large dataset
final_dataset <- map_dfr(measure_files, process_image_files)

# 5. Write the final cleaned dataset to an Excel file
write_xlsx(final_dataset, output_file)

cat("Success! Combined", length(measure_files), "images.\n")
cat("File saved to:", output_file, "\n")