test_that("Additional make_archive test", {
  skip_on_cran()
  inst = function(pckgs){
     prepare = function(val){
       return(val*2)
     }
     save(prepare, file = "prepare.rda")
  }
  init = function()
  {
    load("prepare.rda", .GlobalEnv)
  }
  fun = function(val)
  {
    return(prepare(val) + 2)
  }

  res = test_jobs(fun, 1:10, 2, init, install_func = inst)

  flag = TRUE
  for(k in 1:10){
    if(res[[k]]$result != k*2+2){
      flag = FALSE
    }
  }
  expect_equal(flag, TRUE)
})
