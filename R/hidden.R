# Variable for storing the name of the latest tz database found on the IANA website:
.tzupdater.globals <- new.env()
.tzupdater.globals$last_tz_db <- NA

# Get the active tz database insession - not allowing NULL:
.get_active_tz_db <- function()
{
  if (is.null(attr(OlsonNames(),"Version")))
  {
    return ("-----")
  }
  else
  {
    return(attr(OlsonNames(),"Version")) 
  }
}


# Activate a time zone database.
.activate_tz <- function(tz_path, verbose=TRUE)
{
  Sys.setenv(TZDIR=tz_path)
  if (verbose)
  {
    print(paste("Active tz db:",.get_active_tz_db()))
  }
}
