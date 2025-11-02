/*
-----------------------------
-- import the field history 
-----------------------------
drop table if exists redcap.logged_field_history 
--
create table redcap.logged_field_history (
	id int NOT NULL,
	record_id varchar(32) NOT NULL,
	instance int NULL,
	field_name varchar(128) NOT NULL,
	field_value varchar(max) NOT NULL,
	event_dt datetime NOT NULL,
	username varchar(128) NOT NULL
)
--
insert redcap.logged_field_history 
select id, 'P'+cast(record_id as varchar(32)) record_id, instance, 
	field_name,substring(field_value, 2, len(field_value) - 2), 
	event_dt, username
from [10.181.18.96\JHBCRU_VSQL2].RC_3130_Astropath.dbo.PID3130_logged_field_history

-----------------
-- fix astropt
-----------------
update redcap.logged_field_history
  set field_value = 'P'+field_value
where field_name='astropt'

*/

select distinct record_id, instance
from  redcap.logged_field_history 
order by 1,2

select *
from  redcap.logged_field_history 
where record_id='P200003'
order by event_dt

update redcap.logged_field_history 
  set instance = 1
  where instance is null


select record_id, instance, field_name, field_value, max(event_dt) 
from  redcap.logged_field_history 
group by record_id, instance, field_name, field_value
order by 1,2,3


select * from Patient
where astropt='P200003'


-----------------------------------------
-- delete events are not captured
-- see P200003
-----------------------------------------

/*
--===================
-- LogFieldHistory
--===================
drop table if exists LogFieldHistory
--
create table LogFieldHistory (
	hid int NOT NULL,
	record_id int NOT NULL,
	instance int NULL,
	field_name varchar(256) NOT NULL,
	field_value varchar(max) NOT NULL,
	event_dt datetime NOT NULL,
	username varchar(128) NOT NULL,
	primary key(hid)
)


--=============
-- LogEvents
--=============
drop table if exists LogEvents
--
create table LogEvents (
	eventid int NOT NULL,
	event_dt datetime NOT NULL,
	username varchar(128) NOT NULL,
	action varchar(256) NOT NULL,
	details varchar(max) NULL,
	record_id int NOT NULL,
	instance int NULL,
	primary key (eventid)
)

insert LogEvents
select * from PID3130_logged_data_events
order by id

insert LogFieldHistory
select * from PID3130_logged_field_history
order by id
go


*/
