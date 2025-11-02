drop function if exists dbo.fGetIRBReport
go
--
create function dbo.fGetIRBReport()
--===============================================
-- create the standard IRB demographic report
-- Alex Szalay, 2025-10-14, Baltimore
--===============================================
returns @out table (
		[Racial Categories] varchar(32),
		[Male(NH)] int,
		[Female(NH)] int,
		[Unknown(NH)] int,
		[Male(H)] int,
		[Female(H)] int,
		[Unknown(H)] int,
		[Male(U)] int,
		[Female(U)] int,
		[Unknown(U)] int,
		[Total] int
		)
as begin	
	--------------------------------
	-- create CTE for the query
	-- for each value of _ethnicity
	--------------------------------
	with a1 as (
		select race, Male, Female, Unknown
		from 
		(
			select race, sex, count(*) cnt
			from Patient
			where _ethnicity in (1)
			group by race, sex
		) x
		pivot ( sum(cnt) for sex in ([Male], [Female], [Unknown]) ) p
	),
	a2 as (
		select race, Male, Female, Unknown
		from 
		(
			select race, sex, count(*) cnt
			from Patient
			where _ethnicity in (2)
			group by race, sex
		) x
		pivot ( sum(cnt) for sex in (Male, Female, Unknown) ) p
	),
	a3 as (
		select race, Male, Female, Unknown
		from 
		(
			select race, sex, count(*) cnt
			from Patient
			where _ethnicity in (3)
			group by race, sex
		) x
		pivot ( sum(cnt) for sex in (Male, Female, Unknown) ) p
	)
	------------------------------------------
	-- collect these into the output table
	------------------------------------------
	insert @out
	select coalesce(a1.race, a2.race,a3.race) race, 
		isnull(a1.Male,0), isnull(a1.Female,0), isnull(a1.Unknown,0),
		isnull(a2.Male,0), isnull(a2.Female,0), isnull(a2.Unknown,0),
		isnull(a3.Male,0), isnull(a3.Female,0), isnull(a3.Unknown,0),
		0
	from a1 full outer join a2
	on a1.race=a2.race full outer join a3
	on a2.race=a3.race
	----------------------------
	-- add the columnwise total
	----------------------------
	insert @out
	select 'Total', 
			sum([Male(NH)]), sum([Female(NH)]), sum([Unknown(NH)]),
			sum([Male(H)]), sum([Female(H)]), sum([Unknown(H)]),
			sum([Male(U)]), sum([Female(U)]), sum([Unknown(U)]),0
	from @out
	-----------------------------------
	-- add the rowwise total
	-----------------------------------
	update a
	  set a.total=b.total
	from @out a, (
		select [Racial Categories],[Male(NH)]+[Female(NH)]+[Unknown(NH)]
		  +[Male(H)] +[Female(H)]+[Unknown(H)]
		  +[Male(U)]+[Female(U)]+[Unknown(U)] total
		from @out
		) b
	where a.[Racial Categories]=b.[Racial Categories]
	--
	return
	--
end
go


select * from fGetIRBReport()
