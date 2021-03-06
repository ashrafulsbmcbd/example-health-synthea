------------------------------------------------------------------------------
-- Copyright 2019 IBM Corp. All Rights Reserved.
--
-- Licensed under the Apache License, Version 2.0 (the "License");
--  you may not use this file except in compliance with the License.
--  You may obtain a copy of the License at
--
--       http://www.apache.org/licenses/LICENSE-2.0
--
--   Unless required by applicable law or agreed to in writing, software
--   distributed under the License is distributed on an "AS IS" BASIS,
--   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
--   See the License for the specific language governing permissions and
--   limitations under the License.
------------------------------------------------------------------------------

--
-- Transform synthea patients.csv file into format compatible with Example Health.
--
-- Usage:
--   1. set working directory to Synthea project
--   2. run "sqlite3 < transformPatients.sql"
--
-- Input:  patients.csv
-- Output: sh_patients.csv
--
-- Dependencies:
--   1. Update the starting patient number in the SELECT statement before running this.
--

-- Read input file

.mode csv
.import output/csv/patients.csv patients
.import output/csv/sh_variables.csv sh_variables

-- Transform CSV file.
--   * Assign integer patient ids.  Keep patient UUID for use in joins done by the other transformations.
--   * Truncate columns.
--   * Set columns not produced by Synthea to blank.

CREATE TABLE SH_PATIENTS AS 
  SELECT ROW_NUMBER() OVER(ORDER BY Id) AS PATIENTID,
         ID,
         "" AS USERNAME,
         BIRTHDATE AS DATEOFBIRTH,
         REPLACE(SSN,'-','') AS INSCARDNUMBER,
         SUBSTR(FIRST,1,20) AS FIRSTNAME,
         SUBSTR(LAST,1,20) AS LASTNAME,
         SUBSTR(ADDRESS,1,20) AS ADDRESS,
         SUBSTR(CITY,1,20) AS CITY,
         ZIP AS POSTCODE,
         " " AS PHONEMOBILE,
         " " AS EMAILADDRESS
         FROM PATIENTS WHERE DEATHDATE = '';

-- Update patient id above last id

UPDATE SH_PATIENTS 
  SET PATIENTID = PATIENTID + (SELECT LASTPATIENTID FROM SH_VARIABLES);

-- Assign userids

UPDATE SH_PATIENTS 
  SET USERNAME = "USER" || PATIENTID;

-- Open output file

.headers on
.output output/csv/sh_patients.csv

-- Output table

SELECT * FROM SH_PATIENTS;

.exit