# Movies Dataset - Data Cleaning and Exploration

This repository contains a data cleaning script for the movies dataset, which is used for feature extraction and prediction tasks.

## Dataset

The dataset is available on Kaggle:

[Movies Dataset for Feature Extraction & Prediction](https://www.kaggle.com/datasets/bharatnatrayn/movies-dataset-for-feature-extracion-prediction?select=movies.csv)

## Overview

The dataset initially contains several inconsistencies and messy data formats, such as:
- Non-standardized column names.
- Duplicated rows.
- Mixed formatting in the year field (including Roman numerals).
- Whitespace issues in text fields.
- Incorrect data types for columns like rating, votes, runtime, and gross.

This project provides a comprehensive T-SQL script to clean and standardize the data in preparation for further analysis or predictive modeling.

## Data Cleaning Script

The data cleaning script performs the following tasks:

1. **Column Renaming:**  
   - Renames columns in the source table to standardized names.

2. **Staging Table Creation:**  
   - Creates a new staging table (`movies_staging`) and inserts the raw data from the source table.

3. **Duplicate Removal:**  
   - Identifies and deletes duplicate records based on title, year, description, and runtime.

4. **Year Parsing:**  
   - Extracts production years (start and end years) from the raw `year` column which sometimes contains Roman numerals.
   - Updates movie titles with appended Roman numeral identifiers to differentiate multiple movies released in the same year.

5. **Computed Column:**  
   - Creates a computed column (`type`) to classify entries as 'Movie' or 'Series' based on the presence of start and end year data.

6. **Whitespace Trimming:**  
   - Removes leading and trailing whitespace from text fields such as title, genre, description, and stars.

7. **Data Type Conversions:**  
   - Converts the `rating` column to FLOAT.
   - Removes commas from the `votes` column and converts it to INT.
   - Converts the `runtime` column to INT.
   - Cleans and converts the `gross` column (formatted as `$XX.XXM`) to a numeric value representing millions of dollars, renaming it to `gross(million dollars)`.

## How to Run

1. Ensure you have access to a SQL Server instance and that the necessary databases are set up.
2. Load the raw dataset into the source table (e.g., `movies.dbo.movies`).
3. Execute the provided T-SQL script in your SQL Server Management Studio (SSMS) or your preferred SQL client.
4. The cleaned data will be available in the `movies_staging` table.


## Contact

For questions or further information, please contact me at nasir.nesirli@gmail.com.

