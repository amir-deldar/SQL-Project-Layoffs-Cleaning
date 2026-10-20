-- SQL Project: Layoffs - Data Cleaning




SELECT *
From layoffs_dataset.layoffs;



-- At first we should make a copy of our main table (layoffs) and we will work on the copy and we start cleaning data, because we need the raw data to be safe
CREATE TABLE layoffs_dataset.layoffs_copy1
LIKE layoffs_dataset.layoffs;

INSERT layoffs_dataset.layoffs_copy1
SELECT * 
FROM layoffs_dataset.layoffs;



-- Now we made our copy and we will work on it and clean our data, these are our steps:
-- STEP 1: Find and Remove All the Duplicates
-- STEP 2: Standardizing Data and Values
-- STEP 3: Checking NULL values and think about what to do with them
-- STEP 4: Removing all the irrevelant and unnecessary columns or rows



-- STEP 1: Find and Remove All the Duplicates
SELECT *
FROM layoffs_dataset.layoffs_copy1;


-- these are the ones we want to delete where the row number is greater than 1 (that means there are more than 1 row with the exact same values):
SELECT *
FROM (
	SELECT company, location, industry, total_laid_off,percentage_laid_off,`date`, stage, country, funds_raised_millions,
		ROW_NUMBER() OVER (
			PARTITION BY company, location, industry, total_laid_off,percentage_laid_off,`date`, stage, country, funds_raised_millions
			) AS row_num
	FROM 
		layoffs_dataset.layoffs_copy1
) duplicates
WHERE 
	row_num > 1;

-- But for deleting the duplicates we should make another copy of the current table with the column row_num:
CREATE TABLE `layoffs_dataset`.`layoffs_copy2` (
  `company` text,
  `location` text,
  `industry` text,
  `total_laid_off` int DEFAULT NULL,
  `percentage_laid_off` text,
  `date` text,
  `stage` text,
  `country` text,
  `funds_raised_millions` int,
  row_num INT
);

SELECT *
FROM layoffs_dataset.layoffs_copy2;

-- As we see the new table (layoffs_copy2) is created but it's empty and we should import data into it:
INSERT INTO `layoffs_dataset`.`layoffs_copy2`
	(`company`,
	`location`,
	`industry`,
	`total_laid_off`,
	`percentage_laid_off`,
	`date`,
	`stage`,
	`country`,
	`funds_raised_millions`,
	`row_num`)
SELECT `company`,
`location`,
`industry`,
`total_laid_off`,
`percentage_laid_off`,
`date`,
`stage`,
`country`,
`funds_raised_millions`,
		ROW_NUMBER() OVER (
			PARTITION BY company, location, industry, total_laid_off,percentage_laid_off,`date`, stage, country, funds_raised_millions
			) AS row_num
	FROM 
		layoffs_dataset.layoffs_copy1;

-- Now the same data is imported to our new table but with a new column "row_num" at the end, let's check it:
SELECT *
FROM layoffs_dataset.layoffs_copy2;

-- Ok, now we can delete the duplicates easily:
DELETE FROM layoffs_dataset.layoffs_copy2
WHERE row_num >= 2;

-- Let's check:

SELECT *
FROM (
	SELECT company, location, industry, total_laid_off,percentage_laid_off,`date`, stage, country, funds_raised_millions,
		ROW_NUMBER() OVER (
			PARTITION BY company, location, industry, total_laid_off,percentage_laid_off,`date`, stage, country, funds_raised_millions
			) AS row_num
	FROM 
		layoffs_dataset.layoffs_copy2
) duplicates
WHERE 
	row_num > 1;
    
    -- So in the "layoffs_copy2" table we don't have any duplicates now.
    
  -- ----------------------------------------------------------------------------------------------------------------------------------------------------  
-- STEP 2: Standardizing Data and Values

SELECT * 
FROM layoffs_dataset.layoffs_copy2;


-- Let's inspect the industry column to identify any missing or blank values
SELECT DISTINCT industry
FROM layoffs_dataset.layoffs_copy2
ORDER BY industry;

SELECT *
FROM layoffs_dataset.layoffs_copy2
WHERE industry IS NULL
OR industry = ''
ORDER BY industry;

-- Examine the records for these companies
SELECT *
FROM layoffs_dataset.layoffs_copy2
WHERE company LIKE 'Bally%';

-- No issues found in these records
SELECT *
FROM layoffs_dataset.layoffs_copy2
WHERE company LIKE 'airbnb%';

