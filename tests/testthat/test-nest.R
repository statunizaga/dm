test_that("'nest_join_zoomed_dm()'-method for `zoomed_dm` works", {
  skip_if_remote_src()
  expect_equivalent_tbl(
    zoomed_dm_2() %>%
      nest_join_zoomed_dm() %>%
      pull_tbl(),
    tf_3() %>%
      nest_join(tf_2(), name = "tf_2", by = c("f" = "e")) %>%
      mutate(tf_2 = vctrs::as_list_of(tf_2)) %>%
      nest_join(tf_4(), name = "tf_4", by = c("f" = "j")) %>%
      mutate(tf_4 = vctrs::as_list_of(tf_4))
  )

  expect_equivalent_tbl(
    zoomed_dm_2() %>%
      nest_join_zoomed_dm(tf_4, tf_2) %>%
      pull_tbl(),
    tf_3() %>%
      nest_join(tf_4(), name = "tf_4", by = c("f" = "j")) %>%
      mutate(tf_4 = vctrs::as_list_of(tf_4)) %>%
      nest_join(tf_2(), name = "tf_2", by = c("f" = "e")) %>%
      mutate(tf_2 = vctrs::as_list_of(tf_2))
  )

  expect_message(
    expect_equivalent_dm(
      dm_rm_pk(dm_for_filter(), tf_3, TRUE) %>% dm_zoom_to(tf_3) %>% nest_join_zoomed_dm(),
      dm_rm_pk(dm_for_filter(), tf_3, TRUE) %>% dm_zoom_to(tf_3)
    ),
    "didn't have a primary key"
  )

  expect_dm_error(
    zoomed_dm_2() %>% select(g) %>% nest_join_zoomed_dm(),
    "pk_not_tracked"
  )
})

test_that("'nest_join_zoomed_dm()' fails for DB-'dm'", {
  skip_if_local_src()
  expect_dm_error(
    dm_zoom_to(dm_for_filter(), tf_3) %>% nest_join_zoomed_dm(),
    "only_for_local_src"
  )
})
