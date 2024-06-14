USE AstroPath
go


/*
====================================================
1. Basic demographic information
-	First name: first_name
-	Last name: last_name
-	JHU MRN or non-JHU MRN: mrn, mrn_other
-	DOB: dob
-	Sex assigned at birth: sex
-	Gender identity: gender, gender_other
-	Ethnicity: ethnicity
-	Race: race
===================================================
*/

select astropt, first_name, last_name
	, mrn
	, dob
	, sex
	, gender
	, gender 
	, ethnicity
	, race race
from Patient p

/*
===================================================
2. IRB data for continuing review: pathology team
-	First name: first_name
-	Last name: last_name
-	DOB: dob
-	Sex assigned at birth: sex
-	Gender identity: gender, gender_other
-	Clinical entry date: clinical_date
-	AstroSpecimen ID: astro_sp
===================================================
*/


select p.astropt, first_name, last_name, dob
	, sex
	, gender
	, sp_generating_yn
	, clinical_date
from  patient p
	, diagnosis d 
	, clinical c
	, specimen q
where p.astropt= d.linked2pt
  and d.astro_dg = c.linked2dg
  and q.linked2cl = c.astro_cl

/*
===================================================
  3. Specimens by anatomic category
-	JHU MRN: mrn
-	Cancer site of origin: ca_subtype, ca_origin_site, 
		ca_origin_site_other, ca_cutaneous, melanoma_subtype, 
		melanoma_subtype_other, melanoma_primary_icd
-	AstroSpecimen: astro_sp
-	JHU or non-JHU specimen ID: sp_id, sp_id_other
-	Anatomic site of origin for specimen: sp_anatomic_origin, 
		sp_source_other, sp_anatomic_origin_detail
===================================================
*/

select p.astropt, first_name, last_name, DOB
	, mrn
	, sex
	, gender
	, ca_subtype				--/ NULL
	, sp_generating_yn
	, clinical_date
	, astro_sp
	, sp_id
	, ca_origin_site
	, ca_cutaneous
	, melanoma_subtype
	, melanoma_primary_icd
	, sp_anatomic_origin
	, sp_source
from  patient p
	, diagnosis d 
	, clinical c
	, specimen q
where d.linked2pt = p.astropt
  and c.linked2dg = d.astro_dg
  and q.linked2cl = c.astro_cl

/*
===================================================
4a. Survival data  
Basic Info
-	First name: first_name
-	Last name: last_name
-	JHU or non-JHU MRN: mrn, mrn_other
-	DOB: dob
-	Age at diagnosis: dx_age
-	Sex assigned at birth: sex
-	Cancer site of origin: ca_subtype, ca_origin_site, 
		ca_origin_site_other, ca_cutaneous, melanoma_subtype, 
		melanoma_subtype_other, melanoma_primary_icd
o	Melanoma mutation at the time of diagnosis: 
		melanoma_mutation, braf, braf_other
===================================================
*/

select p.astropt, first_name, last_name, mrn, DOB, dx_age
	, sex sex
	, ca_subtype
	, ca_origin_site
	, ca_cutaneous
	, melanoma_subtype
	, melanoma_primary_icd
	, melanoma_mutation
	, braf
from  patient p
	, diagnosis d 
	, clinical c
	, specimen q
where d.linked2pt = p.astropt
  and c.linked2dg = d.astro_dg
  and q.linked2cl = c.astro_cl

/*
===================================================
4b. Survival data  
-	Clinical entry type: clinical_type
-	Clinical entry date: clinical_date
-	Death data: death_date_lastfu, death_relationship, death_tx_related
-	Left study data: leftstudy, leftstudy_other
===================================================
*/


select p.astropt, first_name, last_name, mrn, DOB, dx_age, sex
	---------------------------------------------------------------------------
	, clinical_type
	, clinical_date
	, death_date_lastfu
	, death_relationship
	, death_tx_related
	, leftstudy
	---------------------------------------------------------------------------
from  patient p
	, diagnosis d 
	, clinical c
	, specimen q
where d.linked2pt = p.astropt
  and c.linked2dg = d.astro_dg
  and q.linked2cl = c.astro_cl


/*
===================================================
4c. Specimen Data
-	Specimen ID: astro_sp
-	JHU or non-JHU specimen ID: sp_id, sp_id_other
-	Age at collection: collection_age
-	Anatomic site of origin for specimen: 
		sp_anatomic_origin, sp_source_other, sp_source_charac(?)
===================================================
*/

select p.astropt, first_name, last_name, mrn, DOB, dx_age, sex
	-------------------------------------------------------------------------
	, astro_sp
	, sp_id
	, collection_age
	, sp_anatomic_origin
	, sp_source
	-------------------------------------------------------------------------
