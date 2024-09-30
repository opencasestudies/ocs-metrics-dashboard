# C. Savonen

# Download that Google Forms data

library(metricminer)
library(magrittr)
library(dplyr)

# Find .git root directory
root_dir <- rprojroot::find_root(rprojroot::has_dir(".git"))
source(file.path(root_dir, "refresh-scripts", "folder-setup.R"))

folder_path <- file.path("metricminer_data", "googleforms")

# Declare and read in config file
yaml_file_path <- file.path(root_dir, "_config_automation.yml")
yaml <- yaml::read_yaml(yaml_file_path)

# Authorize Google
auth_from_secret("google",
  refresh_token = Sys.getenv("METRICMINER_GOOGLE_REFRESH"),
  access_token = Sys.getenv("METRICMINER_GOOGLE_ACCESS"),
  cache = TRUE
)

setup_folders(
  folder_path = folder_path,
  google_entry = "gf_googlesheet",
  config_file = yaml_file_path,
  data_name = "googleforms"
)


#### Get the Google Forms data
google_forms <- get_multiple_forms(form_ids = yaml$google_forms)
form_names <- names(google_forms)

yaml <- yaml::read_yaml(yaml_file_path)

if (yaml$data_dest == "google") {
  lapply(form_names, function(form_name) {
    # Writing the number of responses (e.g., non-empty rows)
    googlesheets4::write_sheet(nrow(google_forms[[form_name]]$answers %>% dplyr::filter(!if_all(everything(), .fns = is.na))),
      ss = yaml$gf_googlesheet,
      sheet = form_name
    )
  })
}

if (yaml$data_dest == "github") {
  lapply(form_names, function(form_name) {
    # Writing the number of responses (e.g., non-empty rows)
    readr::write_tsv(
      nrow(google_forms[[form_name]]$answers %>% dplyr::filter(!if_all(everything(), .fns = is.na))),
      file.path(folder_path, paste0(form_name, ".tsv"))
    )
  })
}

sessionInfo()
