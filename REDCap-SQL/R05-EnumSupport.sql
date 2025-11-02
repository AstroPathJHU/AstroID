use Astropath
go
--

drop procedure if exists spDropComputedColumns
go
--
create procedure spDropComputedColumns
as begin
	-------------------------------------------
	-- drop computed columns for all tiers
	-------------------------------------------
	set nocount on
	--
	declare @sql table(n int, tier varchar(32), col varchar(32), cmd varchar(max))
	declare @n int, @max int, @cmd varchar(max)
	-------------------------------------------------------------
	-- create the dynamic sql for each column in the tables,
	-- except for the PK and FK, and redcap_ , and _other
	-------------------------------------------------------------
	insert @sql
	select n, tier, col, 'alter table '+tier+' drop column if exists '+col+';'
	from (	
		select tier, col, row_number() over (order by tier, min(column_id)) n
		from LoadColumns
		where iskey=0
		  and col not like '%_complete'
		  and col not like 'redcap_repeat_%'
		  and col not like '%_other'
		group by tier, col
	) x
	order by n	
	----------------------
	-- write a debug log
	----------------------
	insert redcap.debug
	select tier, 'spDropComputedColumns:'+col, cmd, getdate()
	from @sql
	--
	select @n=0, @max=max(n) from @sql
	--
	while(@n<@max)
	begin
		select top 1 @n=n, @cmd=cmd
		from @sql
		where n>@n
		order by n
		--		
		exec(@cmd)
		--
	end
	--
end
go

exec spDropComputedColumns
go


--=============
-- dbo.fEnum
--=============
drop function if exists dbo.fEnum
go
--
create function dbo.fEnum(@col varchar(32), @val bigint)
returns varchar(8000)
as begin
	--------------------------------------------------------
	-- return the enumerated values in plain text, which 
	-- correspond to an integer valued enumerated column @val
	--------------------------------------------------------
	declare @out varchar(8000)
	--
	declare @ctype varchar(32)
	select top 1 @ctype=ctype 
	from Enum
	where col = @col
	--
	if @@rowcount=0
		return ''
	--
	if @ctype='checkbox'
		select @out = string_agg(e.enum,', ')
		from Mask m, Enum e
		where @val & mask>0
		  and e.item=m.item
		  and e.col = @col
	else if @ctype in ('radio', 'dropdown')
		select @out = enum
		from Enum e
		where @val=item
		  and e.col = @col
	--
	if @out is null
		return ''
	return @out
end
go

--===============
-- dbo.fEnumChar
--===============
drop function if exists dbo.fEnumChar
go
--
create function dbo.fEnumChar(@col varchar(32), @val varchar(16))
returns varchar(8000)
as begin
	--------------------------------------------------------
	-- return the enumerated values in plain text, which 
	-- correspond to an varchar valued enumerated column @val
	--------------------------------------------------------
	declare @out varchar(8000)
	--
	declare @ctype varchar(32)
	select top 1 @ctype=ctype 
	from Enum
	where col = @col
	--
	if @@rowcount=0
		return ''
	--
	if @ctype in ('radio', 'dropdown')
		select @out = enum
		from Enum e
		where @val=ikey
		  and e.col = @col
	--
	if @out is null
		return ''
	return @out
end
go



drop function if exists dbo.fGetCombined
go
--
create function dbo.fGetCombined(@tier varchar(32), @col varchar(32), @val bigint)
returns varchar(8000)
as begin
	------------------------------------------------------------
	-- return the array of bitmask values for a checkbox field
	-- corresponding to @val in plain text
	------------------------------------------------------------
	declare @out varchar(8000)
	--
	declare @ctype varchar(32)
	select top 1 @ctype=ctype 
	from Enum
	where tier=@tier
	  and col = @col
	--
	if @ctype='checkbox'
		select @out = '['+string_agg(cast(e.item as varchar(3)),',')+']'
		from Mask m, Enum e
		where @val & mask>0
		  and e.item=m.item
		  and e.tier=@tier
		  and e.col = @col
	--
	return @out
end
go

