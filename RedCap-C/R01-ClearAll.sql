--USE Astropath
--go

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

exec spDropForeignKeys
go

--==============================================================
-- ClearAll.sql
-- Clear all the user created objects in the database
-- 2022-05-23 Alex Szalay
--==============================================================

drop procedure if exists spClearAll
go
--
create procedure spClearAll
as begin
	--
	set nocount on
	--
	print 'ClearAll started';
	----------------------------------
	-- create a table for the driver
	----------------------------------
	drop table if exists #dropall

	create table #dropall (
		n int identity(1,1) NOT NULL,
		code varchar(3) NOT NULL,
		target varchar(16) NOT NULL
	)
	--
	insert #dropall values('U','TABLE')
	insert #dropall values('V','VIEW')
	insert #dropall values('FS','FUNCTION')
	insert #dropall values('FN','FUNCTION')
	insert #dropall values('TF','FUNCTION')
	insert #dropall values('P','PROCEDURE')
	-----------------------------------------------
	-- loop through the database objects by class
	-----------------------------------------------
	declare @n int=0, @code varchar(3), @target varchar(16), 
		@sql varchar(64), @m int, @obj varchar(64)
	declare @names table (m int identity(1,1), name varchar(128))
	while(1=1)
	begin
		--
		select @n=min(n)
		from #dropall where n>@n
		if @n is null
			break;
		--
		select @code=code, @target = target
		from #dropall where n=@n
		delete @names
		--
		insert @names
		select s.name+'.'+t.name
		from sysobjects t, sys.schemas s
		where t.uid=s.schema_id	
		and xtype=@code
		--
		set @m=0
		while(1=1)
		begin
			select @m = min(m) from @names where m>@m
			if @m is null
				break;
			select @obj = name from @names where m=@m
			select @sql = 'DROP '+@target+' '+ @obj
			exec(@sql)

		end
		--
	end
	-----------------------------
	print 'ClearAll completed';
	-----------------------------
end
go


exec spClearAll
go
