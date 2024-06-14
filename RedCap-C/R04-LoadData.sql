--===========================================================
-- create the data tables withe schema and transfer the data 
-- Alex Szalay, 2024-04-10
-------------------------------------------------------------
set nocount on;
go


----------------------------------------------------
-- write a code to check foreigh and primary keys
-- before loading
---------------------------------------------------

--=============
-- spMakeTier
--=============
drop procedure if exists spMakeTier
go
--
create procedure spMakeTier(@tier varchar(32))
as begin
	-----------------------------------------------------------------------
	-- build the table schema for a single tier from LoadColumns, PKeys
	-----------------------------------------------------------------------
	set nocount on
	print 'spMakeTier '+@tier
	---------------------------------------
	-- capitalize first letter of the tier
	---------------------------------------
	set @tier = UPPER(LEFT(@tier,1))+LOWER(SUBSTRING(@tier,2,LEN(@tier)))
	declare @tiername varchar(256)
	set @tiername = @tier
	---------------------
	-- define command
	---------------------
	declare @sql nvarchar(max), @nullable varchar(32)
	select @sql = 'drop table if exists '+ @tiername+ ';' 
	select @sql = @sql+'create table '+ @tiername+ '(' 
	--
	select @sql=@sql+sqlrow
	from (
		select tier, min(column_id) column_no,
			case when min(iskey)=0 then '_' else '' end+col+' '
			+ min(dest_dtype)			
			+ case when min(iskey)=0 then ' NULL,' else ' NOT NULL,' end sqlrow
		from LoadColumns
		where tier = @tier
		  and col not like '%_tier_complete'
		  and col not like 'redcap_repeat_%'
		group by tier, col
	) x
	order by column_no
	--
	select @sql=@sql+ 'PRIMARY KEY ('+pkey+') )' from PKeys where tier=@tier
	exec(@sql)
	----------------------
	-- write a debug log
	----------------------
	insert redcap.debug select @tier, 'spMakeTier', cast(@sql as varchar(max)), getdate()
	--
end
go


--================
-- spMakeSchema
--================
drop procedure if exists spMakeSchema
go
--
create procedure spMakeSchema
as begin
	--------------------------------------------
	-- make the whole schema for all the tiers
	--------------------------------------------
	set nocount on
	--
	print 'Executing spMakeSchema'
	--
	declare @n int, @max int, @tier varchar(20)
	select @n=0, @max=max(tierid) from tiers
	while(@n<@max)
	begin
		select top 1 @n=tierid, @tier=tier
		from Tiers
		where tierid>@n
		order by tierid
		--
		--print 'starting '+@tier
		exec spMakeTier @tier
		print '  finished '+@tier
	end
	--
end
go


--==============
-- fCastColumn
--==============
drop function if exists dbo.fCastColumn
go
--
create function dbo.fCastColumn(@tier varchar(32), @dest varchar(32))
returns varchar(8000) 
as begin
	---------------------------------------------------
	-- function to cast source columns to the target
	-- it can be called as
	--
	-- select dbo.fCastColumn(tier,col) from LoadColumns group by tier, col
	---------------------------------------------------
	declare @sql varchar(8000)='', @two bigint = 2
	declare @dtype varchar(32), @ctype varchar(32), @cdest varchar(128)
	--set @cdest = 'isnull('+@dest+','''')'
	set @cdest = @dest
	---------------------------------
	-- get the data and column types
	---------------------------------
	select @dtype = dest_dtype, @ctype=ctype
	from LoadColumns
	where tier= @tier
	  and col = @dest
	--------------
	-- checkbox
	--------------
	if @ctype='checkbox'
	begin
		select @sql=@sql+' cast(isnull('
			+colname+','''') as int)*power(@two,'
			+cast(item-1 as varchar(3))+')+'
		from LoadColumns
		where tier=@tier
		  and col=@dest
		--
		set @sql = substring(@sql,1,len(@sql)-1)
	end
	------------------------------------------------
	-- convert to date (do not change the NULLs)
	------------------------------------------------
	else if @dtype='date'
		select @sql=@sql+' try_cast('+@dest+' as date)'
	---------------------
	-- convert to real
	---------------------
	else if @dtype='real'
		select @sql=@sql+' try_cast('+@cdest+' as real)'
	---------------------
	-- convert to int
	---------------------
	else if @dtype='real'
		select @sql=@sql+' try_cast('+@cdest+' as int)'
	else 
		select @sql = @sql+' '
	-----------------------------------
	-- add the attribute name, finally
	-----------------------------------
	select @sql = @sql + ' '+@dest
	return @sql
	--