from  patient p
	, diagnosis d 
	, clinical c
	, specimen q
where d.linked2pt = p.astropt
  and c.linked2dg = d.astro_dg
  and q.linked2cl = c.astro_cl


/*
===================================================
4d. Clinical / Pathologic Staging

-	Initial clinical staging at diagnosis: 
		stage_change_methvers, initial_cstage_t, initial_cstage_n, 
		initial_cstage_m, initial_cstage
-	Clinical entry resulted in change in clinical staging: 
		stage_change, stage_change_methvers, stage_change_t, 
		stage_change_n, stage_change_m, stage_change_final
		 
-	Pathologic staging: pathstage_methvers, pathstage_t, 
		pathstage_n, pathstage_m
===================================================
*/

select p.astropt, first_name, last_name, mrn, DOB, dx_age, sex
	----------------------------------------------------------------------------
	, initial_cstage_methvers
	, initial_cstage
	, initial_cstage_t
	, initial_cstage_n
	, initial_cstage_m
	, stage_change
	, stage_change_methvers
	, stage_change_t
	, stage_change_n
	, stage_change_m
	, stage_change_final
	, pathstage_yn
	, pathstage_methvers
	, pathstage_t
	, pathstage_n
	, pathstage_m
	-------------------------------------------------------------
from  patient p
	, diagnosis d 
	, clinical c
	, specimen q
where d.linked2pt = p.astropt
  and c.linked2dg = d.astro_dg
  and q.linked2cl = c.astro_cl



/*
===================================================
4e. Biopsy / Surgery / Treatment Data
-	Biopsy data: biopsy_type
-	Surgery data: surgery_type
-	Treatment data: tx, tx_io, tx_io_other, tx_chemo, tx_chemo_other, 
		tx_targeted, tx_targeted_other, tx_targeted_meki, tx_targeted_brafmeki, 
		tx_iotargeted, tx_iotargeted_other, tx_dosing, tx_administration, 
		tx_setting, tx_clinicaltrial, tx_clinicaltrial_specify
===================================================
*/

select p.astropt, first_name, last_name, mrn, DOB, dx_age, sex
	----------------------------------------------
	, biopsy_type
	, surgery_type
	, tx
	, tx_io
	, tx_chemo
	, tx_targeted
	, tx_targeted_meki
	, tx_targeted_brafmeki
	, tx_iotargeted
	, tx_dosing
	, tx_administration
	, tx_setting
	, tx_clinicaltrial+' ' + tx_clinicaltrial_specify tx_clinicaltrial
from  patient p
	, diagnosis d 
	, clinical c
	, specimen q
where d.linked2pt = p.astropt
  and c.linked2dg = d.astro_dg
  and q.linked2cl = c.astro_cl

/*
===================================================
4f.  Clinical / Pathologic Response, Adverse Events
-	Clinical entry resulted in response assessment: 
		response_methvers_other, response_date, response_determination, 
		response, response_simplified, clinical_benefit
-	Pathologic response: path_response, path_response_other
-	Adverse event data: ae_1, ae_1_other, ae_grade_1, ae_txchange_1, 
		ae_txchange_detail_1, ae_2, ae_2_other, ae_grade_2, ae_txchange_2, 
		ae_txchange_detail_2, ae_3, ae_3_other, ae_grade_3, ae_txchange_3, 
		ae_txchange_detail_3
===================================================
*/

select 
	  p.astropt, first_name, last_name, mrn, DOB, dx_age, sex
	-----------------------------------------------
	, response_methvers
	, response_date
	, response_determination
	, response_yn
	, response_simplified
	, clinical_benefit
	--, recist_target_header --	(missing)
	--, recist_1_1_target_table	(missing)
	--, recist_1_1_target_total	(missing)
	--, recist_percentchange 
	--, recist_1_1_target_assess	(missing)
	--, recist_1_1_nontarget_table	(missing)
	, nontarget_response_1
	, overall_recist_response
	, overall_irecist_response
	--------------------------------------------------
	, path_response
	-------------------------------
	, ae_1 
	, ae_grade_1
	, ae_txchange_1
	, ae_txchange_detail_1
	, ae_2
	, ae_grade_2   
	, ae_txchange_2
	, ae_txchange_detail_2
	, ae_3 
	, ae_grade_3
	, ae_txchange_3 
	, ae_txchange_detail_3
	--------------------------------------------------
from  patient p
	, diagnosis d 
	, clinical c
	, specimen q
where d.linked2pt = p.astropt
  and c.linked2dg = d.astro_dg
  and q.linked2cl = c.astro_cl
  

