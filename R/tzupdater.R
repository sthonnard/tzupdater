
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
  tryCatch(
  {
      
    
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
      },warning = function(err){
        print("zic not found on your system!")
        if (.Platform$OS.type == "windows") {
          print("Please install Cygwin from https://www.cygwin.com")
        }else
        {
          print("Please install Linux package tzdata")
        }
        Sys.setenv(PATH = old_path)
        if (fail_if_zic_missing) {
          stop("Installation stopped!")
        }else
        {
          print(paste(tgt_version, "cannot be compiled because zic cannot be found."))
        }
      },
      error = function(e)
      {
        print(e$message)
        message("Unexpected error when running zic!")
      }
      )
    
    if (zic_found)
    { # zic has been found
      dir.create(target_folder, showWarnings = FALSE, recursive = TRUE)
      target_tar_file <- paste0(target_folder,"/tzdata",tgt_version,".tar.gz")
    
      target_untar <- paste0(target_folder,"/",tgt_version)
      target_compiled_version <- paste0(target_untar,"/compiled")
    
      iana_files_ok <- FALSE # Required files are there
      # Download the IANA Time Zone Database except if it was already done
      if (!(file.exists(target_tar_file)))
      {
        tz_url <- paste0(.tzupdater.globals$download_base_URL,"/tzdata",tgt_version,".tar.gz")
        tryCatch({
          ret <- utils::download.file(url = tz_url,
                        destfile = target_tar_file,
                        quiet = FALSE)
          if (ret != 0)
          {
            Sys.setenv(PATH = old_path)
            message(paste0("Download ", tgt_version, " at ", tz_url, " failed!"))
          }
          else
          {
            iana_files_ok <- TRUE
          }
        },
        warning = function(err) {
            iana_files_ok <- FALSE
            Sys.setenv(PATH = old_path)
            if (grepl("404", err$message) == 1)
            {
              message("Cannot fetch requested file (404 not found).")
              last_tz <- get_last_published_tz()
              if (last_tz == tgt_version) {.iana_not_reachable()}
              else
              {
                print(paste(tgt_version,"is not available!"))
              }
              
            }else if (grepl("Couldn't resolve host name", err$message) == 1)
            {
              message("IANA website is unreachable!")   
              .iana_not_reachable()
            }else
            {
              message(err$message)
              message(paste0("Cannot download ", tz_url))
            }
          }, 
          error = function(err) {
            iana_files_ok <- FALSE
            message(err$message)
            message("A critical issue occured, preventing to download the file.")
          },
        finally = {
            tryCatch(
              if (file.exists(target_tar_file) & !iana_files_ok) {unlink(target_tar_file)},
              warning = function(w) {print(paste("+ Unexpected warning when removing",target_tar_file))},
              error = function(e) {print(paste("+ Unexpected error when removing",target_tar_file))}
            )
          }
        )
      }else
      {
        iana_files_ok <- TRUE
      }
      
      if (iana_files_ok)
      {
      
        # Unzip the files and move them to a folder nammed with IANA release name
        utils::untar(tarfile = target_tar_file, exdir = target_untar)
      
        # Compile
        compilation_done <- TRUE
        compilated_zones <- 0
        for (zone in c("etcetera", "southamerica","northamerica","europe","africa","antarctica",
                       "asia", "australasia", "backward", "pacificnew","systemv", "factory"))
        {
          if (verbose) {print(paste("Compile",zone))}
          if (file.exists(paste0(target_untar,"/",zone)))
          {
            zic_out <- data.frame()
            zic_err <- data.frame()
            tryCatch(
              {
                zic_out <- data.frame(msg = system2("zic", paste0("-d ",paste0(target_compiled_version," ",
                                           target_untar,"/",zone)),
                     stdout = TRUE,
                     stderr = TRUE))
          
                zic_err <- subset(zic_out,!(grepl("warning: ", zic_out$msg) > 0))
              },
              warning = function(w)
              {
                # zic return status 1 should throw a warning
                zic_err <- data.frame(warning_message = w$message)
              },
              error = function(e)
              {
                zic_err <- data.frame(error_message = e$message)
              }
            )
            
            if (nrow(zic_out) > 0 & show_zic_log) {
              print(zic_out)
            }
            if (err_stop & nrow(zic_err) > 0 )
            {
              print(zic_err)
              compilation_done <- FALSE
              Sys.setenv(PATH = old_path)
              message("zic command didn't work as expected! Operation cancelled. You can force the compilation by setting parameter err_stop to FALSE. ?tzupdater for details.")
              .iana_not_reachable()
              break
            }
            compilated_zones <- compilated_zones + 1
          }else
          {
            if (!(zone %in% c("backward", "pacificnew","systemv", "factory")))
            {
              print(paste0("  Expected ",zone," was not in ",tgt_version,"!"))            
            }
          }
        } # For each zone
        
        if (compilation_done & compilated_zones > 0)
        {
          
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
        }else
        {
          message(paste0("Cannot install tz",tgt_version,"!"))
        }
      }
    }
  },
  warning = function(w)
  {
    print(w$message)
    message("Unexpected warning when installing a given Time Zone Database from The IANA website!")
    .iana_not_reachable()
  },
  error = function(e)
  {
    print(e$message)
    message("Unexpected error when installing a given Time Zone Database from The IANA website!")
    .iana_not_reachable()
  }  
  )
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
  tryCatch(
  {
    if (is.na(.tzupdater.globals$last_tz_db))
    { # Fetch on the IANA only once in the session
      tryCatch({
        
          OlsonDb.lastver <- readLines(.tzupdater.globals$IANA_website, warn = FALSE)
          OlsonDb.lastver <- gsub('</span','',strsplit(OlsonDb.lastver[grep('<span id="version">',OlsonDb.lastver)],'>')[[1]][2])
          anno <- try(as.numeric(substring(OlsonDb.lastver, 1, 4)), silent = TRUE)
          if (is.na(anno))
          {
            message("Cannot retrieve latest tz database name from the IANA. The html structure might have changed.")
            .tzupdater.globals$last_tz_db  <- 'Unknown'
          }
          else
          {
            .tzupdater.globals$last_tz_db <- OlsonDb.lastver
          }
      }, warning = function(warnmsg){
          message(warnmsg$message)
          message("Warning when retrieving the name of the latest tz database at https://www.iana.org/time-zones.")
          .iana_not_reachable()
          .tzupdater.globals$last_tz_db  <- 'Unknown'}
        ,error = function(err){
          message(err$message)
          message("Error when retrieving the name of the latest tz database at https://www.iana.org/time-zones.\nThis might be a temporary problem.\nIf you keep experiencing the issue please report at https://github.com/sthonnard/tzupdater")
          .tzupdater.globals$last_tz_db  <- 'Unknown'})
    }
  
  },
  warning = function(w){
    print(w$message)
    .tzupdater.globals$last_tz_db <- "Unknown"
    message("Unexpected warning when fetching latest Time Zone Database from The IANA website!")
    .iana_not_reachable()
  },
  error = function(e){
    print(e$message)
    .tzupdater.globals$last_tz_db <- "Unknown"
    message("Unexpected error when fetching latest Time Zone Database from The IANA website!")
    .iana_not_reachable()
  },
  finally = {return(.tzupdater.globals$last_tz_db)}
  )
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
    message(paste0("Please fetch the name of the last IANA tz database at https://www.iana.org/time-zones and install it with tzupdater::install_tz in case it does not match with your active tz db, ",get_active_tz_db()))
  }
  else
  {
    if (!(lastver == get_active_tz_db()))
    { # Local tz db outdated and fresher version does not exists in target_folder
      if (verbose)
      {
        print(paste0("Local tz database ", get_active_tz_db(), " outdated. Will install ",lastver, " now." ))
      }
      install_tz(lastver, zic_path, target_folder, show_zic_log = FALSE, err_stop = TRUE, activate_tz = TRUE, verbose )
    }
    else if (verbose)
    { # Nothing to do
      print(paste0("Local tz database ", get_active_tz_db(), " is up to date."))
    }
  }
}

