library(xml2)
library(dplyr)
library(purrr)
library(stringr)
library(lubridate)
library(tidyverse)
library(stargazer)


rm(list = ls())

################################################################################
################################################################################

#setwd("/Users/raphael/SSD_Documents/STUDIES/M2_EGR/Empirical/INDEX")

################################################################################
################################################################################
# Prepare the Dictionary for climate related texts
################################################################################
################################################################################

climate_terms <- c(
  # Trigrams
  "capture and sequestration",
  "climate and energy",
  "sea level rise",
  "environmental protection agency",
  "energy department",
  "cap and trade",
  "clean power plan",
  "energy efficiency program",
  "fuel economy standard",
  "climate change bill",
  "clean air act",
  "climate stewardship act",
  "clear skies act",
  
  # Bigrams
  "climate change",
  "climate crisis",
  "climate disaster",
  "climate science",
  "climate scientist",
  "climate action",
  "global warming",
  "climate warming",
  "temperature rise",
  "global temperature",
  "greenhouse gas",
  "renewable energy",
  "renewable fuel",
  "renewable electricity",
  "renewable power",
  "clean energy",
  "clean power",
  "green energy",
  "energy efficiency",
  "fuel economy",
  "fuel efficiency",
  "fossil fuel",
  "energy transition",
  "climate transition",
  "climate mitigation",
  "climate adaptation",
  "climate accord",
  "climate conference",
  "climate activist",
  "climate demonstration",
  "energy policy",
  "energy legislation",
  "energy law",
  "energy tax",
  "energy committee",
  "climate bill",
  "climate policy",
  "climate legislation",
  "climate rule",
  "carbon tax",
  "carbon price",
  "carbon market",
  "carbon trading",
  "carbon limit",
  "emission trading",
  "emission limit",
  "emission permit",
  "emission standard",
  "ghg rule",
  "ghg limit",
  "ghg permit",
  "ghg standard",
  "fuel standard",
  "waxman markey",
  "kerry lieberman",
  
  # Unigrams
  "ghg",
  "co2",
  "carbon",
  "emission",
  "methane",
  "environmental",
  "decarbonization",
  "renewables",
  "epa",
  "doe"
)

# Convert terms into strict regex patterns
climate_patterns <- climate_terms %>%
  str_replace_all(" ", "\\\\s+") %>%   # handle whitespace robustly
  paste0("\\b", ., "\\b")

# Collapse into one master regex
climate_regex <- paste(climate_patterns, collapse = "|")

################################################################################
################################################################################
# Functions to parse XML bills
################################################################################
################################################################################
extract_bill_number <- function(file_name) {
  str_extract(file_name, "(?<=-)[^-]+(?=\\.xml$)")
}

# Parse one XML bill
parse_bill_xml <- function(file_path) {
  
  xml <- read_xml(file_path)
  
  tibble(
    file_name       = basename(file_path),
    bill_number     = extract_bill_number(basename(file_path)),
    title           = xml_text(xml_find_first(xml, ".//dc:title")),
    date_published  = as.Date(xml_text(xml_find_first(xml, ".//dc:date"))),
    official_title  = xml_text(xml_find_first(xml, ".//official-title")),
    committees      = paste(xml_text(xml_find_all(xml, ".//committee-name")), collapse = "; "),
    text            = str_squish(
      paste(xml_text(xml_find_all(xml, ".//text")), collapse = " ")
    )
  )
}

################################################################################
# House of Representatives
# Bills 113-119
################################################################################

# Paths
xml_folder <- "INDEX/BILLS_HR_113-119"
xml_files  <- list.files(xml_folder, pattern = "\\.xml$", full.names = TRUE)


# Parse all bills (safe)
all_hr <- map_df(xml_files, ~{
  tryCatch(parse_bill_xml(.x),
           error = function(e) tibble(
             file_name      = basename(.x),
             bill_number    = extract_bill_number(basename(.x)),
             title          = NA_character_,
             date_published = as.Date(NA),
             official_title = NA_character_,
             committees     = NA_character_,
             text           = NA_character_
           ))
})

#save the object all_bills because it's long to compute
dir.create("RDS", showWarnings = FALSE, recursive = TRUE)
saveRDS(all_hr, file = "RDS/all_hr.rds")

#Add the climate related detection
all_hr <- readRDS("RDS/all_hr.rds")
all_hr <- all_hr %>%
  mutate(
    climate_related = str_detect(
      paste(title, official_title, text, sep = " "),
      regex(climate_regex, ignore_case = TRUE)
    )
  )

# Keep only climate-related bills
hr_climate <- filter(all_hr, climate_related)

# Reduced & cleaned dataset for presentation
hr_reduced <- hr_climate %>%
  mutate(
    date_published = as.character(date_published),
  ) %>%
  select(bill_number, date_published, title, text)


