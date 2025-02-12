# Movies Dataset - Data Cleaning, Exploration, and Visualization

A comprehensive project demonstrating data cleaning, exploratory analysis, and interactive visualization using a Movies dataset. The project leverages T-SQL for initial data cleaning, Python for in-depth exploration, and Tableau Public for dynamic data visualization.

---

## Table of Contents

- [Dataset](#dataset)
- [Project Overview](#project-overview)
- [Data Cleaning & Exploration](#data-cleaning--exploration)
  - [T-SQL Data Cleaning](#t-sql-data-cleaning)
  - [Python Data Exploration](#python-data-exploration)
- [Visualization](#visualization)
- [How to Run](#how-to-run)
- [Contact](#contact)

---

## Dataset

The Movies dataset is available on [Kaggle](https://www.kaggle.com/datasets/bharatnatrayn/movies-dataset-for-extracion-prediction?select=movies.csv). It contains various inconsistencies such as non-standardized column names, duplicated rows, mixed year formats (including Roman numerals), whitespace issues, and incorrect data types.

---

## Project Overview

The raw dataset presented several challenges:
- **Non-standardized column names**
- **Duplicate rows**
- **Inconsistent year formats (including Roman numerals)**
- **Whitespace issues in text fields**
- **Incorrect data types for key columns (e.g., rating, votes, runtime, and gross)**

To address these issues, this project uses a two-pronged approach:
1. **Data Cleaning with T-SQL:** A script to standardize and prepare the data for further analysis.
2. **Data Exploration with Python:** An additional layer of analysis to uncover deeper insights and trends.

---

## Data Cleaning & Exploration

### T-SQL Data Cleaning

The provided T-SQL script performs the following tasks:

1. **Column Renaming:**  
   - Standardizes column names from the source table.
2. **Staging Table Creation:**  
   - Creates a staging table (`movies_staging`) and imports the raw data.
3. **Duplicate Removal:**  
   - Identifies and removes duplicate records based on title, year, description, and runtime.
4. **Year Parsing:**  
   - Extracts production years (start and end years) from the raw `year` column—even when formatted with Roman numerals.
   - Updates movie titles by appending Roman numeral identifiers to differentiate movies released in the same year.
5. **Computed Column:**  
   - Adds a computed column (`type`) to classify entries as either 'Movie' or 'Series' based on year information.
6. **Whitespace Trimming:**  
   - Eliminates leading and trailing whitespace in text fields such as title, genre, description, and stars.
7. **Data Type Conversions:**  
   - Converts the `rating` column to FLOAT.
   - Removes commas from the `votes` column and converts it to INT.
   - Converts the `runtime` column to INT.
   - Cleans the `gross` column (formatted as `$XX.XXM`) and converts it into a numeric value representing millions of dollars, renaming it to `gross(million dollars)`.

### Python Data Exploration

In parallel with the T-SQL cleaning process, Python was used to:
- Cleaning the data for further analysis
- Perform some exploratory data analysis (EDA).
- Prepare the data for predictive modeling and feature extraction.

---

## Visualization

The final interactive visualization of the Movies dataset is hosted on Tableau Public. This dashboard provides dynamic insights into the data:

[![Tableau Public Dashboard]](https://public.tableau.com/app/profile/nasir.nesirli/viz/Movies_17393855435270/Movies)



*Click the image above to explore the interactive dashboard on Tableau Public.*

---

## How to Run

### T-SQL Script

1. **Set Up SQL Server:**  
   Ensure you have a SQL Server instance running with the necessary databases configured.
2. **Load the Dataset:**  
   Import the raw Movies dataset into the source table (e.g., `movies.dbo.movies`).
3. **Execute the Script:**  
   Run the provided T-SQL script in SQL Server Management Studio (SSMS) or your preferred SQL client. The cleaned data will be available in the `movies_staging` table.

### Python Scripts

1. **Install Dependencies:**  
   Make sure Python is installed along with required libraries such as `pandas`, `numpy`, `matplotlib`, and/or `seaborn`.
2. **Run the Analysis:**  
   Execute the scripts located in the `python_analysis` folder to perform data exploration and generate visualizations.

---

## Contact

For any questions or additional information, feel free to reach out:

- **Email:** [nasir.nesirli@gmail.com](mailto:nasir.nesirli@gmail.com)

---

*Thank you for reviewing my project! Contributions and feedback are always welcome.*


