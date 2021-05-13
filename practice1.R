require(pacman)
p_load(tidyverse,RODBC)

# must specify full file path, apparently
dta <- odbcConnectAccess2007("C:/Users/Joe/Dropbox (University of Oregon)/My PC (DESKTOP-8RMGF3S)/Documents/howdb/Cookie.accdb") 

# get the names of tables in the database
sqlTables(dta)

df1 <- sqlFetch(dta, "Customers")
df2 <- sqlFetch(dta,"Orders")
df3 <- sqlFetch(dta,"Unfilled orders")

sqlQuery(dta,"SELECT Customers.[First Name], Customers.[Last Name], Customers.Address, Customers.City, Customers.State, Customers.Zip, Customers.Country, Orders.[Order Date], Orders.[Cookies Ordered], Orders.[Order Filled]
FROM Customers INNER JOIN Orders ON Customers.[Customer ID] = Orders.[Customer ID]
WHERE ((Orders.[Order Filled])=No);")
