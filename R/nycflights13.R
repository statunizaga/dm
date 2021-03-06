#' Creates a dm object for the \pkg{nycflights13} data
#'
#' @description Creates an example [`dm`] object from the tables in \pkg{nycflights13},
#' along with the references.
#' See [nycflights13::flights] for a description of the data.
#' As described in [nycflights13::planes], the relationship
#' between the `flights` table and the `planes` tables is "weak", it does not satisfy
#' data integrity constraints.
#'
#' @param cycle Boolean.
#'   If `FALSE` (default), only one foreign key relation
#'   (from `flights$origin` to `airports$faa`) between the `flights` table and the `airports` table is
#'   established.
#'   If `TRUE`, a `dm` object with a double reference
#'   between those tables will be produced.
#' @param color Boolean, if `TRUE` (default), the resulting `dm` object will have
#'   colors assigned to different tables for visualization with `dm_draw()`.
#' @param subset Boolean, if `TRUE` (default), the `flights` table is reduced to flights with column `day` equal to 10.
#'
#' @return A `dm` object consisting of {nycflights13} tables, complete with primary and foreign keys and optionally colored.
#'
#' @export
#' @examplesIf rlang::is_installed("nycflights13") && rlang::is_installed("DiagrammeR")
#' dm_nycflights13() %>%
#'   dm_draw()
dm_nycflights13 <- function(cycle = FALSE, color = TRUE, subset = TRUE) {
  airlines <- nycflights13::airlines
  airports <- nycflights13::airports
  planes <- nycflights13::planes

  if (subset) {
    flights <- flights_subset()
    weather <- weather_subset()
  } else {
    flights <- nycflights13::flights
    weather <- nycflights13::weather
  }

  dm <-
    dm(airlines, airports, flights, planes, weather) %>%
    dm_add_pk(planes, tailnum) %>%
    dm_add_pk(airlines, carrier) %>%
    dm_add_pk(airports, faa) %>%
    dm_add_fk(flights, tailnum, planes, check = FALSE) %>%
    dm_add_fk(flights, carrier, airlines) %>%
    dm_add_fk(flights, origin, airports)

  if (color) {
    dm <-
      dm %>%
      dm_set_colors(
        "#5B9BD5" = flights,
        "#ED7D31" = c(starts_with("air"), planes),
        "#70AD47" = weather
      )
  }

  if (cycle) {
    dm <-
      dm %>%
      dm_add_fk(flights, dest, airports, check = FALSE)
  }

  dm
}

flights_subset <- function() {
  nycflights13::flights %>%
    filter(day == 10)
}

weather_subset <- function() {
  nycflights13::weather %>%
    filter(day == 10)
}
