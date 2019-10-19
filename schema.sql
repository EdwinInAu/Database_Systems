-- Schema for simple company database

create table Employees (
	tfn   char(11) CHECK(tfn ~ ‘[0-9]{3}-[0-9]{3}-[0-9]{3}’),
	givenName   varchar(30) NOT NULL,
	familyName  varchar(30),
	hoursPweek  float CHECK(hoursPweek>=0 AND hoursPweek<=168),
	primary key(tfn)
);

create table Departments (
	id          char(3),
	name        varchar(100),
	manager     char(11) CHECK(manager ~ ‘[0-9]{3}-[0-9]{3}-[0-9]{3}’),
	primary key(id)
);

create table DeptMissions (
	department  char(3),
	keyword     varchar(20),
	primary key(department,keyword)
);

create table WorksFor (
	employee    char(11) CHECK(employee ~ ‘[0-9]{3}-[0-9]{3}-[0-9]{3}’),
	department  char(3),
	percentage  float CHECK(percentage>=0 AND percentage<=100),
	primary key(employee,department)
);

alter table Departments add foreign key(manager) references Employees(tfn);
alter table DeptMissions add foreign key(department) references Departments(id);
alter table WorksFor add foreign key(employee) references Employees(tfn);
alter table WorksFor add foreign key(department) references Departments(id);
