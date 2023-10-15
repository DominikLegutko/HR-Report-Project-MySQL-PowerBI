CREATE DATABASE projectv4;

USE projectv4;

SELECT * FROM hr;

-- Renaming the first column
ALTER TABLE hr
CHANGE ď»żid employee_id VARCHAR(20);

-- Data type check
DESC hr;

-- Standardizing and changing the data format and type for the birthdate column
SELECT birthdate FROM hr;

UPDATE hr
SET birthdate = CASE 
	WHEN birthdate LIKE '%/%' THEN date_format(str_to_date(birthdate, '%m/%d/%Y'),'%Y-%m-%d')
	WHEN birthdate LIKE '%-%' THEN date_format(str_to_date(birthdate, '%m-%d-%Y'),'%Y-%m-%d')
	ELSE NULL 
END;

ALTER TABLE hr
MODIFY COLUMN birthdate DATE;

-- Similar operation for the hire_date column
SELECT hire_date FROM hr;

UPDATE hr
SET hire_date = CASE 
	WHEN hire_date LIKE '%/%' THEN date_format(str_to_date(hire_date, '%m/%d/%Y'),'%Y-%m-%d')
	WHEN hire_date LIKE '%-%' THEN date_format(str_to_date(hire_date, '%m-%d-%Y'),'%Y-%m-%d')
	ELSE NULL 
END;

ALTER TABLE hr
MODIFY COLUMN hire_date DATE;

-- Removing the exact time from termdate and leaving only the date

SELECT termdate FROM hr;

UPDATE hr
SET termdate = date(str_to_date(termdate,'%Y-%m-%d %H:%i:%s UTC'))
WHERE termdate IS NOT NULL AND termdate != '';


ALTER TABLE hr
MODIFY COLUMN termdate DATE;

-- MySQL modes // in strict mode, not all operations can be executed
SET SQL_MODE = ' ';
SET SQL_MODE = 'STRICT_ALL_TABLES';
-- 

--  Adding and calculating the age column

ALTER TABLE hr ADD COLUMN age INT;

UPDATE hr 
SET age = TIMESTAMPDIFF(YEAR,birthdate, CURDATE());

SELECT birthdate, age FROM hr;

-- Some birthdates are incorrectly recorded in the data, let's check it

SELECT 
	min(age) AS min_age,
    max(age) AS max_age
FROM hr;

SELECT COUNT(*) FROM hr WHERE age <= 0;

-- After cleaning and exploring, let's analyze the data

-- Let's check what is the gender breakdown in the company // saved as ('gender breakdown')

SELECT 
	gender, 
	COUNT(*) AS counts 
FROM hr 
WHERE age >= 0 AND termdate = '0000-00-00'
GROUP BY gender;

-- Let's check what is the ethnisity breakdown in the company // saved as ('race breakdwon')

SELECT * FROM hr;

SELECT 
	race, 
	COUNT(*) AS counts 
FROM hr 
WHERE age >= 0 AND termdate = '0000-00-00'
GROUP BY race
ORDER BY counts DESC;

-- Let's check what is the age distribution of employees in the company // saved as ('age_group')

SELECT 
	min(age) AS min_age,
    max(age) AS max_age
FROM hr
WHERE age >= 0 AND termdate = '0000-00-00';

SELECT 
	CASE
		WHEN age >= 18 AND age <= 24 THEN '18-24'
        WHEN age >= 25 AND age <= 34 THEN '25-34'
        WHEN age >= 35 AND age <= 44 THEN '35-44'
        WHEN age >= 45 AND age <= 54 THEN '45-54'
        WHEN age >= 55 AND age <= 64 THEN '55-64'
        ELSE 'nie w przedziale'
	END AS age_groups,
    COUNT(*) as counts
FROM hr
WHERE age >= 0 AND termdate = '0000-00-00'
GROUP BY age_groups
ORDER BY age_groups;

