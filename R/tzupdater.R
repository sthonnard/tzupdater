
#' tzupdater: A Tool For Automatically Download And Compile Tz Database From The IANA Website.
#'
#' Download and compile any version of the IANA Time Zone Database (also known as Olson database) and make it current
#' in your R session.
#' This will NOT replace your system tz database.
#'
#' Context:\cr
#' It can be useful to download and compile the latest tz database because tz information are constently changing,
#' hence your system might not have the latest version. Outdated tz database can cause troubles when converting from UTC to local time
#' and vice-versa. You won't have any obvious error, you will just get wrong UTC offset or zone name.
#'
#' Prerequisite:\cr
#' You need the timezone compiler (zic). \cr
#'  -On Windows you can get it by installing Cygwin (\url{https://www.cygwin.com})\cr
#'   zic should be installed in C:\\Cygwin\\usr\\sbin by default. If you installed Cygwin somewhere else, \cr
#'   please add the zic path to your environment pariable PATH or specify the path in the function call.\cr
#'  -On macOS zic is installed by default.\cr
#'  -On Linux zic is generally already available. Otherwise it is part of package tzdata.\cr
#'  Using Alpine Linux you can get it by running the following command:\cr
#'  apk add tzdata
#'  
#'  Bugs report:\cr
#'  \url{https://github.com/sthonnard/tzupdater}
#'
#'
#' @section tzupdater functions:
#' \strong{install_last_tz()}\cr
#' Automatically get the latest version available and compile it. Once done make it active. 
#' If your tz database is already the latest, do nothing.
#'
#' \strong{get_last_published_tz()}\cr
#' Get the name of the latest version available at IANA website.\cr
#'
#' \strong{get_active_tz_db()}\cr
#' Get the active tz database version on your session.\cr
#'
#' \strong{install_tz(version_to_install)}\cr
#' Download and install the IANA time zone specified in parameter.
#'
#'
#' @docType package
#' @name tzupdater
#'

source("./R/hidden.R")


