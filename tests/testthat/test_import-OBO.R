context("import-OBO")

test_that("'import.obo()' works", {
    oboFile <- system.file("extdata", "sample_go.obo", package = "BiocSet")

    ## minimal
    foo <- import.obo(oboFile)
    expect_s4_class(foo, "OBOSet")
    expect_true(.is_tbl_elementset(.elementset(foo)))
    expect_identical(dim(.element(foo)), c(7L, 6L))
    expect_identical(dim(.set(foo)), c(7L, 5L))
    expect_identical(dim(.elementset(foo)), c(7L, 2L))
    expect_type(.element(foo)$obsolete, "logical")
    expect_type(.element(foo)$children, "list")
    expect_type(.set(foo)$name, "character")

    element_nms <- c("element", "name", "parents", "children", "ancestors", "obsolete")
    expect_true(all(element_nms %in% colnames(.element(foo))))

    set_nms <- c("set", "name", "parents", "children", "ancestors")
    expect_true(all(set_nms %in% colnames(.set(foo))))
    
    ## everything
    foo_all <- import.obo(oboFile, extract_tag = "everything")
    expect_s4_class(foo_all, "OBOSet")
    expect_true(.is_tbl_elementset(.elementset(foo_all)))
    expect_identical(dim(.element(foo_all)), c(7L, 26L))
    expect_identical(dim(.set(foo_all)), c(7L, 5L))
    expect_identical(dim(.elementset(foo_all)), c(7L, 2L))
    expect_type(.element(foo_all)$obsolete, "logical")
    expect_type(.element(foo_all)$children, "list")
    expect_type(.set(foo_all)$name, "character")

    expect_true(all(element_nms %in% colnames(.element(foo_all))))
    expect_true(all(set_nms %in% colnames(.set(foo_all))))

    expect_error(import.obo())
    expect_error(import.obo(oboFile, all))
    expect_error(import.obo(oboFile, extract_tag = all))
    expect_error(import.obo(oboFile, extract_tag = "all"))
})

test_that("'import()' works", {
    oboFile <- system.file("extdata", "sample_go.obo", package = "BiocSet")

    ## minimal
    foo <- import(oboFile)
    expect_s4_class(foo, "OBOSet")
    expect_true(.is_tbl_elementset(.elementset(foo)))
    expect_identical(dim(.element(foo)), c(7L, 6L))
    expect_identical(dim(.set(foo)), c(7L, 5L))
    expect_identical(dim(.elementset(foo)), c(7L, 2L))

    ## everything
    foo_all <- import(oboFile, extract_tag = "everything")
    expect_s4_class(foo_all, "OBOSet")
    expect_true(.is_tbl_elementset(.elementset(foo_all)))
    expect_identical(dim(.element(foo_all)), c(7L, 26L))
    expect_identical(dim(.set(foo_all)), c(7L, 5L))
    expect_identical(dim(.elementset(foo_all)), c(7L, 2L))

    expect_error(import())
    expect_error(import(oboFile, all))
    expect_error(import(oboFile, extract_tag = all))
    expect_error(import(oboFile, extract_tag = "all"))
})