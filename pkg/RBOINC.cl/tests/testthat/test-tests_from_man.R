# Original file name: "test-tests_from_man.R"
# Created: 2022.11.14
# Last modified: 2022.11.14
# License: BSD-3-clause
# Written by: Astaf'ev Sergey <seryymail@mail.ru>
# This is a part of RBOINC R package.
# Copyright (c) 2022 Karelian Research Centre of
# the RAS: Institute of Applied Mathematical Research
# All rights reserved

test_that("example 0", {
  skip_on_cran()
  fun = function(val)
  {
    return(val*5)
  }

  data = 1:9

  res = test_jobs(fun, data)
  flag = TRUE
  for(k in 1:9){
    if(res[[k]]$result != k*5){
      flag = FALSE
    }
  }
  expect_equal(flag, TRUE)
})

test_that("example 1", {
  skip_on_cran()
  fun = function(val)
  {
    return(val*5)
  }

  data = 1:9

  res = test_jobs(fun, data, 2)
  flag = TRUE
  for(k in 1:9){
    if(res[[k]]$result != k*5){
      flag = FALSE
    }
  }
  expect_equal(flag, TRUE)
})

test_that("example 2", {
  skip_on_cran()
  fac = function(val)
  {
    if(val == 0 || val == 1){
      return(val)
    } else {
      return(val*fac(val- 1))
    }
  }

  data = 1:9

  res = test_jobs(fac, data, 2)
  rval = 1
  flag = TRUE
  for(k in 1:9){
    rval = rval * k
    if(res[[k]]$result != rval){
      flag = FALSE
    }
  }
  expect_equal(flag, TRUE)
})


test_that("example 3", {
  skip_on_cran()
  N = 10000

  pi_approx = function()
  {
    a = runif(N,0,1)
    b = runif(N,0,1)
    res = sum(a*a+b*b < 1)/N
    return(res)
  }

  res = test_jobs(pi_approx, n = 10, global_vars = list(N = N))

  prob = 0
  count = 0
  for(val in res){
    prob = prob + val$result
    count = count + 1
  }
  expect_equal(abs(prob/count*4 - pi) < 0.1, TRUE)
})

test_that("example 7", {
  skip_on_cran()
  fun = function(val)
  {
    return(val*5)
  }

  callback = function(val)
  {
    return(val/2)
  }

  data = 1:9

  res = test_jobs(fun, data, 2, callback_function = callback)
  flag = TRUE
  for(k in 1:9){
    if(res[[k]]$result != k*5/2){
      flag = FALSE
    }
  }
  expect_equal(flag, TRUE)
})

