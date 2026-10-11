================================================================================
  README — Data Preparation Script (00_data_preparation.R)
================================================================================

- The working directory is hardcoded at the top of the script. Update the
  setwd() path before running on a different machine.


OVERVIEW
--------
This script constructs the two raw datasets that feed into the CPU index:

  1. legi_climate_dataset.csv  — Climate-related legislative texts
                                 (U.S. House & Senate, Congress 113–119)

  2. APP_climate.csv           — Policy intent documents
                                 (American Presidency Project, from 2016)

We provide the processed data in the replication file. If for some reason you did not have them, you would have to run this script on the raw XML data before hand.

--------------------------------------------------------------------------------
SECTION 1 — CLIMATE DICTIONARY
--------------------------------------------------------------------------------
Builds a master regex  of climate-related terms from the Gavriilidis (2021) dictionary
organised in three tiers:

  - Trigrams  (e.g., "cap and trade", "sea level rise"...)
  - Bigrams   (e.g., "climate change", "carbon tax", "fossil fuel"...)
  - Unigrams  (e.g., "ghg", "co2", "epa", "methane"...)

Word boundaries (\b) are enforced and whitespace is handled robustly with \s+.
Detection is case-insensitive. The regex is applied to the concatenation of
title + official_title + text for legislative documents.


--------------------------------------------------------------------------------
SECTION 2 — LEGISLATIVE TEXTS (U.S. Congress)
--------------------------------------------------------------------------------
Source: XML bill files downloaded from congress.gov (Congress 113–119).
Four document types are processed in parallel, each following the same pipeline:

  Document type          Folder              Output CSV
  ─────────────────────  ──────────────────  ──────────────────────
  House Bills            BILLS_HR_113-119    hr_bills_climate.csv
  House Joint Resols.    Hjres_ALL           hjres_climate.csv
  Senate Bills           Senate_ALL          s_climate.csv
  Senate Joint Resols.   Sjres_ALL           sjres_climate.csv

Pipeline per document type:
  1. List all .xml files in the folder.
  2. Parse each file with parse_bill_xml():
       - bill_number     extracted from filename (e.g., "hr1234.xml" → "1234")
       - title           from <dc:title>
       - date_published  from <dc:date>
       - official_title  from <official-title>
       - committees      from all <committee-name> nodes (semicolon-separated)
       - text            from all <text> nodes (whitespace-collapsed)
     Parsing errors are caught silently; failed files return an NA row.
  3. Save the full parsed object as an .rds file (avoids re-parsing).
  4. Apply climate_regex to flag climate-related documents.
  5. Keep only flagged rows, retain {bill_number, date_published, title, text}.
  6. Write to CSV.

Final merge:
  - A chamber and instrument identifier is added to each dataset.
  - All four are row-bound into legi_df.
  - Filtered to date_published >= 2016-01-01.
  - Written to legi_climate_dataset.csv.

Note: A diagnostic check for NA values in June–November 2016 is performed on
the raw Senate and House Bill datasets (all_s_2016, all_hr_2016) before merging.


--------------------------------------------------------------------------------
SECTION 3 — POLICY INTENT DOCUMENTS (American Presidency Project)
--------------------------------------------------------------------------------
Source: XML files from the American Presidency Project (APP), stored across
multiple chunk subfolders (CHUNK1, CHUNK2, ...) inside APP_CHUNKS/.

Deduplication step (run once):
  - All XML filenames across all chunk folders are collected.
  - Duplicates are removed on filename.
  - Unique files are copied to APP_CHUNKS/UNIQUE_FILES/.

Parsing: parse_app_xml() extracts from the root <text> element:
  - author          from the "author" attribute
  - title           from the "title" attribute
  - date_published  from the "date" attribute
  - text            full text content, with <lb> replaced by line breaks,
                    leading "Link to original document" stripped, whitespace
                    collapsed.

Filtering:
  - Retained from 2016-01-01 onward.
  - Note: the APP texts are already climate-filtered at the source
    (only climate-related documents were downloaded from the APP).
    No regex filtering step is applied here.

Output: APP_climate.csv with columns {date_published, title, text}.


--------------------------------------------------------------------------------
INPUT FOLDER STRUCTURE (expected)
--------------------------------------------------------------------------------
INDEX/
├── BILLS_HR_113-119/        House bills (.xml)
├── Hjres_ALL/               House joint resolutions (.xml)
├── Senate_ALL/              Senate bills (.xml)
├── Sjres_ALL/               Senate joint resolutions (.xml)
└── APP_CHUNKS/
    ├── CHUNK1/              Raw APP XML files
    ├── CHUNK2/
    ├── ...
    └── UNIQUE_FILES/        Created automatically by the dedup step


--------------------------------------------------------------------------------
OUTPUT FILES
--------------------------------------------------------------------------------
  legi_climate_dataset.csv   Full merged legislative dataset (from 2016)
  APP_climate.csv            Full APP dataset (from 2016)

  Intermediate .rds files (for faster re-runs without re-parsing XML):
    all_hr.rds
    all_hjres.rds
    all_s.rds
    all_sjres.rds


--------------------------------------------------------------------------------
DEPENDENCIES
--------------------------------------------------------------------------------
R packages required:
  xml2, dplyr, purrr, stringr, lubridate, tidyverse, stargazer

Install missing packages with:
  install.packages(c("xml2", "dplyr", "purrr", "stringr",
                     "lubridate", "tidyverse", "stargazer"))



================================================================================
