--=====================================================================
-- Implement changes to the astropt datatype, and prefix with a 'P'
--=====================================================================

set nocount on

declare @isint bigint
select @isint = try_cast(astropt as bigint)
from redcap.patient_tier

if @isint is not null
begin 
	print 'bigint, converting to varchar with a P prefix'
	--	
	update redcap.patient_tier
	  set astropt = 'P'+astropt

	update redcap.diagnosis_tier
	  set astropt = 'P'+astropt

	update redcap.clinical_tier
	  set astropt = 'P'+astropt

	update redcap.specimen_tier
	  set astropt = 'P'+astropt

	update redcap.block_tier
	  set astropt = 'P'+astropt

	update redcap.slide_tier
	  set astropt = 'P'+astropt
	--
	update redcap.metadata
	  set text_validation_type_or_show_slider_number =NULL
	where field_name='astropt'
	--
end
else
	print 'Already converted'
go

----------------------------------------------
-- change the datatype for the date fields, 
-- so that they handle NULLs gracefully
---------------------------------------------
update redcap.metadata
  set text_validation_type_or_show_slider_number =NULL
where text_validation_type_or_show_slider_number like 'date%'
go



