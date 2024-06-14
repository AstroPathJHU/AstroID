/*

------------------------------
-- patch the Clinical tier
------------------------------
drop table if exists PID3130_clinical_tier
--
select a1.*, a2.leftstudy___1, leftstudy___2, leftstudy___3, leftstudy___4, leftstudy___5, leftstudy_COMBINED, leftstudy_other, notes_event
into PID3130_clinical_tier
from PID3130_clinical_tier_Part_01 a1, PID3130_clinical_tier_Part_02 a2
where a1.astropath_id=a2.astropath_id
  and a1.redcap_repeat_instrument=a2.redcap_repeat_instrument
  and a1.redcap_repeat_instance=a2.redcap_repeat_instance
go

*/



drop procedure if exists spMergeParts
go
--
create procedure spMergeParts (@table varchar(128), @dbg int=0)
--------------------------------------------------------------------
-- Stored procedure to merge a table split into two partitions
-- by the Redcap export tool
-- Alex Szalay, Baltimore, 12-09-2023
--------------------------------------------------------------------
as begin
	--
	set nocount on
	--------------------------------------------------
	-- only execute if this is a partitioned table
	-- with exactly two partitions
	--------------------------------------------------
	declare @c int
	select @c = count(*) 
	from sys.tables
	where name like @table+'%'
	  and name like '%Part%'
	-----------------------------------
	-- test the number of partitions
	-----------------------------------
	if (@c=0)
	begin
		print 'Table '+@table+' does not have partitions'
		return
	end
	if (@c>2)
	begin
		print 'Table '+@table+' has '+cast(@c as varchar(4)) +' partitions'
		return
	end
	-------------------------------
	-- extract the list of columns
	-------------------------------
	declare @cols table(name varchar(128), part smallint, col varchar(64), column_id int)
	--
	insert @cols
	select t.name, cast(replace(t.name,@table+'_Part_','') as int) part, 
		   c.name as col, column_id
	from sys.tables t, sys.columns c
	where t.object_id=c.object_id
	  and t.name like '%'+@table+'_Part%'
	-------------------------------------------------------
	-- get column names shared between the partitions
	-------------------------------------------------------
	declare @shared table(col varchar(64))
	--
	insert @shared
	select col from @cols
	group by col
	having count(*)>1
	----------------------------------
	-- build the dynamic SQL command
	----------------------------------
	declare @sql varchar(max)=''
	------------------------------
	-- create the drop coommand
	------------------------------
	select @sql = @sql+'drop table if exists '+@table+'; '
	-------------------------
	-- add the column list
	-------------------------
	select @sql = @sql+'select a1.*, a2.'
	select @sql = @sql+string_agg(col,', a2.') 
	from @cols
	where col not in (select col from @shared)
	  and part=2
	------------------------------
	-- add destination table
	------------------------------
	select @sql = @sql+' into '+@table
	-------------------------
	-- add the join targets
	-------------------------
	select @sql = @sql+' from '+ string_agg([name] + ' a'+x.part,', ')
	from (
		select t.name, substring(t.name,len(t.name),1) part
		from sys.tables t
		where t.name like @table+'%'
		  and t.name like '%Part%'
	) x
	-------------------------
	-- add the join clauses
	-------------------------
	select @sql = @sql + ' where '+string_agg('a1.'+col+'=a2.'+col,' and ') from @shared
	----------------------------
	-- execute with try.. catch
	----------------------------
	begin try
		exec(@sql)
	end try
	begin catch
		print 'ERROR: '+@sql
	end catch
	---------------
	-- for debug
	---------------
	if @dbg>0
		print @sql
	---------------
end
go

-- tests:

spMergeParts 'PID3130_patient_tier'
spMergeParts 'PID3130_clinical_tier'
spMergeParts 'PID3130_clinical_tier',1

select * from PID3130_clinical_tier


/*

-----------------------------------------------------------
-- patch the Clinical tier (original handwritten join)
-----------------------------------------------------------
drop table if exists PID3130_clinical_tier
--
select  a1.*, a2.leftstudy___1, leftstudy___2, leftstudy___3, 
		leftstudy___4, leftstudy___5, leftstudy_COMBINED, leftstudy_other, notes_event
into PID3130_clinical_tier
from PID3130_clinical_tier_Part_01 a1, PID3130_clinical_tier_Part_02 a2
where a1.astropath_id=a2.astropath_id
  and a1.redcap_repeat_instrument=a2.redcap_repeat_instrument
  and a1.redcap_repeat_instance=a2.redcap_repeat_instance
go

*/

