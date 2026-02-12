-- DATA CLEANSING Customer_Call_List BY SQL --
SELECT * FROM customer_call_list;

ALTER TABLE customer_call_list
DROP COLUMN `MyUnknownColumn`, 
DROP COLUMN `MyUnknownColumn_[0]`;

SHOW COLUMNS FROM customer_call_list;

-- CREATE BACK-UP FILE
CREATE TABLE customer_list_1
LIKE customer_call_list;

INSERT customer_list_1
SELECT * FROM customer_call_list;

SELECT * FROM customer_list_1;

-- 1# DROP DUPLICATES - customer_list_new
-- Define duplicates
WITH duplicate_values AS
(SELECT *,
ROW_NUMBER() OVER (PARTITION BY CustomerID, First_Name, Last_Name, Phone_Number, Address
) AS row_num
FROM customer_list_1
)

SELECT * FROM duplicate_values
WHERE row_num >1
;

-- Delete duplicates
-- (Not working- so create new table, delete column with value >2, then drop that column) 
-- DELETE * FROM duplicate_values
-- WHERE row_num >1


-- Copy to clipboard -> Create Statement
CREATE TABLE `customer_list_2` (
  `CustomerID` INT NOT NULL,
  `First_Name` VARCHAR(50),
  `Last_Name` VARCHAR(50),
  `Phone_Number` VARCHAR(20),
  `Address` VARCHAR(255),
  `Paying Customer` VARCHAR(20),
  `Do_Not_Contact` VARCHAR(20),
  `Not_Useful_Column` VARCHAR(255),
  `row_num` INT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Create another backup table
INSERT INTO customer_list_2
SELECT *,
ROW_NUMBER() OVER (PARTITION BY CustomerID, First_Name, Last_Name, Phone_Number, Address
) AS row_num
FROM customer_list_1;

SELECT * FROM customer_list_2;
-- Delete duplicate values from backup table
DELETE 
FROM customer_list_2
WHERE row_num >1;

SELECT * FROM customer_list_2;

-- 2# DELETE NOT USEFUL COLUMN
ALTER TABLE customer_list_2
DROP COLUMN `Not_Useful_column`,
DROP COLUMN `row_num`,
;

SELECT * FROM customer_list_2;


-- 3# LAST NAME CLEANSING
SELECT Last_name, TRIM(REGEXP_REPLACE(Last_Name, '[123._/ ]', '')) as last_name3
FROM customer_list_2;

UPDATE customer_list_2
SET last_name = REGEXP_REPLACE(Last_Name, '[123._/ ]', '');

SELECT * FROM customer_list_2;

-- 4# Phone Number format xxx-xxx-xxxx
WITH phone AS
(SELECT Phone_Number, REGEXP_REPLACE(Phone_Number, '[-/|]', '') as phone2
FROM customer_list_2)

SELECT 
Phone_Number,
CONCAT(LEFT(phone2,3),'-', MID(phone2,5,3), '-', RIGHT(phone2,4)) as phone3
FROM phone;

UPDATE customer_list_2
SET Phone_Number = CONCAT(
LEFT(REGEXP_REPLACE(Phone_Number, '[-/|]', ''),3),'-',
MID(REGEXP_REPLACE(Phone_Number, '[-/|]', ''),5,3), '-',
RIGHT(REGEXP_REPLACE(Phone_Number, '[-/|]', ''),4)
);

SELECT Phone_Number,
CASE 
WHEN Phone_Number ='--' OR Phone_Number LIKE '%Na%'THEN ''
ELSE Phone_Number
END as phone3
FROM customer_list_2;

UPDATE customer_list_2
SET Phone_Number = 
	CASE 
	WHEN Phone_Number ='--' OR Phone_Number LIKE '%Na%'THEN ''
	ELSE Phone_Number
	END;
    
SELECT * FROM customer_list_2;

-- 5# Yes/No
UPDATE customer_list_2
SET `Paying Customer` = 
 CASE 
WHEN `Paying Customer` = 'Y' Then 'Yes'
WHEN `Paying Customer` = 'N' Then 'No'
WHEN `Paying Customer` = 'N/a' Then ''
ELSE `Paying Customer`
END
;

SELECT * FROM customer_list_2;

-- 6# Delete Donotcontact=No
DELETE FROM customer_list_2
WHERE Do_Not_Contact IN ('No','','N');

UPDATE customer_list_2
SET Do_Not_Contact = 
CASE WHEN Do_Not_Contact= 'Y' THEN 'Yes'
ELSE Do_Not_Contact
END;

SELECT * FROM customer_list_2;

-- 7# Address Split
WITH New_Address AS
(SELECT
Address,
    SUBSTRING_INDEX(Address, ',', 1) AS Street,
    TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(Address, ',', 2), ',', -1)) AS State,
    TRIM(SUBSTRING_INDEX(Address, ',', -1)) AS ZipCode
FROM customer_list_1)

SELECT
Address,
Street,
CASE WHEN 
LENGTH(Address) - LENGTH(REPLACE(Address, ',', '')) >=1 THEN State
ELSE '' END AS State,

CASE WHEN 
LENGTH(Address) - LENGTH(REPLACE(Address, ',', '')) >=2 THEN Zipcode
ELSE '' END AS Zipcode

FROM New_Address;