-- Determine how gender is distributed among age groups (just add the 'gender' field to the previous query)
-- // saved as ('age_group_gender')

SELECT 
	CASE
		WHEN age >= 18 AND age <= 24 THEN '18-24'
        WHEN age >= 25 AND age <= 34 THEN '25-34'
        WHEN age >= 35 AND age <= 44 THEN '35-44'
        WHEN age >= 45 AND age <= 54 THEN '45-54'
        WHEN age >= 55 AND age <= 64 THEN '55-64'
        ELSE 'nie w przedziale'
	END AS age_groups,
    COUNT(*) as counts,
    gender
FROM hr
WHERE age >= 0 AND termdate = '0000-00-00'
GROUP BY age_groups, gender
ORDER BY age_groups, gender;

-- How many employees work at headquarters and how many work remotely // saved as ('location')

SELECT 
    CASE 
        WHEN location = 'remote' THEN 'Remote'
        WHEN location = 'headquarters' THEN 'Headquaters'
        ELSE 'different loction' 
    END AS workplace,
    COUNT(*) as counts
FROM hr
WHERE age >= 0 AND termdate = '0000-00-00'
GROUP BY workplace;

-- Average length of employment for terminated employees // saved as ('avg_emp_length_year')

SELECT * FROM hr;

SElECT 
	round(avg(datediff(termdate, hire_date)) / 365,2) AS avg_emp_lenght_year
FROM hr
WHERE age >= 0 AND termdate <= curdate() AND termdate <> '0000-00-00';

-- Let's check how gender distribution varies across departments // saved as ('gender_department')

SELECT 
	department,
    gender,
    COUNT(*) AS counts
FROM hr
WHERE age >= 0 AND termdate = '0000-00-00'
GROUP BY department, gender
ORDER BY department;

-- Distribution of job titles across the company // saved as ('jobtitle_count')

SELECT 
	jobtitle,
    COUNT(*) AS counts
FROM hr
WHERE age >= 0 AND termdate = '0000-00-00'
GROUP BY jobtitle
ORDER BY jobtitle DESC;

-- Let's check which department has the highest turnover rate, which indicates the rate at which employees leave the company
-- // saved as ('turnover_rate')

SELECT 
	department,
    total_count,
    terminated_count,
    terminated_count/total_count AS termination_rate
FROM(
	SELECT 
		department,
        COUNT(*) AS total_count,
        SUM(CASE WHEN termdate <> '0000-00-00'AND termdate <= curdate() THEN 1 ELSE 0 END) AS terminated_count
	FROM hr
    WHERE age >= 0
    GROUP BY department) AS sub_query
ORDER BY termination_rate DESC;
    
-- Distribution of employees across locations by state // saved as ('state')

SELECT 
	location_state,
    COUNT(*) AS counts
FROM hr 
WHERE age >= 0 AND termdate = '0000-00-00'
GROUP BY location_state
ORDER BY counts DESC;

-- How has the company's employee count changed over time based on hire and termination dates 
-- // saved as ('employee_changes')

SELECT * FROM hr;

SELECT
	year,
    hires,
    terminations,
    hires - terminations AS net_changes,
    ROUND((hires - terminations)/hires * 100,2) AS net_changes_percentage 
FROM(
	SELECT
		YEAR(hire_date) AS year,
        COUnT(*) AS hires,
        SUM(CASE WHEN termdate <> '0000-00-00' AND termdate <= curdate() THEN 1 ELSE 0 END) AS terminations
	FROM hr
    WHERE age >= 0
    GROUP BY YEAR(hire_date)) AS subquery
ORDER BY year;

-- What is the tenure distribution for each department // saved as ('avg_tenur')

SELECt
	department,
    ROUND(AVG(datediff(termdate, hire_date)/365),0) AS avg_tenur_year
FROM hr
WHERE termdate <> '0000-00-00' AND termdate <= curdate() AND age > 0
GROUP BY department;

-- We have collected the data, now we can start visualizing it.