dir.create("output_data", showWarnings = FALSE, recursive = TRUE)
write_csv(hr_reduced, "output_data/hr_bills_climate.csv")
# Sample output
hr_sample <- head(hr_reduced, 5)

stargazer(
  hr_sample,
  type   = "text",
  title  = "Sample of Climate-Related Bills",
  summary = FALSE
)

hr_sample

################################################################################
# House of Representatives
# Joint Resolutions
################################################################################
# Paths
xml_folder <- "INDEX/Hjres_ALL"
xml_files  <- list.files(xml_folder, pattern = "\\.xml$", full.names = TRUE)

# Parse all bills (safe)
all_hjres <- map_df(xml_files, ~{
  tryCatch(parse_bill_xml(.x),
           error = function(e) tibble(
             file_name      = basename(.x),
             bill_number    = extract_bill_number(basename(.x)),
             title          = NA_character_,
             date_published = as.Date(NA),
             official_title = NA_character_,
             committees     = NA_character_,
             text           = NA_character_
           ))
})
#save
saveRDS(all_hjres, file = "RDS/all_hjres.rds")

#Add the climate related detection
all_hjres <- readRDS("RDS/all_hjres.rds")
all_hjres <- all_hjres %>%
  mutate(
    climate_related = str_detect(
      paste(title, official_title, text, sep = " "),
      regex(climate_regex, ignore_case = TRUE)
    )
  )

# Keep only climate-related bills

hjres_climate <- filter(all_hjres, climate_related)

# Reduced & cleaned dataset for presentation

hjres_reduced <- hjres_climate %>%
  mutate(
    date_published = as.character(date_published),
  ) %>%
  select(bill_number, date_published, title, text)

write_csv(hjres_reduced, "output_data/hjres_climate.csv")

# Sample output
hjres_sample <- head(hjres_reduced, 5)

stargazer(
  hjres_sample,
  type   = "text",
  title  = "Sample of Climate-Related Bills",
  summary = FALSE
)

hjres_sample

################################################################################
# Senate
# Bills
################################################################################
# Paths
xml_folder <- "INDEX/Senate_ALL"
xml_files  <- list.files(xml_folder, pattern = "\\.xml$", full.names = TRUE)

# Parse all bills (safe)
all_s <- map_df(xml_files, ~{
  tryCatch(parse_bill_xml(.x),
           error = function(e) tibble(
             file_name      = basename(.x),
             bill_number    = extract_bill_number(basename(.x)),
             title          = NA_character_,
             date_published = as.Date(NA),
             official_title = NA_character_,
             committees     = NA_character_,
             text           = NA_character_
           ))
})

#save
saveRDS(all_s, file = "RDS/all_s.rds")

#Add the climate related detection
all_s <- readRDS("RDS/all_s.rds")
all_s <- all_s %>%
  mutate(
    climate_related = str_detect(
      paste(title, official_title, text, sep = " "),
      regex(climate_regex, ignore_case = TRUE)
    )
  )

# Keep only climate-related bills

s_climate <- filter(all_s, climate_related)

# Reduced & cleaned dataset for presentation

s_reduced <- s_climate %>%
  mutate(
    date_published = as.character(date_published),
  ) %>%
  select(bill_number, date_published, title, text)

write_csv(s_reduced, "output_data/s_climate.csv")

# Sample output
s_sample <- head(s_reduced, 5)

stargazer(
  s_sample,
  type   = "text",
  title  = "Sample of Climate-Related Bills",
  summary = FALSE
)

s_sample

################################################################################
# Senate
# Joint Resolutions
################################################################################
# Paths
xml_folder <- "INDEX/Sjres_ALL"
xml_files  <- list.files(xml_folder, pattern = "\\.xml$", full.names = TRUE)

# Parse all bills (safe)
all_sjres <- map_df(xml_files, ~{
  tryCatch(parse_bill_xml(.x),
           error = function(e) tibble(
             file_name      = basename(.x),
             bill_number    = extract_bill_number(basename(.x)),
             title          = NA_character_,
             date_published = as.Date(NA),
             official_title = NA_character_,
             committees     = NA_character_,
             text           = NA_character_
           ))
})

#save
saveRDS(all_sjres, file = "RDS/all_sjres.rds")

#Add the climate related detection
all_sjres <- all_sjres %>%
  mutate(
    climate_related = str_detect(
      paste(title, official_title, text, sep = " "),
      regex(climate_regex, ignore_case = TRUE)
    )
  )

#Keep only climate-related bills

sjres_climate <- filter(all_sjres, climate_related)

#Reduced & cleaned dataset for presentation