#' install_tz
#'
#' Download and compile a tz database from the IANA website and make it active as an option.
#' In case the tz db exists already, do not download again.
#'
#' @param tgt_version  Version to download and compile (eg 2019c, 2019a).
#' @param zic_path  Optional for Windows: path to the zic compiler (if not in C:\\Cygwin\\usr\\sbin)
#' @param target_folder Optional target folder. Default will be tzupdater/data/IANA_release as in tempdir()
#' @param show_zic_log  Optional: show logs from the zic compiler (TRUE/FALSE). Default FALSE.
#' @param err_stop Stop on error (TRUE/FALSE). Default TRUE. Recommanded to TRUE.
#' @param activate_tz Activate the tz database once installed. Default TRUE.
#' @param verbose Print additional information to the console TRUE/FALSE. Default TRUE.
#' @param fail_if_zic_missing Stop execution if zic is missing (default FALSE, will only display a message)
#'
#' @export
#'
#' @examples
#' # Install tz database 2019c
#' install_tz("2019c")
#'
install_tz <- function(tgt_version = "2019c", zic_path = NA,  
                       target_folder = paste0(tempdir(),"/tzupdater/data/IANA_release"),
                       show_zic_log = FALSE, err_stop = TRUE, activate_tz = TRUE, verbose = TRUE,
                       fail_if_zic_missing = FALSE) {
  # On Windows set default zic path to C:\\Cygwin\\usr\\sbin if zic_path not provided
  old_path <- Sys.getenv("PATH")
  zic_found <- FALSE
  if (is.na(zic_path) & .Platform$OS.type == "windows" & file.exists("C:\\Cygwin\\usr\\sbin"))
  { # no zic path provided and on a Windows platform, set to default Cygwin path to zic
    zic_path <- "C:\\Cygwin\\usr\\sbin"
  }
  # Add zic to system path in case zic_path is set. (on Windows mostly)
  if (!is.na(zic_path))
  {
    Sys.setenv(PATH = paste(old_path,zic_path, sep = ";"))
  }
  # Test that zic is available
  tryCatch({
    system2("zic")
    zic_found <- TRUE
    },warning=function(err){
    print("zic not found on your system!")
    if ( .Platform$OS.type == "windows"){print("Please install Cygwin from https://www.cygwin.com")}else
    {
      print("Please install Linux package tzdata")
    }
    Sys.setenv(PATH = old_path)
    if (fail_if_zic_missing){
      stop("Installation stopped!")
    }else
    {
      print(paste(tgt_version, "cannot be compiled because zic cannot be found."))
    }
    }
    )
  
  if (zic_found)
  { # zic has been found
    dir.create(target_folder, showWarnings = FALSE, recursive = TRUE)
    target_tar_file <- paste0(target_folder,"/tzdata",tgt_version,".tar.gz")
  
    target_untar <- paste0(target_folder,"/",tgt_version)
    target_compiled_version <- paste0(target_untar,"/compiled")
  
  
    # Download the IANA Time Zone Database except if it was already done
    if (!(file.exists(target_tar_file)))
    {
      tz_url <- paste0("https://data.iana.org/time-zones/releases/tzdata",tgt_version,".tar.gz")
      tryCatch({
        ret <- utils::download.file(url = tz_url,
                      destfile = target_tar_file,
                      quiet = FALSE)
        if(ret != 0)
        {
          Sys.setenv(PATH = old_path)
          stop(paste0("Download ", tgt_version, " at ", tz_url, " failed!"))
        }
      },
      warning, error=function(err) {
        message(err$message)
        Sys.setenv(PATH = old_path)
        if (grepl("404", err$message) == 1)
        {
          stop("Cannot fetch requested file. IANA website might have changed. Please try again later.\nIf it does not work, please report the issue at https://github.com/sthonnard/tzupdater")
        }else if (grepl("Couldn't resolve host name", err$message) == 1)
        {
          stop("IANA website is unreachable! Please try again later.\nIf it does not work, please report the issue at https://github.com/sthonnard/tzupdater")    
        }else
        {
          stop(paste0("Cannot download ", tz_url))
        }      
      }
      )
    }
  
    # Unzip the files and move them to a folder nammed with IANA release name
    utils::untar(tarfile = target_tar_file, exdir = target_untar)
  
    # Compile
    for (zone in c("etcetera", "southamerica","northamerica","europe","africa","antarctica",
                   "asia", "australasia", "backward", "pacificnew","systemv"))
    {
      if (verbose){print(paste("Compile",zone))}
      zic_out <- data.frame(msg=system2("zic", paste0("-d ",paste0(target_compiled_version," ",
                                   target_untar,"/",zone)),
             stdout = TRUE,
             stderr = TRUE))
  
      zic_err <- subset(zic_out,!(grepl("warning: ", zic_out$msg)>0))
      if (nrow(zic_out) > 0 & show_zic_log){
        print(zic_out)
      }
      if (err_stop & nrow(zic_err) > 0 )
      {
        print(zic_err)
        Sys.setenv(PATH = old_path)
        stop("zic command didn't work as expected! Operation cancelled. You can force the compilation by setting parameter err_stop to FALSE. ?tzupdater for details.")
      }
  
    }
  
    cat(tgt_version, file = paste0(target_compiled_version,"/+VERSION"), append = FALSE)
    if (verbose)
    {
      print(paste("IANA Time Zone Database", tgt_version, "installed in", gsub("\\./",getwd(),target_compiled_version)))
    }
    if (activate_tz)
    {
      # Set to current
      .activate_tz(target_compiled_version, verbose)
    }
    
    # Set the path as it was before adding the zic path
    Sys.setenv(PATH = old_path)
  }
}


#' get_active_tz_db
#'
#' Get the active tz database version
#'
#'
#' @return Active tz database for the current session.
#' @export
#'
#' @examples
#' # Get the active tz database in your session:
#' get_active_tz_db()
get_active_tz_db <- function()
{
  return(.get_active_tz_db())
}


