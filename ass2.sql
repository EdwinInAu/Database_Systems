-- COMP9311 Assignment 2
-- Written by Chongshi Wang, August 1 2019

-- Q1: get details of the current Heads of Schools

create or replace view Id as
select id from StaffRoles
where description = 'Head of School'
;

create or replace view Type as
select id from OrgUnitTypes
where name = 'School'
;

create or replace view Man as
select  Affiliation.staff, Affiliation.role, Affiliation.starting,Affiliation.orgunit from Affiliation, Id
where  
Affiliation.role = Id.id AND
Affiliation.isprimary AND
Affiliation.ending is NULL
;

create or replace view Q1(name, school, starting)
as
select distinct People.name, OrgUnits.longname, Man.starting FROM
People,OrgUnits, Man, Type where People.id = Man.staff AND
OrgUnits.utype = Type.id AND
Man.orgunit = OrgUnits.id
order by Man.starting
;

-- Q2: longest-serving and most-recent current Heads of Schools

create or replace view Count(name,school,starting) as 
select Q1.name,Q1.school,Q1.starting from Q1 where Q1.starting = (select min(Q1.starting) from Q1) Or
Q1.starting = (select max(Q1.starting) from Q1)
;

create or replace view Q2(status, name, school, starting)
as
SELECT
CASE WHEN Count.starting = (select min(Count.starting) from Count) THEN 'Longest serving'
when Count.starting = (select max(Count.starting) from Count) THEN 'Most recent'
END AS status,
Count.name, Count.school, Count.starting
FROM Count;

-- Q3: term names

create or replace view T
as 
select Terms.id,Terms.year,Terms.sess
from Terms; 

create or replace view L
as
select T.id, cast(T.year as varchar), T.sess  from T
;

create or replace view M(id,y)
as 
select DISTINCT L.id, substring(L.year,3,4) || L.sess 
from L;

create or replace function Q3(integer) returns text
as $$
select  LOWER(M.y) from M where M.id = $1
$$ language sql
;

-- Q4: percentage of international students, S1 and S2, 2005..2011

create or replace view Int
as 
select Students.id,Students.stype FROM
Students where Students.stype = 'intl'
;

create or replace view I1
AS
select * from M where M.y like '%S%' AND
M.id >= (select M.id from M where M.y = '05S1') AND
M.id <= (select M.id from M where M.y = '11S1')
;

create or replace view A1
as 
select count(ProgramEnrolments.student),ProgramEnrolments.term
from ProgramEnrolments,I1 where ProgramEnrolments.term = I1.id
group by term
;

create or replace view B1
as
select count(ProgramEnrolments.student),ProgramEnrolments.term 
from ProgramEnrolments,I1 where ProgramEnrolments.term = I1.id AND
ProgramEnrolments.student in (select Int.id from Int)
group by term
;

create or replace view K(term,count1,count2)
as 
select 
I1.y,B1.count,A1.count
from I1,A1,B1
where I1.id = A1.term AND
I1.id = B1.term AND
A1.term = B1.term;

create or replace view Q4(term, percent)
as
select LOWER(K.term),
CAST( CAST(K.count1 as float)/K.count2 as decimal (4,2))  from K
order by term;
;

-- Q5: total FTE students per term since 2005

create or replace view Tid(term,id)
AS
select M.y,M.id from M WHERE
M.y like '%S%' AND
M.id >= (select M.id from M where M.y = '00S1') AND
M.id <= (select M.id from M where M.y = '10S2')
order by M.y;

create or replace view Tcount
as 
select Courses.id,Courses.term,Courses.subject, Subjects.uoc from Courses,Subjects,Tid
where Courses.term = Tid.id AND
Subjects.id = Courses.subject 
order by Courses.term;

create or replace view Numstu
as 
select distinct CourseEnrolments.student, Tcount.term from CourseEnrolments,Tcount WHERE
CourseEnrolments.course =  Tcount.id
order by Tcount.term;

create or replace view Count1(termid,nstudents)
as 
select Numstu.term, 
count(*) from Numstu group by Numstu.term
order by Numstu.term;

create or replace view Goal1(term,nstudes,id)
as 
select LOWER(Tid.term), Count1.nstudents,Tid.id from Tid,Count1
where Tid.id = Count1.termid
order by Tid.term;