-- Airbnb belongs to the travel industry, but its industry value is missing here.
-- Other companies may have the same issue. We can solve this by checking whether
-- another record with the same company name contains a valid industry value.
-- This approach allows us to fill in missing values automatically instead of
-- reviewing and correcting potentially thousands of records manually.

-- Replace empty industry strings with NULL values because they are easier to handle
UPDATE layoffs_dataset.layoffs_copy2
SET industry = NULL
WHERE industry = '';

-- Check whether the blank industry values have been converted to NULL
SELECT *
FROM layoffs_dataset.layoffs_copy2
WHERE industry IS NULL
OR industry = ''
ORDER BY industry;

-- Fill in missing industry values using matching company records where possible

UPDATE layoffs_dataset.layoffs_copy2 AS t1
JOIN layoffs_dataset.layoffs_copy2 AS t2
    ON t1.company = t2.company
SET t1.industry = t2.industry
WHERE t1.industry IS NULL
  AND t2.industry IS NOT NULL;


-- Review the remaining missing industry values.
-- Bally's appears to be the only company without another populated record
-- that can be used to fill in its missing industry value.
SELECT *
FROM layoffs_dataset.layoffs_copy2
WHERE industry IS NULL
OR industry = ''
ORDER BY industry;

-- ---------------------------------------------------

-- The Crypto industry has several different name variations.
-- Standardize them all under a single value: 'Crypto'.
SELECT DISTINCT industry
FROM layoffs_dataset.layoffs_copy2
ORDER BY industry;

UPDATE layoffs_dataset.layoffs_copy2
SET industry = 'Crypto'
WHERE industry IN ('Crypto Currency', 'CryptoCurrency');

-- Verify that the industry names have been standardized
SELECT DISTINCT industry
FROM layoffs_dataset.layoffs_copy2
ORDER BY industry;

-- --------------------------------------------------

-- Review the dataset to identify any additional inconsistencies
SELECT *
FROM layoffs_dataset.layoffs_copy2;

-- Some country values appear as 'United States' while others appear as
-- 'United States.' with a trailing period. Let's make these values consistent.
SELECT DISTINCT country
FROM layoffs_dataset.layoffs_copy2
ORDER BY country;

UPDATE layoffs_dataset.layoffs_copy2
SET country = TRIM(TRAILING '.' FROM country);

-- Check the country column again to confirm the correction
SELECT DISTINCT country
FROM layoffs_dataset.layoffs_copy2
ORDER BY country;

-- --------------------------------------------------

-- Next, let's standardize the date column
SELECT *
FROM layoffs_dataset.layoffs_copy2;

-- Convert the date strings into a proper date format using STR_TO_DATE
UPDATE layoffs_dataset.layoffs_copy2
SET `date` = STR_TO_DATE(`date`, '%m/%d/%Y');

-- Change the column's data type to DATE
ALTER TABLE layoffs_dataset.layoffs_copy2
MODIFY COLUMN `date` DATE;

-- Review the dataset after updating the date column
SELECT *
FROM layoffs_dataset.layoffs_copy2;

-- ----------------------------------------------------------------------------------------------------------------------------------------------------


-- STEP 3: Checking NULL values and think about what to do with them
SELECT *
FROM layoffs_dataset.layoffs_copy2
WHERE (total_laid_off OR percentage_laid_off OR funds_raised_millions) IS NULL;

-- The NULL values in total_laid_off, percentage_laid_off, and
-- funds_raised_millions appear reasonable, so I don't think they need changing.
-- Keeping these values as NULL makes calculations easier during the
-- Exploratory Data Analysis (EDA) process.

-- Therefore, no changes are necessary for the NULL values in these columns.



-- STEP 4: Removing all the irrevelant and unnecessary columns or rows

SELECT *
FROM layoffs_dataset.layoffs_copy2
WHERE total_laid_off IS NULL;

SELECT *
FROM layoffs_dataset.layoffs_copy2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

-- Remove records that don't contain useful layoff information
DELETE FROM layoffs_dataset.layoffs_copy2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

-- Review the dataset after deleting the unnecessary records
SELECT *
FROM layoffs_dataset.layoffs_copy2;

-- Remove the row_num column because it is no longer needed
ALTER TABLE layoffs_dataset.layoffs_copy2
DROP COLUMN row_num;

-- Check the dataset again after removing the column
SELECT *
FROM layoffs_dataset.layoffs_copy2;

-- Data Cleaning is Done! Now we can export our table.













































