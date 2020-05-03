#' Load a dm from a remote data source
#'
#' `dm_from_src()` creates a [dm] from some or all tables in a [src]
#' (a database or an environment) or which are accessible via a DBI-Connection.
#' For Postgres and SQL Server databases, primary and foreign keys
#' are imported from the database.
#'
#' @param src A \pkg{dplyr} table source object or a
#'   [`DBI::DBIConnection-class`] object is accepted.
#' @param table_names
#'   A character vector of the names of the tables to include.
#' @param learn_keys
#'   \lifecycle{experimental}
#'
#'   Set to `TRUE` to query the definition of primary and
#'   foreign keys from the database.
#'   Currently works only for Postgres and SQL Server databases.
#'   The default attempts to query and issues an informative message.
#' @param ...
#'   \lifecycle{experimental}
#'
#'   Additional parameters for the schema learning query.
#'   Currently supports `schema` (default: `"public"`)
#'   and `table_type` (default: `"BASE TABLE"`) for Postgres databases.
#'
#' @return A `dm` object.
#'
#' @export
#' @examples
#' dm_from_src_demo <- function() {
#'   if (!rlang::is_installed("DBI")) {
#'     message("Install the DBI package to run this example.")
#'   }
#'
#'   con <- DBI::dbConnect(
#'     RMariaDB::MariaDB(),
#'     username = "guest",
#'     password = "relational",
#'     dbname = "Financial_ijs",
#'     host = "relational.fit.cvut.cz"
#'   )
#'   on.exit(DBI::dbDisconnect(con))
#'
#'   dm_from_src(con)
#' }
#'
#' dm_from_src_demo()
dm_from_src <- function(src = NULL, table_names = NULL, learn_keys = NULL,
                        ...) {
  if (is_null(src)) {
    # FIXME: Check empty arguments and ellipsis
    return(empty_dm())
  }
  # both DBI-Connection and {dplyr}-src object are accepted
  src <- src_from_src_or_con(src)

  if (is.null(learn_keys) || isTRUE(learn_keys)) {
    dm_learned <- dm_learn_from_db(src, ...)

    if (is.null(dm_learned)) {
      if (isTRUE(learn_keys)) {
        abort_learn_keys()
      }

      inform("Keys could not be queried, use `learn_keys = FALSE` to mute this message.")
    } else {
      if (is_null(learn_keys)) {
        inform("Keys queried successfully, use `learn_keys = TRUE` to mute this message.")
      }

      tbls_in_dm <- src_tbls(dm_learned)

      if (is_null(table_names)) {
        return(dm_learned)
      }

      if (!all(table_names %in% tbls_in_dm)) {
        abort_req_tbl_not_avail(src_tbl_names, setdiff(table_names, tbls_in_dm))
      }
      tbls_req <- intersect(tbls_in_dm, table_names)

      return(dm_learned %>% dm_select_tbl(!!!tbls_req))
    }
  }

  src_tbl_names <- unique(src_tbls(src))
  if (is_null(table_names)) {
    table_names <- src_tbl_names
  } else {
    if (!all(table_names %in% src_tbl_names)) {
      abort_req_tbl_not_avail(src_tbl_names, setdiff(table_names, src_tbl_names))
    }
  }

  tbls <- map(set_names(table_names), tbl, src = src)

  new_dm(tbls)
}


# Errors ------------------------------------------------------------------

abort_learn_keys <- function() {
  abort(error_txt_learn_keys(), .subclass = dm_error_full("learn_keys"))
}

error_txt_learn_keys <- function() {
  "Failed to learn keys from database. Use `learn_keys = FALSE` to work around."
}

abort_req_tbl_not_avail <- function(avail, missing) {
  abort(error_txt_req_tbl_not_avail(avail, missing), .subclass = dm_error_full("req_tbl_not_avail"))
}

error_txt_req_tbl_not_avail <- function(avail, missing) {
  glue("Table(s) {commas(tick(missing))} not available on `src`. Available tables are: {commas(tick(avail))}.")
}