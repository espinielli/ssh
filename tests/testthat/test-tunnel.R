context("tunnel")

R <- file.path(R.home("bin"), "R")

test_that("Tunneling works", {
  for(i in 1:3){
    pid <- sys::exec_background(R, c("-e", "ssh::ssh_tunnel()"), std_out = FALSE, std_err = FALSE)
    on.exit(tools::pskill(pid, tools::SIGKILL))
    Sys.sleep(3)
    expect_equal(sys::exec_status(pid, wait = FALSE), NA_integer_)
    con <- mongolite::mongo("mtcars", url = "mongodb://readwrite:test@localhost:5555/jeroen_test")
    expect_is(con, 'mongo')
    if(con$count())
      con$drop()
    con$insert(mtcars)
    out <- con$find()
    expect_equal(out, mtcars)
    con$drop()
    if(i == 2){
      tools::pskill(pid, tools::SIGINT)
    } else {
      rm(con); gc()
    }
    expect_equal(sys::exec_status(pid), 0)
    expect_error(con$count())
  }
})

test_that("Recycle port",{
  # Start tunnel twice!
  pid <- sys::exec_background(R, c("-e", "for(i in 1:2) ssh::ssh_tunnel()"), std_out = FALSE, std_err = FALSE)

  # Connect and disconnect twice on the same parent process
  for(i in 1:2){
    Sys.sleep(3)
    expect_equal(sys::exec_status(pid, wait = FALSE), NA_integer_)
    con <- mongolite::mongo("mtcars", url = "mongodb://readwrite:test@localhost:5555/jeroen_test")
    expect_is(con, 'mongo')
    rm(con); gc();
  }

  Sys.sleep(3)
  expect_error(mongolite::mongo("mtcars", url = "mongodb://readwrite:test@localhost:5555/jeroen_test"))
  expect_equal(sys::exec_status(pid, wait = FALSE), 0)
})