#' get_last_published_tz
#'
#' Get the name of the latest version available at IANA website.
#'
#' @return Latest IANA tz db version name or Unknown if not found.
#' @export
#'
#' @examples
#' # Will return for instance "2019c"
#' get_last_published_tz()
get_last_published_tz <- function()
{
  if (is.na(.tzupdater.globals$last_tz_db))
  { # Fetch on the IANA only once in the session
    tryCatch({
      
        OlsonDb.lastver <- readLines("https://www.iana.org/time-zones")
        OlsonDb.lastver <- gsub('</span','',strsplit(OlsonDb.lastver [grep('<span id="version">',OlsonDb.lastver)],'>')[[1]][2])
        anno <- try(as.numeric(substring(OlsonDb.lastver, 1, 4)), silent = TRUE)
        if (is.na(anno))
        {
          warning("Cannot retrieve latest tz database name from the IANA. The html structure might have changed.")
          .tzupdater.globals$last_tz_db  <- 'Unknown'
        }
        else
        {
          .tzupdater.globals$last_tz_db <- OlsonDb.lastver
        }
    }, warning,error=function(err){
      message(err$message)
      message("Cannot retrieve the name of the latest tz database at https://www.iana.org/time-zones.\nThis might be a temporary problem.\nIf you keep experiencing the issue please report at https://github.com/sthonnard/tzupdater")
      .tzupdater.globals$last_tz_db  <- 'Unknown'
    })
  }

  return(.tzupdater.globals$last_tz_db)

}


#' install_last_tz
#'
#' Install latest tz database if required, and make it active.\cr\cr
#' Will stop in case it is not possible to know what the last version is.\cr
#' If it happens browse IANA website at https://www.iana.org/time-zones and install last version with install_tz(version).\cr
#' ?install_tz for details.
#'
#' @param zic_path  Optional for Windows: path to the zic compiler (if not in
#'   C:\\Cygwin\\usr\\sbin).
#' @param target_folder Optional target folder. Default will be
#'   tzupdater/data/IANA_release as subdirectory of your temp dir.
#' @param verbose Print information to the console TRUE/FALSE. Default TRUE.
#'
#' @return None.
#' @export
#'
#' @examples
#'
#' # Get the latest version available and compile. 
#' # If your tz database is already the latest, do nothing.
#' install_last_tz()
#'
#' # Same, but more verbose.
#' install_last_tz(verbose = TRUE)
#'
#' # On Windows: install latest tz database, with Cygwin installed in c:\\Cygwin.
#' install_last_tz(zic_path="C:\\Cygwin\\usr\\sbin")
install_last_tz <- function(zic_path = NA, target_folder = paste0(tempdir(),"/tzupdater/data/IANA_release"), verbose = TRUE)
{
  lastver <- get_last_published_tz()
  if (lastver == "Unknown")
  {
    stop(paste0("Please fetch the name of the last IANA tz database at https://www.iana.org/time-zones and install it with tzupdater::install_tz in case it does not match with your active tz db, ",get_active_tz_db()))
  }


  if(!(lastver==get_active_tz_db()) & !(file.exists(paste0(target_folder, "/", lastver)) ))
  { # Local tz db outdated and fresher version does not exists in target_folder
    if (verbose)
    {
      print(paste0("Local tz database ", get_active_tz_db(), " outdated. Will install ",lastver, " now." ))
    }
    install_tz(lastver, zic_path, target_folder, show_zic_log=FALSE, err_stop = TRUE, activate_tz = TRUE, verbose )
  }
  else if(!(lastver==get_active_tz_db()) & !(file.exists(paste0(target_folder, "/", lastver)) ))
  { # Local tz db outdated and fresher version exists in target_folder
    .activate_tz(paste0(target_folder, "/", lastver), verbose)
    print(paste0("Local tz database ", get_active_tz_db(), " in folder ", target_folder, " is up to date."))
  }
  else if (verbose)
  { # Nothin to do
    print(paste0("Local tz database ", get_active_tz_db(), " is up to date."))
  }
}

