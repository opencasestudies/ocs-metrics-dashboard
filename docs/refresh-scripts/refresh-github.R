# C. Savonen

# Download that Github data

library(metricminer)
library(magrittr)

# Find .git root directory
root_dir <- rprojroot::find_root(rprojroot::has_dir(".git"))
source(file.path(root_dir, "refresh-scripts", "folder-setup.R"))

folder_path <- file.path("metricminer_data", "github")

# Declare and read in config file
yaml_file_path <- file.path(root_dir, "_config_automation.yml")
yaml <- yaml::read_yaml(yaml_file_path)

# Authorize Google
auth_from_secret("google",
                 refresh_token = Sys.getenv("METRICMINER_GOOGLE_REFRESH"),
                 access_token = Sys.getenv("METRICMINER_GOOGLE_ACCESS"),
                 cache = TRUE
)
# Authorize GitHub
auth_from_secret("github", token = Sys.getenv("METRICMINER_GITHUB_PAT"))

# Read the data
gh_metrics <- get_multiple_repos_metrics(repo_names = yaml$github_repos, time_course = FALSE, github_stats = c("stars", "forks", "contributors"))
gh_timecourse <- get_multiple_repos_metrics(repo_names = yaml$github_repos, time_course = TRUE)

setup_folders(
  folder_path = folder_path,
  google_entry = "github_googlesheet",
  config_file = yaml_file_path,
  data_name = "github"
)

yaml <- yaml::read_yaml(yaml_file_path)

if (yaml$data_dest == "google") {
    googlesheets4::write_sheet(gh_metrics,
                               ss = yaml$gh_googlesheet,
                               sheet = "overall_stats"
    )
    googlesheets4::write_sheet(gh_timecourse,
                               ss = yaml$gh_googlesheet,
                               sheet = "timecourse"
    )
}

if (yaml$data_dest == "github") {
  readr::write_tsv(gh_metrics,
      file.path(folder_path, "github.tsv")
    )
  readr::write_tsv(gh_timecourse,
      file.path(folder_path, "github_timecourse.tsv")
    )
}

sessionInfo()
