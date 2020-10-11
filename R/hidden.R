# Variable for storing the name of the latest tz database found on the IANA website:
.tzupdater.globals <- new.env()
.tzupdater.globals$last_tz_db <- NA

.tzupdater.globals$IANA_website <- "https://www.iana.org/time-zones"
.tzupdater.globals$download_base_URL <- "https://data.iana.org/time-zones/releases"

# Get the active tz database insession - not allowing NULL:
.get_active_tz_db <- function()
{
  if (is.null(attr(OlsonNames(),"Version")))
  {
    return("-----")
  }
  else
  {
    return(attr(OlsonNames(),"Version")) 
  }
}


# Activate a time zone database.
.activate_tz <- function(tz_path, verbose=TRUE)
{
  Sys.setenv(TZDIR = tz_path)
  if (verbose)
  {
    print(paste("Active tz db:",.get_active_tz_db()))
  }
}


# Message when IANA cannot be reached
.iana_not_reachable <- function()
{
  print("========================================================================================================================")
  print("IANA website might be unreachable or has changed in a way that broke the package logic. Please try again later.")
  print("If it still doesn't work later, please report the issue at https://github.com/sthonnard/tzupdater")
  print("========================================================================================================================")
}