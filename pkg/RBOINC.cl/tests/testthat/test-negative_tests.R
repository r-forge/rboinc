# Original file name: "test-negative_tests.R"
# Created: 2022.11.14
# Last modified: 2022.11.14
# License: BSD-3-clause
# Written by: Astaf'ev Sergey <seryymail@mail.ru>
# This is a part of RBOINC R package.
# Copyright (c) 2022 Karelian Research Centre of
# the RAS: Institute of Applied Mathematical Research
# All rights reserved

test_that("create_connection tests", {
  expect_error({
    con = create_connection("ftp://server.local", "rboinc", "user", "user")
  }, "Unrecognized protocol: 'ftp'")

  expect_error({
    con = create_connection("server.local", "rboinc", "user", "user")
  }, "Unsupported server address format.")
})

test_that("create_jobs tests", {
  connection = list(type = "ftp")
  fn = function(val)
  {
    return(val)
  }

  expect_error({
    create_jobs(connection, fn, NULL, NULL)
  }, "You must specify 'data' or 'n'.")

  expect_error({
    create_jobs(connection, fn, 1:10, -1)
  }, "The number of tasks must be greater than 0.")

  expect_error({
    create_jobs(connection, fn, 1:10, 100)
  }, "The number of tasks must be less or equal than length of data.")

  expect_error({
    create_jobs(connection, fn, 1:10, 1)
  }, "Unknown protocol.")
})

test_that("update_jobs_status tests", {
  jobs_status = list(status = "done")
  connection = list(type = "ftp")
  expect_error({
    update_jobs_status(connection, jobs_status)
  }, "All results have already been received.")
  jobs_status$status = "aborted"
  expect_error({
    update_jobs_status(connection, jobs_status)
  }, "All jobs have already been canceled.")
  jobs_status$status = "in_progress"
  expect_error({
    update_jobs_status(connection, jobs_status)
  }, "Unknown protocol.")

})

test_that("cancel_jobs tests", {
  jobs_status = list(status = "done")
  connection = list(type = "ftp")
  expect_error({
    cancel_jobs(connection, jobs_status)
  }, "All results have already been received.")
  jobs_status$status = "aborted"
  expect_error({
    cancel_jobs(connection, jobs_status)
  }, "All jobs have already been canceled.")
  jobs_status$status = "in_progress"
  expect_error({
    cancel_jobs(connection, jobs_status)
  }, "Unknown protocol.")
})

test_that("test_jobs tests", {
  fn = function(val)
  {
    return(val)
  }

  expect_error({
    test_jobs(fn, NULL, NULL)
  }, "You must specify 'data' or 'n'.")

  expect_error({
    test_jobs(fn, 1:10, -1)
  }, "The number of tasks must be greater than 0.")

  expect_error({
    test_jobs(fn, 1:10, 100)
  }, "The number of tasks must be less or equal than length of data.")
})


