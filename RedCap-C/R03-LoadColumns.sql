--===========================================================
-- create the metadata tables necessary to create 
-- the schema for the new tables and transfer the data 
-- Alex Szalay, 2023-10-31
-------------------------------------------------------------
set nocount on;
go

--==================
-- spBuildMeta
--==================
drop procedure if exists spBuildMeta
go
--
create procedure spBuildMeta
as begin
	----------------------------------------------------
	-- build the schema script for the metadata tables:
	--     Tiers, PKeys, FKeys, LoadColumns, Fields
	----------------------------------------------------
	set nocount on
	--------------------
	-- build Tiers
	--------------------
	drop table if exists Tiers
	--
	create table Tiers (
		tierid int PRIMARY KEY NOT NULL,
		tier varchar(32) NOT NULL,
		label varchar(128) NOT NULL
	)
	--
	insert Tiers
	select  cast(substring(instrument_label,1,1) as int) tierid, 
			replace(instrument_name,'_tier','') tier,
			substring(instrument_label,5,100) label
	from redcap.instrument
	-------------------------------------
	-- create the table of Primary keys
	-------------------------------------
	drop table if exists PKeys 
	--
	create table PKeys (
		id int identity(1,1) NOT NULL,
		tier varchar(32) NOT NULL,
		pkey varchar(16) NOT NULL
	)
	--
	insert Pkeys values('patient','astropt')
	insert Pkeys values('diagnosis','astro_dg')
	insert Pkeys values('clinical','astro_cl')
	insert Pkeys values('specimen','astro_sp')
	insert PKeys values('block','astro_bl')
	insert Pkeys values('slide','astro_sl')
	-------------------------------------
	-- create the table of Foreign keys
	-------------------------------------
	drop table if exists FKeys 
	--
	create table FKeys (
		id int identity(1,1) NOT NULL,
		tier varchar(32) NOT NULL,
		fkey varchar(32) NOT NULL,
		ptier varchar(32) NOT NULL,
		pkey varchar(32) NOT NULL
	)
	--
	insert Fkeys values('slide','linked2bl','block','astro_bl')
	insert Fkeys values('block','linked2sp','specimen','astro_sp')	
	insert Fkeys values('specimen','linked2cl','clinical','astro_cl')
	insert Fkeys values('clinical','linked2dg','diagnosis','astro_dg')
	insert Fkeys values('diagnosis','linked2pt','patient','astropt')
	--
	print 'Created Tiers, PKeys, FKeys'
end
go

--==============
-- spBuildEnum
--==============
drop procedure if exists spBuildEnum
go
--
create procedure spBuildEnum
as begin
	----------------------------------------------
	-- create the table of the enumerated fields
	----------------------------------------------
	set nocount on
	---------------
	-- Enum
	---------------
	drop table if exists Enum
	--
	create table Enum (
		tier varchar(32) NOT NULL,	--/D the tier
		col varchar(32) NOT NULL,	--/D the name of the column
		ctype varchar(16) NOT NULL,	--/D the control type
		ikey varchar(16) NOT NULL,	--/D the numerical or varchar value of the choice
		item int NOT NULL,			--/D the numerical value of the option
		ischar tinyint NOT NULL,	--/D true for checkbox fields from EPIC
		enum varchar(128) NOT NULL	--/D the label of the enumeration
	)
	--
	insert Enum
	select replace(form_name,'_tier','') tier, 
		field_name col,  
		field_type ctype,
		substring(value,1,charindex(',',value)-1) ikey,
		row_number() over (partition by field_name order by field_name) item,
		0 ischar,
		ltrim(substring(value,charindex(',',value)+1, len(value))) enum
	from (
		select field_name, form_name, field_type, rtrim(ltrim(n.value)) value
		from redcap.metadata m
		cross apply string_split(select_choices_or_calculations,'|') n
		where field_type in ('dropdown', 'checkbox','radio')
	) x
	-----------------------------------------------------------------------
	-- mark the columns with non-numerical option in ikey (from EPIC)
	-----------------------------------------------------------------------
	update Enum
	  set ischar = 1
	where try_cast(ikey as int) is null
	--
	print 'Created Enum'
	--
end
go

--===============
-- spMakeMask
--===============
drop procedure if exists spMakeMask
go
--
create procedure spMakeMask
as begin
	-----------------------------------------------------
	-- precompute column values for the bimask fields
	-----------------------------------------------------
	set nocount on
	--
	drop table if exists Mask
	--
	create table Mask (
		item int NOT NULL,
		mask bigint NOT NULL,
		PRIMARY KEY (item)
	)
	--
	declare @two bigint=2
	declare @n int=0, @m bigint
	while(@n<63)
	begin
		insert Mask	select @n+1, power(@two,@n)
		set @n=@n+1
	end
	--
end
go

------------------------------
-- and execute right away
------------------------------
exec spMakeMask
go