create or replace view Count2
as 
select  CourseEnrolments.student,Tcount.id,Tcount.subject,Tcount.uoc,Tcount.term from CourseEnrolments,Tcount WHERE
CourseEnrolments.course = Tcount.id
order by Tcount.term;

create or replace view Goal2(fte,term)
as 
select CAST(CAST(sum(Count2.uoc) as float)/24 as decimal (6,1)),
Count2.term from Count2 group by Count2.term;

create or replace view Q5(term, nstudes, fte)
as
select Goal1.term,Goal1.nstudes,Goal2.fte from Goal1,Goal2
where Goal2.term = Goal1.id;

-- Q6: subjects with > 30 course offerings and no staff recorded

create or replace view Nul(id)
as 
select CourseStaff.course from CourseStaff;

create or replace view Offe 
as 
select count(*),Courses.subject FROM
Courses group by Courses.subject;

create or replace view Sel 
as 
select Offe.count, Offe.subject from Offe 
where Offe.count > 30;

create or replace view Sub 
as 
select Sel.subject, Courses.id from Sel, Courses
where Courses.subject = Sel.subject order by Sel.subject;

create or replace view Rem 
as 
select Sub.id, Sub.subject from Sub where 
Sub.id not in (select Nul.id from Nul);

create or replace view Cal 
as 
select count(*), Rem.subject from Rem 
group by Rem.subject;

create or replace view En(subject,nofferings)
as 
select Cal.subject,Cal.count from Cal,Sel where 
Sel.count = Cal.count AND
Sel.subject = Cal.subject;

create or replace view Q6(subject, nOfferings)
as
select (Subjects.code||' '||Subjects.name), En.nofferings from En,Subjects 
where En.subject = Subjects.id
order by  (Subjects.code||' '||Subjects.name);
;

-- Q7:  which rooms have a given facility

create or replace view Roo(roomid,room,facid,facility)
as 
select RoomFacilities.room,Rooms.longname,RoomFacilities.facility,Facilities.description from 
RoomFacilities,Facilities,Rooms
where RoomFacilities.facility = Facilities.id AND 
RoomFacilities.room = Rooms.id 
order by Facilities.description;

create or replace view E1(room,facility) 
as 
select Roo.room, Roo.facility from Roo;

create or replace function
	Q7(text) returns setof FacilityRecord
as $$
select E1.room,E1.facility from E1 where LOWER(E1.facility) like '%'||LOWER($1)||'%'
$$ language sql
;

-- Q8: semester containing a particular day

create or replace view Yeat(year,sess,starting,ending)
as 
select cast(Terms.year as varchar),Terms.sess,Terms.starting,Terms.ending from Terms
order by year;

create or replace view Yea(year,starting,ending)
as 
select substring(Yeat.year, 3,4)||Yeat.sess,Yeat.starting,Yeat.ending from Yeat
order by Yeat.ending;

CREATE or replace view Y1(id,year,starting,ending)
as
select M.id,Yea.year,Yea.starting,Yea.ending 
from Yea,M where Yea.year = M.y 
order by Yea.starting;

create or replace view Y2(id,year,starting,ending,count)
as 
select Y1.id,Y1.year,Y1.starting,Y1.ending,
Y1.starting - lag(Y1.ending) over (order by Y1.starting)
from Y1;

create or replace view Y3(id,year,starting,ending,count,nstarting)
as 
select Y2.id,Y2.year,Y2.starting,Y2.ending,Y2.count,
case when Y2.count >7 then Y2.starting -7
when Y2.count is null then Y2.starting
else (lag(Y2.ending) over(order by Y2.starting) )+ 1 
end as nstarting 
from Y2;

create or replace view Y4(id,year,starting,ending,count,nstarting,nending)
as 
select Y3.id,Y3.year,Y3.starting,Y3.ending,Y3.count,Y3.nstarting,
case when (lead(Y3.count)over (order by Y3.starting)) >7 then (lead(Y3.nstarting) over (order by Y3.starting)) -1
when Y3.count is null then Y3.ending
else Y3.ending
end as nending
from Y3;

create or replace function Q8(_day date) returns text 
as $$
declare
	line RECORD;
