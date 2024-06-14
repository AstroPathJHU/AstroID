-----------------------------------
-- delete theimorted tier tables
-----------------------------------
drop table if exists redcap.block_tier
drop table if exists redcap.clinical_tier
drop table if exists redcap.diagnosis_tier
drop table if exists redcap.patient_tier
drop table if exists redcap.slide_tier
drop table if exists redcap.specimen_tier
go

-------------------------------------------------------
-- add the linked2pt field to the redcap.record table
-- and then update its value to astropath_id
-------------------------------------------------------
alter table redcap.record add linked2pt varchar(max);
go
--
update redcap.record
  set linked2pt=astropath_id
where redcap_repeat_instrument ='diagnosis_tier'
go
-------------------------------------------------
-- update the tier designator in redcap.record
-- where it is NULL
-------------------------------------------------
update r
  set redcap_repeat_instrument='patient_tier', redcap_repeat_instance=0
from redcap.record r
where redcap_repeat_instance is null
go

-----------------------------------------------------------------------------
-- patch the redcap.metadata, add the linked2pt field for the foreign key
-----------------------------------------------------------------------------
insert redcap.metadata values('linked2pt','diagnosis_tier','<center><big>Diagnosis Tier Data</big></center>','sql',
	'AstroPath_Id','select a.value from [data-table] a where a.project_id = [project-id] and a.record = [record-name] and a.field_name = ''astropath_id''',
	NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL)
go

-----------------------------------
-- read the ground truth schema
-----------------------------------
drop table if exists dbo.Astropath_Schema
--
create table AstroPath_Schema (
	id int NOT NULL,
	tier varchar(32) NOT NULL,
	col varchar(128) NOT NULL
)
--
bulk insert AstroPath_Schema from '\\bki02\c$\BKI\sql\RedCap-B\Astropath_Schema.csv'
WITH (format='csv', FIELDTERMINATOR = ',', ROWTERMINATOR = '\n', firstrow=2);
go
-- 447
/*
------------------------------------
-- test the consistency
------------------------------------
drop table if exists #names
--
select column_id id, col.name
into #names
from sys.tables as tab, sys.columns as col,  sys.types as t
	where tab.schema_id in (select schema_id from sys.schemas where name = 'redcap')
	and tab.name = 'record'		
		and tab.object_id = col.object_id
		and col.user_type_id = t.user_type_id
-- 447

select count(*) from Astropath_Schema
-- 447

select * from Astropath_Schema
where col not in (select name from #names)
-- 0

select count(*) from #names 
where name not in (select col from Astropath_Schema)
-- 0
*/



/*


	
*/







