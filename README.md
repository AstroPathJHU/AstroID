# AstroID

Code for exporting clinical data from a REDCap build in AstroID format and pushing it into a MSSQL database. Note MSSQL uses `t-SQL`.

## Contents

- *create_recap_tables_in_sql.ipynb*
  - Jupyter Notebook with code to export data from a REDCap build in *AstroID* format and import it into a temporary SQL database
- *REDCap-SQL*
  - Directory with scripts to parse *redcap* tables from *ipynb* script SQL output tables and create more user-friendly SQL tables for analysis
- *examples*
  - A folder with example analysis scripts using the SQL tables generated from *REDCAP-SQL* step and *AstroID*
  - example 1 (*densities*): aggregates cell type densities from an experimental database and pairs it to clinical data in a separate clinical database generated from a REDCap build in AstroID format
  - example 2 (*irb report*): aggregates data from a clinical database generated from a REDCap build in *AstroID* format that could be used for an IRB report 

## Directions for export from REDCap into SQL

- Clone the repository locally: `git checkout https://github.com/AstroPathJHU/AstroID.git`
- Open and run the Jupyter Notebook 'create_recap_tables_in_sql.ipynb' according to the directions inside.
  - This will generate the following SQL tables in a database:
    - redcap_instrument
    - redcap_metadata
    - redcap_record
    - redcap_log
    - redcap_{tier_name}
      - e.g. A separate table for each tier: redcap_patient_tier, redcap_diagnosis_tier, redcap_clinical_tier, redcap_specimen_tier, redcap_block_tier, redcap_slide_tier
- Next, use the SQL scripts in the *REDCap-SQL* directory to generate tables that are more user-friendly for downstream analysis. The scripts are named `R<NN>`, indicating the order in which to run the scripts. There is a `README.txt` with additional instructions in that folder, and the scripts contain additional inline comments.

## Example Queries

There are two example queries in the *examples* folder.

- example 1 (*densities*)
  - Aggregates cell type densities from an experimental database and pairs it to clinical data in a separate clinical database generated from a REDCap build in AstroID format.
  - Contains a simple ".sql" script which can be run in a SQL management studio and outputs in ".csv" files.
- example 2 (*irb report*)
  - Aggregates data from a clinical database generated from a REDCap build in AstroID format that could be used for an IRB report.
  - Contains a ".sql" script that creates a function `dbo.fGetIRBReport()` which can be run as `select * from fGetIRBReport()` once the function is loaded into the database. It also contains an example "csv" output


