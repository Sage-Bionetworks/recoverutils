#' Summarize data for i2b2/RECOVER
#'
#' `stat_summarize()` summarizes the data in a data frame on specific time scales (all data and weekly) for the
#' following statistics: 5/95 percentiles, mean, median, variance, number of records.
#'
#' @param df A data frame with `participantidentifier`, `concept`, `value`, and some combination of `startdate`,
#'   `enddate`, `date`, and `datetime` columns.
#'
#' @return A data frame that differs in size from `df`. The original `value` column is dropped and replaced by a new
#'   `value` column containing the values of each summary statistic computed for each group of data (group by
#'   `participantidentifier` and `concept` for all data, and `participantidentifier`, `concept`, `year`, `week` for
#'   weekly summaries).
#' @export
#'
#' @examples
#' # Create sample data
#' df <- data.frame(participantidentifier = c(rep("A", 6), rep("B", 6)),
#'                  date = c("2022-01-01", "2022-01-05", "2022-01-10", "2022-02-01",
#'                           "2022-02-05", "2022-02-10", "2022-01-01", "2022-01-06",
#'                           "2022-01-11", "2022-02-01", "2022-02-06", "2022-02-11"),
#'                  concept = c("weight", "weight", "weight", "weight", "weight", "weight",
#'                              "height", "height", "height", "height", "height", "height"),
#'                  value = c(60, 62, 64, 65, 66, 68, 160, 162, 164, 165, 166, 168))
#'
#' # Summarize the data
#' stat_summarize(df)
stat_summarize <- function(df) {
  
  if (!is.data.frame(df)) stop("df must be a data frame")
  if (!all(c("participantidentifier", "concept", "value") %in% colnames(df))) stop("'participantidentifier', 'concept', and 'value' columns must be present in df")
  
  summarize_alltime <- function(df) {
    if ("startdate" %in% colnames(df) & "enddate" %in% colnames(df)) {
      # Do nothing
    } else if ("date" %in% colnames(df)) {
      df <- 
        df %>% 
        dplyr::rename(startdate = date) %>% 
        dplyr::mutate(enddate = NA)
    } else if ("datetime" %in% colnames(df) & !"date" %in% colnames(df)) {
      df <- 
        df %>% 
        dplyr::rename(startdate = datetime) %>% 
        dplyr::mutate(enddate = NA)
    } else {
      stop("No 'startdate', 'enddate', 'date', or 'datetime' column found")
    }
    
    df %>%
      dplyr::select(participantidentifier, startdate, enddate, concept, value) %>%
      dplyr::group_by(participantidentifier, concept) %>%
      dplyr::reframe(startdate = lubridate::as_date(min(startdate)),
                enddate = lubridate::as_date(max(enddate)),
                mean = mean(as.numeric(value), na.rm = T),
                median = stats::median(as.numeric(value), na.rm = T),
                variance = stats::var(as.numeric(value), na.rm = T),
                `5pct` = stats::quantile(as.numeric(value), 0.05, na.rm = T),
                `95pct` = stats::quantile(as.numeric(value), 0.95, na.rm = T),
                numrecords = dplyr::n()) %>%
      dplyr::ungroup() %>% 
      tidyr::pivot_longer(cols = c(mean, median, variance, `5pct`, `95pct`, numrecords),
                   names_to = "stat",
                   values_to = "value") %>%
      dplyr::mutate(concept = paste0("mhp:summary:alltime:", stat, ":", concept)) %>%
      dplyr::select(participantidentifier, startdate, enddate, concept, value) %>%
      dplyr::distinct()
  }
  
  summarize_weekly <- function(df) {
    if ("startdate" %in% colnames(df)) {
      # Do nothing
    } else if ("date" %in% colnames(df)) {
      df <- 
        df %>% 
        dplyr::rename(startdate = date)
    } else if ("datetime" %in% colnames(df) & !"date" %in% colnames(df)) {
      df <- 
        df %>% 
        dplyr::rename(startdate = datetime)
    } else {
      stop("No 'startdate, enddate, date, or datetime' column found")
    }
    
    df %>%
      dplyr::select(participantidentifier, 
                    concept, 
                    value, 
                    startdate) %>% 
      dplyr::mutate(startdate = lubridate::as_date(startdate)) %>% 
      dplyr::filter(startdate >= lubridate::floor_date(min(startdate), 
                                                       unit = "week", 
                                                       week_start = 7)) %>% 
      dplyr::mutate(startdate = lubridate::floor_date(startdate, unit = "week", week_start = 7), 
                    enddate = startdate + lubridate::days(6)) %>% 
      dplyr::group_by(participantidentifier, 
                      concept, 
                      startdate, 
                      enddate) %>% 
      dplyr::reframe(`5pct` = stats::quantile(as.numeric(value), 0.05, na.rm = T), 
                     `95pct` = stats::quantile(as.numeric(value), 0.95, na.rm = T), 
                     mean = mean(as.numeric(value), na.rm = T), 
                     median = stats::median(as.numeric(value), na.rm = T), 
                     variance = stats::var(as.numeric(value), na.rm = T), 
                     numrecords = dplyr::n()) %>% 
      dplyr::ungroup() %>% 
      tidyr::pivot_longer(cols = c(mean, median, variance, `5pct`, `95pct`, numrecords), 
                          names_to = "stat", 
                          values_to = "value") %>% 
      dplyr::mutate(concept = paste0("mhp:summary:weekly:", stat, ":", concept)) %>% 
      dplyr::select(participantidentifier, startdate, enddate, concept, value) %>% 
      dplyr::distinct()
  }
  
  result <- 
    dplyr::bind_rows(summarize_alltime(df), 
                     summarize_weekly(df)) %>% 
    dplyr::distinct()
  
  return(result)
}
