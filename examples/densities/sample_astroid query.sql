-------------------------------------------------------------
-- Get cell densities with response status using AstroID
-- clinical database and experimental data AstroPath database
-------------------------------------------------------------

-------------------------------------------------------------
-- Temporary table of the response status for each slide
-- using the clinical database generated with astroid
-- (called 'astropath' here).
-------------------------------------------------------------
IF OBJECT_ID('tempdb..#clinical') IS NOT NULL
	DROP TABLE #clinical
GO
--
SELECT s.astro_sl AS astroid, s.sl_label, r.response_general AS response
INTO #clinical
FROM astropath.dbo.slide s, astropath.dbo.clinical c, (
		SELECT astropt, response_general
		FROM astropath.dbo.clinical
		WHERE response_general != ''
	) r
WHERE s.astro_sl LIKE c.astro_cl + '%' 
AND c.astropt = r.astropt
AND c.biopsy_setting = 'Pre-treatment'
-------------------------------------------------------------
-- Note that we have selected only the slides from
-- pre-treatment biopsies. Retrieving both the appropriate
-- slide and it's corresponding response data requires
-- selecting the clinical event corresponding to when the
-- pre-treatment biopsy was taken and the event corresponding
-- to when the response status was determined respectively.
--
-- Next, combine with the experimental database and for each
-- sample compute the area and density of each cell phenotype
-- in mm2
-------------------------------------------------------------
SELECT astroid, response, phenotype,
	ganno.STArea() * 2.5e-7 as [area (mm2)],
	cast(count(*) AS FLOAT) / (ganno.STArea() * 2.5e-7) AS [cells per mm2]
FROM #clinical cl, wsi02.dbo.celltag c, wsi02.dbo.phenotype p,
	wsi02.dbo.samples s, wsi02.dbo.annotations a
WHERE p.ptype = c.ptype
AND c.sampleid = a.sampleid
AND c.sampleid = s.sampleid
AND cl.sl_label = s.slideid
AND a.lname = 'good tissue'
GROUP BY astroid, cl.response, p.phenotype, a.ganno.STArea()
ORDER BY 1,3
-------------------------------------------------------------
-- We can also easily include pd1 and pdl1 status per cell
-------------------------------------------------------------
SELECT astroid, response, phenotype, pd1, pdl1,
	ganno.STArea() * 2.5e-7 as [area (mm2)],
	cast(count(*) AS FLOAT) / (a.ganno.STArea() * 2.5e-7) AS [cells per mm2]
FROM #clinical cl, wsi02.dbo.celltag c, wsi02.dbo.phenotype p,
	wsi02.dbo.samples s, wsi02.dbo.annotations a
WHERE p.ptype = c.ptype
AND c.sampleid = a.sampleid
AND c.sampleid = s.sampleid
AND cl.sl_label = s.slideid
AND a.lname = 'good tissue'
GROUP BY astroid, response, phenotype, pd1, pdl1, a.ganno.STArea()
ORDER BY 1,3
/*
run time: ~ 5 seconds
total cells: 60,249,825
*/