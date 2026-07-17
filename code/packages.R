# code/packages.R

# Toggle whether missing packages should be installed automatically
INSTALL_MISSING <- TRUE

pkgs <- c("signal", "tuneR", "seewave", "zoo", "remotes", "PupilPreprocess")

install_if_missing <- function(pkgs){
  missing <- pkgs[!pkgs %in% installed.packages()[, "Package"]]
  if(length(missing) && INSTALL_MISSING){
    install.packages(missing)
  }
}

# Install CRAN packages (exclude github-only package)
cran_pkgs <- setdiff(pkgs, "PupilPreprocess")
install_if_missing(cran_pkgs)

# Install/load github package
if(!("PupilPreprocess" %in% installed.packages()[, "Package"])){
  if(INSTALL_MISSING) remotes::install_github("nicobast/PupilPreprocess")
}
# Load all packages
invisible(lapply(pkgs, function(p) {
  suppressPackageStartupMessages(require(p, character.only = TRUE))
}))