begin
	for line in SELECT Y4.id,Y4.year,Y4.nstarting,Y4.nending 
	from Y4
	LOOP
		if(_day >= line.nstarting and _day <= line.nending)
		then 
			return LOWER(line.year);
		end if;
	end loop;
	return NULL;
end;
$$ language plpgsql
;

-- Q9: transcript with variations

create or replace view P1(unswid,stid,suid,scode,sname,suoc,vtype,intequiv,extequiv,yearpassed,mark,extsubj,institution)
as 
select People.unswid,People.id,Subjects.id,Subjects.code,Subjects.name,Subjects.uoc,
Variations.vtype,Variations.intequiv,Variations.extequiv,Variations.yearpassed,
Variations.mark,ExternalSubjects.extsubj,ExternalSubjects.institution
from Variations join People on Variations.student = People.id join Subjects on Variations.subject = Subjects.id 
Left join ExternalSubjects on ExternalSubjects.id = Variations.extequiv;  

create or replace view P2
as 
select Variations.intequiv,Subjects.code,Subjects.name from Variations,Subjects where 
Variations.intequiv = Subjects.id;

create or replace view P3(unswid,stid,suid,scode,sname,suoc,vtype,intequiv,nscode,extequiv,yearpassed,mark,extsubj,institution)
as 
select 
distinct P1.unswid,P1.stid,P1.suid,P1.scode,P1.sname,P1.suoc,P1.vtype,P1.intequiv,P2.code,P1.extequiv,P1.yearpassed,P1.mark,P1.extsubj,P1.institution
from P1 left join P2 on P1.intequiv = P2.intequiv
order by P1.unswid;

CREATE OR REPLACE FUNCTION q9(_sid integer)
RETURNS SETOF TranscriptRecord
LANGUAGE plpgsql
AS $function$
declare
	rec TranscriptRecord;
	line   RECORD;
	UOCtotal integer := 0;
	UOCpassed integer := 0;
	wsum integer := 0;
	wam integer := 0;
	x integer;
begin
	select s.id into x
	from Students S join People p on (s.id = p.id)
	where p.unswid = _sid;
	if (not found) THEN
			raise EXCEPTION 'Invalid student %',_sid;
	end if;
	for rec in
			select su.code, substr(t.year::text, 3,2)||lower(t.sess),
					su.name, e.mark, e.grade, su.UOC
			from CourseEnrolments e join Students s on (e.student = s.id)
					join People p on (s.id = p.id)
					join Courses c on (e.course = c.id)
					join Subjects su on (c.subject = su.id)
					join Terms t on (c.term = t.id)
			where p.unswid = _sid
			order by t.starting, su.code
	Loop
			if (rec.grade = 'SY') THEN
					UOCpassed := UOCpassed + rec.uoc;
			elsif (rec.mark is not null) THEN
					if (rec.grade in ('PT','PC','PS','CR','DN','HD'))THEN
							-- only counts towards creditted UOC
							-- if they passed the course
							UOCpassed := UOCpassed + rec.uoc;
					end if;
					-- we count fails towards the WAM calculation
					UOCtotal := UOCtotal + rec.uoc;
					-- weighted sum based on mark and uoc for course
					wsum := wsum + (rec.mark * rec.uoc);
			end if;
			return next rec;
	end loop;
    for line in select * from P3 where  unswid = _sid
	loop 
			if (line.vtype = 'exemption') THEN 
				rec := (line.scode,null,'Exemption, based on ...',null,null,null);
			elsif (line.vtype = 'advstanding') then 
				UOCpassed := UOCpassed + line.suoc;
				rec := (line.scode,null,'Advanced standing, based on ...',null,null,line.suoc);
			elsif (line.vtype = 'substitution') then 
				rec := (line.scode,null,'Substitution, based on ...',null,null,null);
			end if;
			return next rec;

			if (line.institution is not null) then 
				rec := (null,null,'study at '||line.institution,null,null,null);
			elsif (line.scode is not null) then 
				rec := (null,null,'studying '||line.nscode||' at UNSW',null,null,null);
			end if;
			return next rec;
	end loop;
	if (UOCtotal = 0) THEN
			rec := (null, null, 'No WAM available', null,null,null);
	else
			wam := wsum / UOCtotal;
			rec := (null,null,'Overall WAM', wam, null, UOCpassed);
	end if;
	-- append the last record containing the WAM
	return next rec;
	return;
end;
$function$;
