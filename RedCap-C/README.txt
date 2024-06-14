This directory contains the code for the RedCap conversion using Ben's export.
Import source is AstroPathXfer, target is AstroPath
Modules:
R01 -- Wipes the Astropath DB completely clean
R02 -- Close the source database, import raw data into the redcap schema
R02.1 -- Patch the inconsistent astroid, prefix with a P, may not be necessary later
R03 -- Create the LoadColumns table, assemble all metadata to build computed columns
R04 -- Load the data into the columns
R05 -- Build the support to resolve enumerated fields, create computed columns
R06 -- still not active, need to sync with Scott and Ben.
Libby-reports-03-EW-04.05.2024.sql -- the file with test queries
