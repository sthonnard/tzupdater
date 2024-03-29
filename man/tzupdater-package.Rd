% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/tzupdater-package.R
\docType{package}
\name{tzupdater-package}
\alias{tzupdater}
\alias{tzupdater-package}
\title{A Tool For Automatically Download And Compile Tz Database From The IANA Website.}
\description{
Download and compile any version of the IANA Time Zone Database (also known as Olson database) and make it current
in your R session.
This will NOT replace your system tz database.
}
\details{
Context:\cr
It can be useful to download and compile the latest tz database because tz information are constently changing,
hence your system might not have the latest version. Outdated tz database can cause troubles when converting from UTC to local time
and vice-versa. You won't have any obvious error, you will just get wrong UTC offset or zone name.

Prerequisite:\cr
You need the timezone compiler (zic). \cr
 -On Windows you can get it by installing Cygwin (\url{https://www.cygwin.com})\cr
  zic should be installed in C:\\Cygwin\\usr\\sbin by default. If you installed Cygwin somewhere else, \cr
  please add the zic path to your environment pariable PATH or specify the path in the function call.\cr
 -On macOS zic is installed by default.\cr
 -On Linux zic is generally already available. Otherwise it is part of package tzdata.\cr
 Using Alpine Linux you can get it by running the following command:\cr
 apk add tzdata
 
 Bugs report:\cr
 \url{https://github.com/sthonnard/tzupdater}
}
\section{tzupdater functions}{

\strong{install_last_tz()}\cr
Automatically get the latest version available and compile it. Once done make it active. 
If your tz database is already the latest, do nothing.

\strong{get_last_published_tz()}\cr
Get the name of the latest version available at IANA website.\cr

\strong{get_active_tz_db()}\cr
Get the active tz database version on your session.\cr

\strong{install_tz(version_to_install)}\cr
Download and install the IANA time zone specified in parameter.
}

\keyword{internal}
