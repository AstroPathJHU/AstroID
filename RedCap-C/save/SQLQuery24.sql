use astropath
go

	set nocount on
	-------------------------------------
	-- list of all columns to be loaded
	-------------------------------------
	drop table if exists LoadColumns
	--
	create table LoadColumns (
		tier varchar(32) NOT NULL,
		column_id int NOT NULL,
		column_no int NOT NULL,
		colname varchar(64) NOT NULL,
		col varchar(64) NOT NULL,
		maxlen int NOT NULL,
		src_dtype varchar(32) NOT NULL,
		dest_dtype varchar(32) NOT NULL,
		ctype varchar(32) NOT NULL,
		item varchar(16) NOT NULL,
		ix smallint NOT NULL,
		enum varchar(1024) NOT NULL,
		iskey tinyint NOT NULL
	)
	--
	insert LoadColumns
	select tier, column_id, 0 column_no, colname, 
			substring(x.colname,1,case when x.pos=0 then len(x.colname) else pos-1 end) col,
			maxlen, dtype src_dtype, 'none' dest_dtype,  'text' ctype, 
			'' as item, cast(0 as smallint) ix, 'none' enum, 0 iskey
	from (
		select
			replace(replace(tab.name,'_tier',''),'redcap_','') tier,
			col.column_id,  col.name colname, col.max_length maxlen, t.name dtype,
			patindex('%[_][_][_]%',col.name) pos
		from sys.tables as tab, sys.columns as col,  sys.types as t
		where tab.name like '%_tier'
		  and tab.object_id = col.object_id
		  and col.user_type_id = t.user_type_id
		  and col.name not like '%COMBINED%'
		  and col.name not like 'redcap%'
	) x
	------------------------------------
	-- mark PK and FK as non-nullable
	------------------------------------
	update LoadColumns
	  set iskey=1
	where colname in (select pkey from PKeys)
	--
	update LoadColumns
	  set iskey=1
	where colname in (select fkey from Fkeys)
    and iskey=0


	------------------------------------------
	-- use redcap_metadata to extract info
	-- about enumerations etc
	------------------------------------------
	drop table if exists #meta
	--
	select --ID, 
		replace(form_name,'_tier','') tier, field_name colname, 
		field_type ctype, coalesce(text_validation_type_or_show_slider_number,'') validation, 
		'xxxxxxxxxx' dtype
	into #meta
	from redcap_metadata
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
	-- propagate these to LoadColumns
	----------------------------------
	update a
	  set a.dest_dtype=b.dtype, a.ctype=b.ctype
	from LoadColumns a, #meta b
	where a.tier=b.tier
	  and a.col = b.colname




	select * from #meta
	
	select * from LoadColumns where colname like 'comorbi%'
	select * from Astropath.dbo.LoadColumns where colname like 'comorbi%'


	select * from redcap_metadata
	where field_name like 'comorbi%'


