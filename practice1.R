require(pacman)
p_load(tidyverse,RODBC,tidycensus)

# create an empty database in MS access
# build connection to that database
# (must specify full file path, apparently)
dta <- odbcConnectAccess2007("C:/Users/Joe/Dropbox (University of Oregon)/My PC (DESKTOP-8RMGF3S)/Documents/howdb/wapo_shootings.accdb") 

# get the names of tables in the database
sqlTables(dta)

# pull external data into R
wapo <- read.csv("https://github.com/washingtonpost/data-police-shootings/releases/download/v0.1/fatal-police-shootings-data.csv")

# do cool R things to that data if necessary

# push that data into the database
sqlSave(dta,wapo,tablename="fatal",rownames = F)
# prints character(0) on success


# set a primary key with a query
sqlQuery(dta,"ALTER TABLE fatal
ADD PRIMARY KEY (id);")


# get more external data and set it up in database
vars <- load_variables(2010,"sf1")

pops <- get_decennial(geography = "state",
                      year=2010,
                      variables="P001001")

# some cleaning in R because I hate cleaning in SQL
pops$state <- state.abb[match(pops$NAME,state.name)]
pops$state <- ifelse(pops$NAME=="District of Columbia","DC",pops$state)

pops <- pops %>% dplyr::filter(!is.na(state)) %>% dplyr::select(-variable,-GEOID,-NAME)

names(pops)[which(names(pops)=="value")] <- "population"

# push cleaned up data into database
sqlSave(dta,pops,tablename="pops",rownames=F)

# add primary key
sqlQuery(dta,"ALTER TABLE pops
ADD PRIMARY KEY (state);")


# add foreign key to our main table
sqlQuery(dta,"ALTER TABLE fatal
ADD FOREIGN KEY (state) REFERENCES pops(state);")

# make a new table from existing tables:
# SELECT [var names] INTO [new table name] FROM [query or existing table]
sqlQuery(dta,"SELECT * INTO fatalwithpops FROM fatal LEFT JOIN pops ON fatal.state = pops.state;")


# stacked subqueries to get a table with states and police-deaths per 100,000 (since 2015)
# order that table by death rate

# working from the inside out:

# SELECT COUNT(id), [pops_state] FROM fatalwithpops GROUP BY [pops_state] 
# groups fatalwithpops by state and gets the total deaths in each state

# AS dcount
# gives an alias (dcount) to the state totals table

#  SELECT population, state, Expr1000 FROM pops LEFT JOIN (
# left joins the pops table (state abbs and populations) with dcount, by state abb

#  SELECT state, 100000 * Expr1000/population as deathrate FROM (
# calculates rates per 100,000 and names this variable deathrate

# SELECT * FROM (
# outermost query is only necessary so that we can alias the table with the rates (I just called it a)
# and then sort that aliased table by death rate

sqlQuery(dta,"SELECT * FROM (
           SELECT state, 100000 * Expr1000/population as deathrate FROM (

         SELECT population, state, Expr1000 FROM pops LEFT JOIN (
         
             (
         
             SELECT COUNT(id), [pops_state] FROM fatalwithpops GROUP BY [pops_state]
         
             ) 
             
             AS dcount
         
           )
           
           ON pops.[state] = dcount.[pops_state]
         
         ) 
         
        ) as a
        
        ORDER BY a.deathrate

         ;")

sqlQuery(dta,"SELECT Expr1000, population, state FROM NEWTABLE LEFT JOIN pops ON NEWTABLE.pops_state = pops.state")


sqlQuery(dta,"SELECT a.id, a.state FROM fatal AS a")

############ other commands that work #############

sqlQuery(dta,"SELECT COUNT(id), pops_state INTO NEWTABLE FROM fatalwithpops GROUP BY pops_state")
sqlQuery(dta,"SELECT COUNT(id), pops_state FROM fatalwithpops GROUP BY pops_state")

sqlQuery(dta,"SELECT * FROM fatalwithpops ORDER BY population")

# create a useless new table (var names and types, no data)
sqlQuery(dta,"CREATE TABLE Persons (
    PersonID int,
    LastName varchar(255),
    FirstName varchar(255),
    Address varchar(255),
    City varchar(255)
);")


odbcCloseAll()
