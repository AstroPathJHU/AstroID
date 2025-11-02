use Astropath
go


set nocount on
--
-----------------------------------
-- set up the linked server
-----------------------------------
--exec sp_addlinkedserver '10.181.18.96\JHBCRU_VSQL2'

--------------------------------
-- create the constants table
--------------------------------
drop table if exists Constants
--
create table Constants (
	cname varchar(256) NOT NULL,
	cval  varchar(max) NOT NULL
)
go

insert Constants
select 'sourcedb', '[10.181.18.96\JHBCRU_VSQL2].[RC_3130_Astropath]' 
go

--------------------------------------------------
-- Check if there is a CopyLog already set up.
-- If not, set it up, but do not delete.
--------------------------------------------------
drop table if exists CopyLog
--
create table CopyLog (
	sname varchar(256) NOT NULL,
	tname varchar(256) NOT NULL,
	msg varchar(4096) NOT NULL,
	nrows int NOT NULL,
	tstamp datetime NOT NULL
)
go

--======================================================
-- RedCap_cloning_script.sql
--
-- clone the RedCap db converted to SQL Server
-- to a local database on our side
-- Alex Szalay, 2022-12-06
--======================================================

-----------------------------------------------
-- get the timestamp of the latest version
-----------------------------------------------
declare @tstamp datetime
select top 1 @tstamp=timestamp from AstroPathXfer.dbo.log order by timestamp desc
--
insert CopyLog
select 'Redcap_PID3130',cval,'Data exported from Redcap',0,@tstamp
from Constants
where cname='sourcedb'
print 'Export timestamp is '+cast(@tstamp as varchar(64))
go

--================
-- spCloneRedCap
--================
drop procedure if exists spCloneRedCap
go
--
create procedure spCloneRedCap (@sourcedb varchar(256))
as begin
	--------------------------------------------------------
	-- clone the redcap export database
	-- assumes that there is a linked server to the source
	--------------------------------------------------------
	set nocount on
	------------------------------------------------------
	-- create a list of the table names to be copied
	------------------------------------------------------
	drop table if exists XferTables
	create table XferTables (
		n int identity(1,1) not null,
		sname varchar(250) not null,
		tname varchar(256) not null
	)
	declare @cmd varchar(max)
	select @cmd = 'insert XferTables'
		+' select name sname, ''redcap.''+name tname from '
		+@sourcedb+'.sys.tables'
	exec(@cmd)
	------------------------------------
	-- now clone the tables in a loop
	-- the source is hardwired
	------------------------------------
	declare @sname varchar(256), @tname varchar(256), @n int=0
	--
	while(1=1)
	begin
		select top 1 @n=n, @sname=@sourcedb+'.dbo.'+sname, @tname=tname,
			@cmd='drop table if exists '+tname
			+'; select * into '+tname+' from '+@sourcedb+'.dbo.'+sname
		from XferTables where n>@n
		if @@rowcount=0
			break;
		--
		begin try
			exec(@cmd)
			insert CopyLog select @sname, @tname, @cmd, cast(0 as int), getdate() tstamp
		end try
		begin catch
			print 'ERROR'
		end catch
		--
	end
	-------------------------------------------
	-- get a count of the rows copied over
	-------------------------------------------
	update c
	  set nrows=b.[rows]
	from   CopyLog c, sys.tables a, sys.partitions b
	where a.object_id = b.object_id 
	  and a.name=c.tname
end
go

-----------------------------------------------
-- create redcap schema if it does not exist
-----------------------------------------------
if not exists ( select * from sys.schemas where name = N'redcap' )
exec('CREATE SCHEMA [redcap] AUTHORIZATION [dbo]');
go


declare @sourcedb varchar(max)
select @sourcedb = cval 
from Constants
where cname='sourcedb'
--print @sourcedb
--
exec spCloneRedcap @sourcedb
go

-------------------------------------------
-- update the number of rows in CopyLog
-------------------------------------------
declare @x table (name varchar(64) not null, cnt int not null)
insert @x 
select 'redcap.'+tab.name, count(*) cnt
from sys.tables as tab, sys.columns as col
where tab.schema_id in (
	select schema_id 
	from sys.schemas 
	where name = 'redcap'
	)
	and tab.object_id = col.object_id
	and tab.name not like '%debug%'
group by tab.name
--
update c
  set nrows=x.cnt
from CopyLog c, @x x
where x.name = c.tname

declare @nrows int
select @nrows = sum(nrows) from CopyLog
--
update CopyLog
  set nrows = @nrows
  where nrows=0
  
--================
-- redcap.debug
--================
drop table if exists redcap.debug
--
create table redcap.debug (
	tier varchar(16) NOT NULL,
	task varchar(64) NOT NULL,
	sql varchar(max) NOT NULL,
	tstamp datetime NOT NULL
)
go

select * from CopyLog



/*

select * from redcap.record
select * from redcap.log
select * from redcap.patient_tier
select * from redcap.diagnosis_tier
select * from redcap.clinical_tier
select * from redcap.specimen_tier
select * from redcap.block_tier
select * from redcap.slide_tier

*/
