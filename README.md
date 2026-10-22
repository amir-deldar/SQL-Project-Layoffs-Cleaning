# Layoffs Data Cleaning (SQL Project)

A data cleaning project in **MySQL** that takes a raw, messy dataset of company layoffs and turns it into a clean, analysis-ready table. The cleaned data is ready for Exploratory Data Analysis (EDA).

---


## Project Overview

Raw data is rarely ready for analysis. This project walks through a complete cleaning pipeline on a layoffs dataset, following four steps:

1. Find and remove duplicates
2. Standardize data and values
3. Check NULL values and decide how to handle them
4. Remove irrelevant rows and columns

To protect the original data, the raw table is never modified. All work is done on copies of it.

---

## Repository Structure

```
.
├── Layoffs_Data_Cleaning.sql    # Full cleaning script, commented step by step
├── layoffs.csv                  # Raw dataset
├── layoffs_cleaned.csv          # Cleaned dataset (exported after cleaning)
└── README.md
```

File locations: `(sql codes/Layoffs_Data_Cleaning.sql)`, `(data/raw data/layoffs.csv)`, `(data/processed data/layoffs_cleaned.csv)`

---

## Dataset

The raw file contains **2,361 rows** and **9 columns**:

| Column | Description |
|---|---|
| `company` | Name of the company |
| `location` | City / region of the company |
| `industry` | Industry the company operates in |
| `total_laid_off` | Number of employees laid off |
| `percentage_laid_off` | Percentage of the workforce laid off |
| `date` | Date of the layoff |
| `stage` | Funding stage of the company |
| `country` | Country of the company |
| `funds_raised_millions` | Total funds raised, in millions (USD) |

---

## Tools and Techniques

- **MySQL / MySQL Workbench**
- Window functions: `ROW_NUMBER() OVER (PARTITION BY ...)`
- Self joins for filling missing values
- String functions: `TRIM`, `STR_TO_DATE`
- DDL and DML: `CREATE TABLE ... LIKE`, `ALTER TABLE`, `UPDATE`, `DELETE`

---

## Cleaning Workflow

### 0. Create working copies
The raw table `layoffs` is copied into `layoffs_copy1`, so the original data stays untouched.

### Step 1: Remove duplicates
- `ROW_NUMBER()` is partitioned over all columns to flag exact duplicate rows (`row_num > 1`).
- MySQL does not allow deleting directly from a CTE, so a second table, `layoffs_copy2`, is created with an extra `row_num` column.
- Rows where `row_num >= 2` are deleted, and a check query confirms no duplicates remain.

### Step 2: Standardize data

| Issue | Fix |
|---|---|
| Blank `industry` values | Converted empty strings to `NULL` |
| Missing `industry` for companies that appear in other rows (e.g. Airbnb) | Self join on `company` to copy the populated industry value |
| Crypto naming variations (`Crypto Currency`, `CryptoCurrency`) | Standardized to `Crypto` |
| `United States.` with a trailing period | `TRIM(TRAILING '.' FROM country)` |
| `date` stored as text | Converted with `STR_TO_DATE(..., '%m/%d/%Y')`, then column changed to `DATE` type |

Bally's is the only company left with a `NULL` industry, because no other record exists to fill it from.

### Step 3: Review NULL values
NULLs in `total_laid_off`, `percentage_laid_off` and `funds_raised_millions` were kept. They are legitimate unknowns, and keeping them as `NULL` makes aggregations in the EDA phase more accurate.

### Step 4: Remove unnecessary rows and columns
- Deleted rows where **both** `total_laid_off` and `percentage_laid_off` are `NULL`, since they carry no usable layoff information.
- Dropped the helper column `row_num`.

---

## Results

- Duplicate records removed
- Inconsistent industry and country values standardized
- Missing industries filled in wherever another record for the same company existed
- `date` converted from text to a proper `DATE` type
- Rows with no layoff information removed
- A clean, consistent table ready for analysis

---

## Key Takeaways

- Always work on a copy of the raw data.
- Window functions make duplicate detection straightforward.
- Self joins can fill missing values automatically instead of fixing records by hand.
- Not every NULL needs to be "fixed"; sometimes keeping it is the right call.

---

## Next Steps

- Exploratory Data Analysis (EDA) on the cleaned table:
  - Layoffs by year, industry, country and company
  - Funding stage vs. layoff size
  - Rolling totals over time
- Build dashboards or visualizations from the results

---

**Author: Amir Deldar**

## 📬 Contact:

[LinkedIn](https://www.linkedin.com/in/amirdeldar) · [GitHub](https://github.com/amir-deldar) · Email: <callmedeldar@gmail.com>
