# Data Cleaning — Global Tech Layoffs (2020–2023)

## Purpose
This stage prepares a raw, self-reported layoffs dataset for reliable
aggregation. The raw file (`data/raw data/layoffs.csv`) contains ~2,300 records
with known quality issues: exact duplicates, inconsistent labels, text-typed
dates, missing industry values, and rows with no usable layoff quantity.
The output of this stage is `data/processed data/layoffs_cleaned.csv`, which all
downstream analysis depends on.

## Input / Output

| | Path | Rows |
|---|---|---|
| Input  | `data/raw/layoffs.csv`      | 2,361 |
| Output | `data/cleaned/layoffs_cleaned.csv` | 1,996 |

The raw file is preserved untouched. All transformations happen on a copy
(`layoffs_copy1` → `layoffs_copy2`) so the original can always be re-audited.

## Pipeline

The cleaning script (`01_data_cleaning.sql`) runs in four ordered steps.
Each step is idempotent and can be re-run safely.

### Step 1 — Remove exact duplicates
- Deduplication key: **all nine columns** (company, location, industry,
  total_laid_off, percentage_laid_off, date, stage, country,
  funds_raised_millions).
- Method: `ROW_NUMBER() OVER (PARTITION BY <all columns>)` then delete rows
  where `row_num >= 2`.
- Rationale: partitioning on all columns ensures only *exact* duplicates are
  removed. Two layoff events by the same company on different dates (or with
  different headcounts) are legitimate and must be preserved — e.g., Amazon
  appears three times with distinct dates and totals.
- Result: **365 exact duplicates removed.**

### Step 2 — Standardize values
Three sub-steps, all on the `industry`, `country`, and `date` columns:

**2a. Industry — fill missing values via self-join**
- Blank `industry` strings converted to `NULL` first (easier to handle).
- Missing values filled by joining the table to itself on `company`, copying
  the industry from a record where the same company has a known industry.
  ```sql
  UPDATE layoffs_copy2 AS t1
  JOIN layoffs_copy2 AS t2 ON t1.company = t2.company
  SET t1.industry = t2.industry
  WHERE t1.industry IS NULL AND t2.industry IS NOT NULL;
