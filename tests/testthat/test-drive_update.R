context("Update files")

# ---- nm_fun ----
me_ <- nm_fun("TEST-drive-update")
nm_ <- nm_fun("TEST-drive-update", NULL)

# ---- clean ----
if (CLEAN) {
  drive_trash(c(
    nm_("update-fodder"),
    nm_("not-unique"),
    nm_("does-not-exist")
  ))
}

# ---- setup ----
if (SETUP) {
  drive_upload(system.file("DESCRIPTION"), nm_("update-fodder"))
  drive_upload(system.file("DESCRIPTION"), nm_("not-unique"))
  drive_upload(system.file("DESCRIPTION"), nm_("not-unique"))
}

# ---- tests ----
test_that("drive_update() errors if local media does not exist", {
  expect_error(
    drive_update(dribble(), "nope123"),
    "Local file does not exist"
  )
})

test_that("drive_update() informatively errors if the path does not exist",{
  skip_if_no_token()
  skip_if_offline()
  expect_error(
    drive_update(nm_("does-not-exist"), system.file("DESCRIPTION")),
    "does not identify at least one"
  )
})

test_that("drive_update() informatively errors if the path is not unique",{
  skip_if_no_token()
  skip_if_offline()
  expect_error(
    drive_update(nm_("not-unique"), system.file("DESCRIPTION")),
    "more than one"
  )
})

test_that("no op if no media, no metadata", {
  skip_if_no_token()
  skip_if_offline()

  expect_message(
    out <- drive_update(nm_("update-fodder")),
    "No updates specified"
  )
  expect_s3_class(out, "dribble")
})

test_that("drive_update() can update metadata only", {
  skip_if_no_token()
  skip_if_offline()
  on.exit(drive_rm(me_("update-me")))

  updatee <- drive_cp(nm_("update-fodder"), name = me_("update-me"))
  out <- drive_update(updatee, starred = TRUE) %>% promote("starred")
  expect_true(out$starred)
})

test_that("drive_update() uses multipart request to update media + metadata",{
  skip_if_no_token()
  skip_if_offline()
  on.exit(drive_rm(c(me_("update-me"), me_("update-me-new"))))

  updatee <- drive_cp(nm_("update-fodder"), name = me_("update-me"))
  tmp <- tempfile()
  now <- as.character(Sys.time())
  writeLines(now, tmp)

  out <- drive_update(updatee, media = tmp, name = me_("update-me-new"))
  expect_identical(out$id, updatee$id)
  drive_download(updatee, tmp, overwrite = TRUE)
  now_out <- readLines(tmp)
  expect_identical(now, now_out)
  expect_identical(out$name, me_("update-me-new"))
})