end
go



--================
-- spLoadTier
--================
drop procedure if exists spLoadTier
go
--
create procedure spLoadTier (@tier varchar(32))
as begin
	-------------------------------------
	-- load the data for a single tier
	-------------------------------------
	set nocount on
	print 'spLoadTier '+@tier
	--
	declare @tiername varchar(256)
	set @tiername = @tier
	declare @sql varchar(max)='declare @two bigint = 2; truncate table '+@tiername+';'
	select @sql = @sql +' insert '+@tiername+' select'
	--
	-- ##################################################
	-- break into separatate agg strings for each tier
	-- ########################################$########
	select @sql= @sql+strg
	from (
		select tier, string_agg(s,',') within group (order by column_no) as strg
		from (
			select tier, col, min(column_id) column_no, cast(dbo.fCastColumn(tier,col) as varchar(max)) s
			from LoadColumns
			where tier=@tier
			  and col not like '%_tier_complete'
		      and col not like 'redcap_repeat_%'
			group by tier, col
		) x
		group by tier
	) y
	--
	set @sql = @sql+' from '+'redcap.'+@tier+'_tier'
	----------------------
	-- write a debug log
	----------------------
	insert redcap.debug select @tier, 'spLoadTier', cast(@sql as varchar(max)), getdate();
	-------------
	-- execute
	------------
	exec(@sql)
	--
end
go


--================
-- spLoadTables
--================
drop procedure if exists spLoadTables
go
--
create procedure spLoadTables
as begin
	--------------------------------------------
	-- make the whole schema for all the tiers
	--------------------------------------------
	set nocount on
	--
	print 'Execute spLoadTier'
	--
	declare @n int, @max int, @tier varchar(20)
	select @n=0, @max=max(tierid) from tiers
	while(@n<@max)
	begin
		select top 1 @n=tierid, @tier=tier
		from Tiers
		where tierid>@n
		order by tierid
		--
		exec spLoadTier @tier
		print '  finished '+ @tier
	end
	--
end
go





exec spMakeSchema
go
exec spLoadTables
go
--exec spMakeAstroPathView
go

/*

select * from redcap.debug


select * from LoadColumns
where tier='patient'
order by column_id

truncate table patient; 
declare @two bigint = 2; 
--insert patient 
select  astropt,  institution_id,  institution_other,  first_name,  last_name,  mrn,  mrn_other,  e_id, try_cast(dob as date) dob, try_cast(dob_cdp as date) dob_cdp,  sex,  gender,  gender_other,  ethnicity,  ethnicity_cdp,  race, cast(isnull(comorbidities___1,'') as int)*power(@two,0)+ cast(isnull(comorbidities___2,'') as int)*power(@two,1)+ cast(isnull(comorbidities___3,'') as int)*power(@two,2)+ cast(isnull(comorbidities___4,'') as int)*power(@two,3)+ cast(isnull(comorbidities___5,'') as int)*power(@two,4)+ cast(isnull(comorbidities___6,'') as int)*power(@two,5)+ cast(isnull(comorbidities___7,'') as int)*power(@two,6)+ cast(isnull(comorbidities___8,'') as int)*power(@two,7) comorbidities,  autoimmune,  autoimmune_tx,  autoimmune_tx_specify,  chronic_immunodeficiency,  hiv_cd4,  chronic_steroid_indication,  chronic_steroid_90days,  solid_tumor_specify, cast(isnull(heme_ca___1,'') as int)*power(@two,0)+ cast(isnull(heme_ca___2,'') as int)*power(@two,1)+ cast(isnull(heme_ca___3,'') as int)*power(@two,2) heme_ca,  heme_ca_other,  comorbidities_other,  melanoma_risk_yn, cast(isnull(melanoma_risk___1,'') as int)*power(@two,0)+ cast(isnull(melanoma_risk___2,'') as int)*power(@two,1)+ cast(isnull(melanoma_risk___3,'') as int)*power(@two,2)+ cast(isnull(melanoma_risk___4,'') as int)*power(@two,3)+ cast(isnull(melanoma_risk___5,'') as int)*power(@two,4) melanoma_risk,  nsclc_risk_yn, cast(isnull(nsclc_risk___1,'') as int)*power(@two,0)+ cast(isnull(nsclc_risk___2,'') as int)*power(@two,1)+ cast(isnull(nsclc_risk___3,'') as int)*power(@two,2) nsclc_risk,  smoker_current, try_cast(smoker_packyears as real) smoker_packyears,  risk_factors,  ecog,  notes_patient 
from redcap.patient_tier

*/
