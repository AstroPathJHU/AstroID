# AstroID
A package for pulling clinical data from an AstroID REDCap build and pushing it into a MSSQL database

## Directions

- Clone the repository locally: `git checkout https://github.com/AstroPathJHU/AstroID.git`
- Open and run the Jupyter Notebook 'create_recap_tables_in_sql.ipynb' according to the directions inside
  - This will generate the following SQL tables in a database:
    - redcap_instrument
    - redcap_metadata
    - redcap_record
    - redcap_log
    - redcap_{tier_name}
      - e.g. A separate table for each tier: redcap_patient_tier, redcap_diagnosis_tier, redcap_clinical_tier, redcap_specimen_tier, redcap_block_tier, redcap_slide_tier
- Next, use the SQL code in RedCap-C directory accoding to the README.txt instructions in that folder and inline comments in the associated SQL scripts
