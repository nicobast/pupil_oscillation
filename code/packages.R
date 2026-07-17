# code/packages.R

# Toggle whether missing packages should be installed automatically
INSTALL_MISSING <- TRUE

# Define packages by source
cran_pkgs <- c("signal", "tuneR", "seewave", "zoo", "remotes")
github_pkgs <- list("PupilPreprocess" = "nicobast/PupilPreprocess")
bioc_pkgs <- c("rhdf5")

# All packages list for loading
all_pkgs <- c(cran_pkgs, names(github_pkgs), bioc_pkgs)

# Function to install missing packages
install_if_missing <- function(pkgs, source = "cran", github_info = NULL) {
  missing <- pkgs[!pkgs %in% installed.packages()[, "Package"]]
  
  if (length(missing) && INSTALL_MISSING) {
    if (source == "cran") {
      message("Installing CRAN packages: ", paste(missing, collapse = ", "))
      install.packages(missing)
    } else if (source == "github") {
      message("Installing GitHub packages: ", paste(missing, collapse = ", "))
      for (pkg in missing) {
        if (!is.null(github_info) && pkg %in% names(github_info)) {
          remotes::install_github(github_info[[pkg]])
        }
      }
    } else if (source == "bioc") {
      message("Installing Bioconductor packages: ", paste(missing, collapse = ", "))
      if (!requireNamespace("BiocManager", quietly = TRUE)) {
        install.packages("BiocManager")
      }
      BiocManager::install(missing)
    }
  }
}

# Install CRAN packages
install_if_missing(cran_pkgs, source = "cran")

# Install GitHub packages
if (length(github_pkgs) > 0) {
  install_if_missing(names(github_pkgs), source = "github", github_info = github_pkgs)
}

# Install Bioconductor packages
if (length(bioc_pkgs) > 0) {
  install_if_missing(bioc_pkgs, source = "bioc")
}

# Load all packages
message("Loading packages...")
invisible(lapply(all_pkgs, function(p) {
  if (p %in% installed.packages()[, "Package"]) {
    suppressPackageStartupMessages(require(p, character.only = TRUE))
    message("  - Loaded: ", p)
  } else {
    warning("  - Package not available: ", p)
  }
}))
message("Package installation and loading complete.")