# Variable for storing the name of the latest tz database found on the IANA website:
.last_tz_db <<- NA

# Activate a time zone database.
.activate_tz <- function(tz_path, verbose=TRUE)
{
  Sys.setenv(TZDIR=tz_path)
  if (verbose)
  {
    print(paste("Current active tz db:",attr(OlsonNames(),"Version")))
  }
}