--===========
-- fOther
--===========
drop function if exists dbo.fOther
go
--
create function dbo.fOther(@col varchar(64))
returns varchar(2048)
as begin
	----------------------------------------------------------
	-- pad dynamic SQL generating the computed columns 
	-- with a string for @col+'_other' value
	-- @other becomes the name of the column with the _other postfix
	----------------------------------------------------------
	declare @out varchar(2048),@other varchar(64), @no int
	set @out=''
	begin
		select @other = @col+'_other'
		select @no=column_id from LoadColumns
		where col=@other
		if @@rowcount=0
			set @out= ''
		else
			set @out = '+(case when _'+@other+'<>'''' then '',''+_'+@other+' else '''' end)'
	end
	--
	return @out
	--
end
go


--==========
-- fCCol
--==========
drop function if exists fCCol
go
--
create function fCCol(@col varchar(64))
returns varchar(2048) 
as begin 
	--------------------------------------------------------------------
	-- Create the dynamic SQL string for defining a computed column.
	-- For enumerated types it will display the option labels.
	-- Accompanying '*_other' option are tagged to the end of the main column.
	-- Scalar columns are filtered for NULL values.
	----------------------------------------------------------------
	declare @sql varchar(max), @main varchar(256), @tier varchar(32), 
			@ischar tinyint, @iskey tinyint, @dtype varchar(16), @def varchar(16)
	------------------------------------------------------
	-- get the tier, the iskey value and the data type
	------------------------------------------------------
	select @tier = tier, @iskey=min(iskey), @dtype=min(dest_dtype)
	from LoadColumns
	where col=@col
	group by tier
	-------------------------------------------------------------
	-- set the default isnull value depending on the data type
	-------------------------------------------------------------
	select @def = '0'
	if @dtype like 'nvarchar%'
		set @def = ''''''
	----------------------------------------------------------------
	-- check if the enumeration option index is a number or a char.
	-- @ischar will be a NULL for non-enum columns
	----------------------------------------------------------------
	select @ischar=ischar from Enum
	where col=@col
	-----------------------------------
	-- @ischar is NULL, normal column
	-----------------------------------
	if @ischar is null
		--if @col in ('mrn','sp_id')
		--	select @main = '_'+@col
		select @main = 'isnull(_'+@col+','+@def+')'
	--------------------------------------------------------------
	-- handle the EPIC fields which have char options separately
	--------------------------------------------------------------
	else if @ischar=0
		select @main= 'dbo.fEnum('''+@col+''', _'+@col+')'
	else if @ischar=1
		select @main= 'dbo.fEnumChar('''+@col+''', _'+@col+')'
	--
	set @sql = 'alter table '+@tier+' drop column if exists '+@col+';'
		+' alter table '+@tier+' add '+@col+' as '
		+@main +dbo.fOther(@col)+';'
	--
	return @sql
	--
end
go


--=======================
-- spAddComputedColumns
--=======================
drop procedure if exists spAddComputedColumns
go
--
create procedure spAddComputedColumns
as begin
	----------------------------------------------------------------
	-- add computed columns for all the enumerated column types
	----------------------------------------------------------------
	set nocount on
	--
	declare @sql table(n int, tier varchar(32), col varchar(32), cmd varchar(max))
	declare @n int, @max int, @cmd varchar(max)
	-------------------------------------------------------------
	-- create the dynamic sql for each column in the tables,
	-- except for the PK and FK, and redcap_ , and _other
	-------------------------------------------------------------
	insert @sql
	select n, tier, col, dbo.fCCol(col) cmd
	from (	
		select tier, col, row_number() over (order by tier, min(column_id)) n
		from LoadColumns
		where iskey=0
		  and col not like '%_complete'
		  and col not like 'redcap_repeat_%'
		  and col not like '%_other'
		group by tier, col
	) x
	order by n	
	----------------------
	-- write a debug log
	----------------------
	insert redcap.debug
	select tier, 'spAddComputedColumns:'+col, cmd, getdate()
	from @sql
	--
	select @n=0, @max=max(n) from @sql
	--
	while(@n<@max)
	begin
		select top 1 @n=n, @cmd=cmd
		from @sql
		where n>@n
		order by n
		--		
		exec(@cmd)
		--
	end
	--
end
go

exec spAddComputedColumns
go


/*


select * from redcap.debug

alter table patient drop column if exists ethnicity_cdp; 

*/
