-- Assignment 1 Stage 2
-- Schema for the et.org events/ticketing site
--
-- Written by <<Wang Chongshi>>
--
-- Conventions:
-- all entity table names are plural
-- most entities have an artifical primary key called "id"
-- foreign keys are named after the relationship they represent
-- Generally useful domains

create domain URLValue as
	varchar(100) check (value like 'http://%');

create domain EmailValue as
	varchar(100) check (value like '%@%.%');

create domain GenderValue as
	char(1) check (value in ('m','f','n'));

create domain ColourValue as
	char(7) check (value ~ '#[0-9A-Fa-f]{6}');

create domain LocationValue as varchar(40)
	check (value ~ E'^-?\\d+\.\\d+,-?\\d+\.\\d+$');

create domain NameValue as varchar(50);

create domain LongNameValue as varchar(100);

create table People (
	id          serial,
	email 		EmailValue NOT NULL	,
	givenNames 	NameValue NOT NULL,
	familyName	NameValue,
	primary key (id)
);

create table Places (
	id        serial, 
	name 	  LongNameValue NOT NULL,
	countryName NameValue NOT NULL,
	postalCode text,
	address text,
	city text,
	state text,
	gpsCoords LocationValue,
	primary key (id)
);

create table Users (
	password text NOT NULL,
	billingAddressId int NOT NULL,
	homeAddressId int,
	id int,
	gender GenderValue,
	birthday DATE,
	phone text,
	blog  URLValue,
	website URLValue,
	showName LongNameValue,
	primary key(id)
);

create table Events (
	id          serial,
	startDate DATE NOT NULL,
	startTime TIME NOT NULL,
	eventInfoId int NOT NULL,
	repeatingEventId int,
	primary key (id)
);

create table PageColours (
	id          serial,
	isTemlate boolean DEFAULT FALSE ,
	links ColourValue,
	name ColourValue NOT NULL,
	userId int,
	heading ColourValue,
	maintext ColourValue,
	headtext ColourValue,
	borders ColourValue,
	boxes ColourValue,
	background ColourValue,
	primary key (id)
);

create table Organisers (
	id serial,
	name LongNameValue NOT NULL,
	logo bytea,
	about text,
	ownsId int NOT NULL,
	themeId int NOT NULL,
	primary key(id)
);

create table ContactLists (
	id serial,
	name LongNameValue NOT NULL,
	ownUserId int NOT NULL,
	primary key (id)
);

create table MemberOf (
nickName LongNameValue,
contactListId int,
peopleId int,
primary key (contactListId,peopleId)
);

create table InvitedTo (
	peopleId int,
	eventId int,
	primary key(peopleId,eventId)
);

create table Attended (
	peopleId int,
	eventId int,
	primary key(peopleId,eventId)
);

create table EventInfos (
	id          serial,
	title LongNameValue NOT NULL,
	details text NOT NULL,
	startingTime  TIME NOT NULL,
	placeId int NOT NULL,
	duration interval,
	isPrivate boolean DEFAULT TRUE NOT NULL,
	showLeft boolean DEFAULT FALSE NOT NULL,
	showFee boolean DEFAULT FALSE NOT NULL,
	pageColoursId int NOT NULL,
	organisersId int NOT NULL,
	primary key (id)
);

create table Categories(
	eventInfoId int,
	categoriesName text,
	primary key(eventinfoId,categoriesname)
	);

create domain EventRepetitionType as varchar(10)
	check (value in ('daily','weekly','monthly-by-day','monthly-by-date'));

create domain DayOfWeekType as char(3)
	check (value in ('mon','tue','wed','thu','fri','sat','sun'));

create table RepeatingEvents (
	id          serial,
	lowerDate DATE NOT NULL,
	upperDate DATE NOT NULL,
	eventInfoID int NOT NULL,
	primary key (id)
);

create table DailyEvents (
frequency int CHECK(1 <= frequency AND 31 >= frequency),
repeatingEventId int,
primary key (repeatingEventId)
);

create table WeeklyEvents (
frequency int CHECK(1 <= frequency AND 4 >= frequency),
repeatingEventId int,
dayofWeek DayOfWeekType,
primary key (repeatingEventId)
);

create table MonthByDayEvents (
repeatingEventId int,
dayofWeek DayOfWeekType,
weekinMonth int CHECK(1 <= weekinMonth AND 5 >= weekinMonth),
primary key (repeatingEventId)
);

create table MonthByDateEvents (
repeatingEventId int,
dateinMonth int CHECK(1 <= dateinMonth AND 31 >= dateinMonth),
primary key (repeatingEventId)
);

create table TicketTypes (
	id          serial,
	type text NOT NULL,
	description LongNameValue,
	price double precision CHECK(0 <= price) NOT NULL,
	currency char(3) NOT NULL,
	maxPerSale int CHECK(0 <= maxperSale) NOT NULL,
	totalNumber int CHECK(0 <= totalNumber) NOT NULL,
	eventInfoId int NOT NULL,
	primary key (id)
);

create table SoldTickets(
id serial,
quantity int NOT NULL,
soldPeopleId int NOT NULL,
ticketTypeId int NOT NULL,
forEventId int NOT NULL,
primary key (id)
);

alter table Users add foreign key(id) references People(id);
alter table Users add foreign key(billingAddressId) references Places(id);
alter table Users add foreign key(homeAddressId) references Places(id);

alter table Events add foreign key(repeatingEventId) references RepeatingEvents(id);
alter table Events add foreign key(eventInfoId) references EventInfos(id);

alter table PageColours add foreign key (userId) references Users(id);

alter table Organisers add foreign key(ownsId) references Users(id);
alter table Organisers add foreign key(themeId) references PageColours(id);

alter table ContactLists add foreign key(ownUserId) references Users(id);

alter table MemberOf add foreign key(contactListId) references ContactLists(id);
alter table MemberOf add foreign key(peopleId) references People(id);

alter table InvitedTo add foreign key(peopleId) references People(id);
alter table InvitedTo add foreign key(eventId) references Events(id);

alter table Attended add foreign key(peopleId) references People(id);
alter table Attended add foreign key(eventId) references Events(id);

alter table EventInfos add foreign key(placeId) references Places(id);
alter table EventInfos add foreign key(pageColoursId) references PageColours(id);
alter table EventInfos add foreign key(organisersId) references Organisers(id);

alter table Categories add foreign key(eventInfoId) references EventInfos(id);

alter table RepeatingEvents add foreign key(eventInfoId) references EventInfos(id);

alter table DailyEvents add foreign key(repeatingEventId) references RepeatingEvents(id);

alter table WeeklyEvents add foreign key(repeatingEventId) references RepeatingEvents(id);

alter table MonthByDayEvents add foreign key(repeatingEventId) references RepeatingEvents(id);

alter table MonthByDateEvents add foreign key(repeatingEventId) references RepeatingEvents(id);

alter table TicketTypes add foreign key(eventInfoId) references EventInfos(id);

alter table SoldTickets add foreign key(soldPeopleId) references People(id);
alter table SoldTickets add foreign key(ticketTypeId) references TicketTypes(id);
alter table SoldTickets add foreign key(forEventId) references Events(id);