sjres_reduced <- sjres_climate %>%
  mutate(
    date_published = as.character(date_published),
  ) %>%
  select(bill_number, date_published, title, text)

write_csv(sjres_reduced, "output_data/sjres_climate.csv")

# Sample output
sjres_sample <- head(hjres_reduced, 5)

stargazer(
  sjres_sample,
  type   = "text",
  title  = "Sample of Climate-Related Bills",
  summary = FALSE
)

sjres_sample

################################################################################
# Dataset of Legislative Texts
################################################################################

#We add identifier in case we need to do robustness checks later
hr_reduced <- hr_reduced %>%
  mutate(chamber = "House", instrument = "Bill")

hjres_reduced <- hjres_reduced %>%
  mutate(chamber = "House", instrument = "JointResolution")

s_reduced <- s_reduced %>%
  mutate(chamber = "Senate", instrument = "Bill")

sjres_reduced <- sjres_reduced %>%
  mutate(chamber = "Senate", instrument = "JointResolution")

#Combine
legi_df <- bind_rows(
  hr_reduced,
  hjres_reduced,
  s_reduced,
  sjres_reduced
)
legi_df <- legi_df %>%
  mutate(date_published = as.Date(date_published)) %>%
  arrange(date_published)

legi_df <- legi_df %>%
  filter(date_published >= as.Date("2016-01-01"))

write_csv(legi_df, "output_data/legi_climate_dataset.csv")

################################################################################
################################################################################
#Policy Intent Documents (American Presidency)
################################################################################
################################################################################

###### SCRIPT TO REMOVE THE DUPLICATA

# Path to your chunks folder
chunks_path <- "INDEX/APP_CHUNKS"

# List all subfolders (CHUNK1, CHUNK2, ...)
chunk_folders <- list.dirs(chunks_path, full.names = TRUE, recursive = FALSE)

# Read all XML file paths
all_files <- map_df(chunk_folders, function(folder) {
  tibble(
    chunk = basename(folder),
    file_path = list.files(folder, pattern = "\\.xml$", full.names = TRUE),
    file_name = basename(list.files(folder, pattern = "\\.xml$", full.names = FALSE))
  )
})

# Remove duplicates based on file_name
all_files_unique <- all_files %>%
  distinct(file_name, .keep_all = TRUE)

#Move unique files to a new folder
unique_folder <- file.path(chunks_path, "UNIQUE_FILES")
dir.create(unique_folder, showWarnings = FALSE)

file.copy(all_files_unique$file_path, unique_folder, overwrite = TRUE)

#####Script for cleaning data

# Set folder path

xml_folder <- "INDEX/APP_CHUNKS/UNIQUE_FILES"
xml_files <- list.files(xml_folder, pattern = "\\.xml$", full.names = TRUE)

# Function to parse a single APP XML file
parse_app_xml <- function(file_path) {
  xml <- read_xml(file_path)
  
  # <text> is the root element
  text_node <- xml_root(xml)
  
  # Extract attributes
  author <- xml_attr(text_node, "author")
  title <- xml_attr(text_node, "title")
  date_published <- as.Date(xml_attr(text_node, "date"))
  
  # Extract full text, replace <lb> with line breaks
  full_text <- xml_text(text_node)
  full_text <- str_replace_all(full_text, "<lb>", "\n")
  
  # Remove leading "Link to original document" if present
  full_text <- str_remove(full_text, "^Link to original document\\s*")
  
  # Clean up extra whitespace
  full_text <- str_squish(full_text)
  
  # Return tibble
  tibble(
    file_name = basename(file_path),
    author = author,
    title = title,
    date_published = date_published,
    text = full_text
  )
}

# Parse all XML files safely
APP <- map_df(xml_files, ~{
  tryCatch(
    parse_app_xml(.x),
    error = function(e) {
      message("Error parsing file: ", .x, " | ", e$message)
      tibble(
        file_name = basename(.x),
        author = NA_character_,
        title = NA_character_,
        date_published = as.Date(NA),
        text = NA_character_
      )
    }
  )
})

# Reduced & cleaned dataset for presentation
APP_reduced <- APP %>%
  mutate(
    date_published = as.character(date_published),
  ) %>%
  select(
    date_published,
    title,
    text
  )

#Only keep from 2016
APP_reduced <- APP_reduced %>% 
  filter(date_published >= "2016-01-01")

write_csv(APP_reduced, "output_data/APP_climate.csv")

# Take a small sample for display
sampled_APP <- APP_reduced %>%
  head(5)

# Display stargazer table
stargazer(
  sampled_APP,
  type = "latex",
  title = "Sample of Policy Intent Documents",
  summary = FALSE,
  rownames = FALSE
)
sampled_APP

################################################################################
################################################################################
################################################################################
################################################################################
################################################################################

