select * from LoadColumns

select * from Pkeys
select * from Fkeys


select * from Enum

select * from Fields


select c.*, p.*
from LoadColumns c, Fkeys p
where c.col=p.fkey



select * from Fkeys


ALTER TABLE Diagnosis ADD FOREIGN KEY (astropath_ID) REFERENCES Patient(astropath_ID);
ALTER TABLE Clinical ADD FOREIGN KEY (linked2dg) REFERENCES Diagnosis(astro_dg);

declare @sql varchar(max)=''
select @sql=@sql+'DROP CONSTRAINT IF EXISTS fk_'+tier+'_'+ptier+';' from FKeys
print @sql

declare @sql varchar(max)=''
select @sql=@sql+'ALTER TABLE '+tier+' ADD CONSTRAINT fk_'+tier+'_'+ptier+' FOREIGN KEY ('+fkey+') REFERENCES '+ptier+'('+pkey+') ON DELETE CASCADE ON UPDATE CASCADE;' from FKeys
print @sql


DROP CONSTRAINT fk_slide_block;
ALTER TABLE block DROP CONSTRAINT fk_block_specimen;
DROP CONSTRAINT IF EXISTS fk_specimen_clinical;
DROP CONSTRAINT IF EXISTS fk_clinical_diagnosis;
DROP CONSTRAINT IF EXISTS fk_diagnosis_patient;

select * from FKeys



ALTER TABLE slide ADD CONSTRAINT fk_slide_block FOREIGN KEY (linked2bl) REFERENCES block(astro_bl) ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE block ADD CONSTRAINT fk_block_specimen FOREIGN KEY (linked2sp) REFERENCES specimen(astro_sp) ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE specimen ADD CONSTRAINT fk_specimen_clinical FOREIGN KEY (linked2cl) REFERENCES clinical(astro_cl) ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE clinical ADD CONSTRAINT fk_clinical_diagnosis FOREIGN KEY (linked2dg) REFERENCES diagnosis(astro_dg) ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE diagnosis ADD CONSTRAINT fk_diagnosis_patient FOREIGN KEY (astropath_id) REFERENCES patient(astropath_id) ON DELETE CASCADE ON UPDATE CASCADE;




drop procedure if exists spDropForeignKeys
go
--
create procedure spDropForeignKeys
as begin
	--
	set nocount on
	--
	declare @sql varchar(max)
	select @sql = string_agg(s,'; ')
	from (
	select  'ALTER TABLE '+t.name+' DROP CONSTRAINT '+f.name s
	from sys.foreign_keys f, sys.tables t
	where t.object_id=f.parent_object_id
	) x
	exec(@sql)
	--
end
go


select * from sys.tables t




select * 
from SLide s
where b.astro_bl=s.linked2bl

select astropath_id, astro_sp from Specimen
select astropath_id, linked2sp from Block

select astropath_id, astro_bl from Block
select astropath_id, linked2bl, astro_sl from Slide


update slide
  set linked2bl='P200001_D01_C02_S01_B02', astro_sl='P200001_D01_C02_S01_B02_L02'
where linked2bl='P200001_D01_C02_S01_B01'

delete Block where linked2sp='P200001_D01_C02_S01'
delete Slide where linked2bl='P200001_D01_C02_S01_B02'


 -- Need to chaeck for consistency of Foreign keys
