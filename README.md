# tzupdater
Automatically Download and Compile Tz Database from the IANA Website (https://www.iana.org/time-zones).

Download and compile any version of the IANA Time Zone Database (also known as Olson database) and make it current in your R session.
This will NOT replace your system tz database.

# Context
It can be useful to download and compile the latest tz database because tz information are constently changing,
hence your system might not catch the latest version. Outdated tz database can cause troubles when converting from UTC to local time and vice-versa. You won't have any obvious error, you will just get wrong UTC offset or zone name.

# Installation
On Windows, please install Cygwin first! https://www.cygwin.com
```
library(devtools)
install_github("sthonnard/tzupdater")
```
# Get last tz
Download and compile the last available tz database, and then make it active. Do nothing in case active tz database is already the latest version.
```
install_last_tz()
```
# Example of tz change
Get the tz database 2016a:\
```
install_tz("2016a")
```

Convert UTC datetime 2019-01-01 11:00:00 to local time in Istanbul\
```
as.POSIXct(format("2019-01-01 11:00:00", tz="UTC"),tz="Asia/Istanbul")
2019-01-01 11:00:00 EET
```
Now get IANA tz database 2019c and convert the same time\
```
install_tz("2019c")\
as.POSIXct(format("2019-01-01 11:00:00", tz="UTC"),tz="Asia/Istanbul")
2019-01-01 11:00:00 +03
```
\
This is because in 2016 Turkey was still observing EET in Winter. Now Turkey is UTC+3 (https://en.wikipedia.org/wiki/Time_in_Turkey) permanently.
