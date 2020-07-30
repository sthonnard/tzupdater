# tzupdater
Download and compile any version of the IANA Time Zone Database (also known as Olson database, https://www.iana.org/time-zones) and make it current in your R session.
This will NOT replace your system tz database.\
This code comes with absolutely no warranty and is not an official IANA component.

# Context
It can be useful to download and compile the latest tz database because tz information are constently changing,
hence your system might not catch the latest version. Outdated tz database can cause troubles when converting from UTC to local time and vice-versa. You won't have any obvious error, you will just get wrong UTC offset or zone name.\
This can also be useful for reproducibility. This helps you to rerun your code using an older tz database.

# Prerequisite
**timezone compiler** (zic) is required. 

* On Windows you can get zic by installing **Cygwin**. It is available at https://www.cygwin.com.
* On Linux zic is generally available by default. Otherwise it is part of package **tzdata**.\
Using Alpine Linux following command will make zic available:
```
apk add tzdata
```
* On macOS zic is already installed.

# Installation
You can install the latest version of tzupdater from github:
```
library(devtools)
install_github("sthonnard/tzupdater")
```
# Get the latest tz database
Download and compile the latest available tz database, and then make it active. Do nothing in case active tz database is already the latest version.
```
install_last_tz()
```
# Example of tz change
Get the tz database 2016a:
```
install_tz("2016a")
```

Convert UTC datetime 2019-01-01 11:00:00 to local time in Istanbul
```
as.POSIXct(format("2019-01-01 11:00:00", tz="UTC"),tz="Asia/Istanbul")
2019-01-01 11:00:00 EET
```
Now get IANA tz database 2019c and convert the same time
```
install_tz("2019c")
as.POSIXct(format("2019-01-01 11:00:00", tz="UTC"),tz="Asia/Istanbul")
2019-01-01 11:00:00 +03
```
\
This is because in 2016 Turkey was still observing EET in Winter. Now Turkey is UTC+3 (https://en.wikipedia.org/wiki/Time_in_Turkey) permanently.
