#' @title Rollup Channel Unit Undercut Data
#'
#' @description Summarize individual undercut data (e.g., from `otg_type =` "Undercut_4.csv) at
#' the channel unit scale
#'
#' @author Mike Ackerman, Richie Carmichael, and Kevin See
#'
#' @param undercut_df data.frame of `otg_type =` "Undercut_4.csv" containing the individual
#' undercut data to be summarized (rolled up) to the channel unit scale
#' @param fix_nas if any of the length or width measurements for an individual undercut
#' is missing i.e., `NA`, would you like to fill them in? Default is `TRUE`, in which
#' case the `NA` values will be imputed using function `impute_missing_values()
#' @param impute_cols character vector of column names that should be imputed, if `fix_nas == TRUE`
#' @param ... other arguments to `impute_missing_values()`
#'
#' @import dplyr
#' @export
#' @return a data.frame summarizing undercut data at the channel unit scale

rollup_cu_undercut = function(undercut_df = NULL,
                              fix_nas = TRUE,
                              impute_cols = c("length_m",
                                              "width_25_percent_m",
                                              "width_50_percent_m",
                                              "width_75_percent_m"),
                              ...) {

  stopifnot(!is.null(undercut_df))

  # how many missing values in individual undercuts
  n_nas = undercut_df %>%
    dplyr::select(dplyr::any_of(impute_cols)) %>%
    is.na() %>%
    sum()

  if( fix_nas == TRUE & n_nas == 0 ) cat("No missing values in impute_cols of undercut_df\n")

  # fix missing values in individual undercuts
  if( fix_nas == TRUE & n_nas > 0) {

    cat("Imputing some missing values in undercut_df\n")

    fix_df = impute_missing_values(undercut_df,
                                   col_nm_vec = impute_cols,
                                   ...)

    undercut_df = fix_df

  } # end if( fix_nas == TRUE & n_nas > 0 ) loop

  # now start data rollup
  return_df = undercut_df %>%
    dplyr::select(-(creation_date:editor)) %>%
    dplyr::mutate(avg_width_m = (width_25_percent_m + width_50_percent_m + width_75_percent_m) / 3) %>%
    dplyr::mutate(area_m2 = length_m * avg_width_m) %>%
    dplyr::group_by(parent_global_id) %>%
    dplyr::summarise(undct_n = length(parent_global_id),
                     undct_n_left = length(parent_global_id[location == "Left_Bank"]),
                     undct_n_right = length(parent_global_id[location == "Right_Bank"]),
                     undct_n_islnd = length(parent_global_id[location == "Island"]),
                     undct_length_m = sum(length_m),
                     undct_area_m2 = sum(area_m2)) %>%
    dplyr::mutate(undct_length_m = round(undct_length_m, 2)) %>%
    dplyr::mutate(undct_area_m2 = round(undct_area_m2, 2))

  return(return_df)

} # end rollup_cu_undercut() function