drop procedure if exists spBuildLoadColumns
go
--
create procedure spBuildLoadColumns
as begin
	----------------------------------------------------
	-- build the schema script for the metadata tables:
	--     LoadColumns, Fields
	----------------------------------------------------
	set nocount on
	--------------------------------------------------------------------
	-- List all columns to be loaded, taken from redcap.*_tier.
	-- The field_type info is saved in ctype, taken from redcap.metadata
	--------------------------------------------------------------------
	drop table if exists #colnames
	--
	select *, case when pos=0 then colname else substring(colname,1, pos-1) end col
	into #colnames
	from (
		select cast(substring(r.instrument_label,1,1) as int) tierid, 
			replace(tab.name,'_tier','') tier, col.column_id, row_number() over (order by tab.name, col.column_id) column_no,
			col.name colname, col.max_length maxlen, t.name dtype, 'text' ctype,
			patindex('%[_][_][_]%',col.name) pos
		from sys.tables as tab, sys.columns as col,  sys.types as t, redcap.instrument r
		where tab.schema_id in (select schema_id from sys.schemas where name = 'redcap')
		  and tab.name = r.instrument_name
		  and tab.object_id = col.object_id
		  and col.user_type_id = t.user_type_id
	) x
	--------------------------------------------------------------
	-- now join with the names etc from the recap.metadata table
	--------------------------------------------------------------
	drop table if exists #loadcol
	--
	select n.tierid, n.tier,
		column_id, 
		n.colname, n.col, n.maxlen, n.dtype src_dtype, n.dtype dest_dtype, 
		isnull(m.field_type, 'text') ctype, 
		cast(0 as int) item,
		--cast(0 as int) ix,
		cast(0 as int) iskey,
		cast('' as varchar(max)) enum
	into #loadcol
	from #colnames n left outer join redcap.metadata m
	on n.col=m.field_name
	order by tierid,column_id
	------------------------------------
	-- mark the PK and FK as non-nullable
	------------------------------------
	update #loadcol
	  set iskey=1
	where colname in (select pkey from PKeys)
	--
	update #loadcol
	  set iskey=1
	where colname in (select fkey from Fkeys)
    and iskey=0
	------------------------------------------
	-- use redcap.metadata to extract info
	-- about enumerations etc
	------------------------------------------
	drop table if exists #meta
	--
	select --ID, 
		replace(form_name,'_tier','') tier, field_name colname, 
		field_type ctype, coalesce(text_validation_type_or_show_slider_number,'') validation, 
		'xxxxxxxxxx' dtype
	into #meta
	from redcap.metadata
	-----------------------------
	-- update the datatypes
	----------------------------
	update #meta
	  set dtype = case ctype 
		when 'dropdown' then 'int'
		when 'radio' then 'int'
		when 'checkbox' then 'bigint'
		when 'yesno' then 'bit'
		when 'text' then 'nvarchar'
		when 'notes' then 'nvarchar'
		when 'calc' then 'nvarchar'
		else 'nvarchar'
	  end
	where validation = ''
	--
	update #meta
	  set dtype = case validation
		when 'date_mdy' then 'date'
		when 'integer' then 'int'
		when 'number' then 'real'
		when 'alpha_only' then 'nvarchar'
		else 'nvarchar' 
	  end
	where validation<>''
	----------------------------------
	-- propagate these to #loadcol
	----------------------------------
	update a
	  set a.dest_dtype=b.dtype, a.ctype=b.ctype
	from #loadcol a, #Meta b
	where a.tier=b.tier
	  and a.col = b.colname
	-------------------------------------
	-- list of all columns to be loaded
	-------------------------------------
	drop table if exists LoadColumns
	--
	create table LoadColumns (
		tierid int NOT NULL,
		tier varchar(32) NOT NULL,
		column_id int NOT NULL,
		colname varchar(64) NOT NULL,
		col varchar(64) NOT NULL,
		maxlen int NOT NULL,
		src_dtype varchar(32) NOT NULL,
		dest_dtype varchar(32) NOT NULL,
		ctype varchar(32) NOT NULL,
		item varchar(16) NOT NULL,
--		ix smallint NOT NULL,
		iskey tinyint NOT NULL,
		enum varchar(1024) NOT NULL
	)
	insert LoadColumns
	select * from #loadcol
	order by tierid, column_id
	---------------------------------------------
	-- merge the Enumerations into LoadColumns
	---------------------------------------------
	update c
	   set c.item = e.item, c.enum=e.enum, c.ctype=e.ctype
	from LoadColumns c, (
		select tier, ctype, ikey, item, enum, col 
		from Enum
		where ctype='checkbox'
	) e
	where c.tier = e.tier
	  and c.colname  = e.col+'___'+e.ikey
	----------------------------------------------
	-- fix the varchar size for the primary keys
	-- they cannot be nvarchar(max)
	----------------------------------------------
	update c
	  set maxlen=64
	from LoadColumns c
	where c.colname in (select pkey from PKeys)
	  or c.colname in (select fkey from Fkeys)
	---------------------------------------
	-- fix the remaning dest_dtype values
	---------------------------------------
	update LoadColumns
	  set dest_dtype=src_dtype
	where dest_dtype='none'	
	------------------------------------------------------
	-- fix the column data type for radio buttons,
	-- where the ikey value is not an int, but a string
	------------------------------------------------------
	update c
		set c.dest_dtype='nvarchar'
	from LoadColumns c
	where col in (select col from Enum where try_cast(ikey as int) is null group by col)
	--
	update LoadColumns
		set dest_dtype = dest_dtype+
			case when dest_dtype like '%varchar%' then '('+case when maxlen=-1 then 'max' 
				 else cast(maxlen as varchar(8)) end+')' else '' end 
	--
	print 'Created LoadColumns'
	--
end
go



exec spBuildMeta
go
exec spBuildEnum
go
exec spBuildLoadColumns
go

