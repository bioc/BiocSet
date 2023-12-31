context("mapping_element")

library(org.Hs.eg.db)

test_that("'.es_map()' works",
{
    metadata <- list(organism = "Homo sapiens")
    es <- BiocSet(
        set1 = c("BRCA1", "BRCA2", "TGFA", "ERCC2"),
        set2 = c("PRNP", "FMR1", "PAX3"),
        metadata = metadata
    )
    es1 <- es %>% .es_map(org.Hs.eg.db, "SYMBOL", "ENTREZID")

    expect_s4_class(es1, "BiocSet")
    expect_identical(dim(es_element(es1)), c(7L, 1L))
    expect_identical(dim(es_set(es1)), c(2L, 1L))
    expect_identical(dim(es_elementset(es1)), c(7L, 2L))
    expect_true(.is_tbl_elementset(es_elementset(es1)))
    expect_identical(metadata(es1), metadata)

    expect_true(all(es_element(es1)$element %in%
        keys(org.Hs.eg.db, keytype="ENTREZID")))

    expect_error(.es_map(es, org.Hs.eg.db))
    expect_error(.es_map(es, org.Hs.eg.db, "SYMBOL"))
    expect_error(.es_map(es, org.Hs.eg.db, SYMBOL, "ENTREZID"))
    expect_error(.es_map(es, org.Hs.eg.db, "SYMBOL", 10))
    expect_error(.es_map(es, org.Hs.eg.db, "SYMBOL", "IDS"))
    expect_error(.es_map(es, species, "SYMBOL", "ENTREZID"))
})

test_that("'.normalize_mapping()' works", {
    es <- .normalize_mapping(letters, LETTERS)
    expect_s3_class(es, "tbl_df")
    expect_false(.is_tbl_elementset(es))
    expect_identical(dim(es), c(26L, 2L))
    expect_true(is.character(es$element))
    expect_true(is.character(es$to))

    es1 <- .normalize_mapping(
        list(letters[1], letters[2:3], character()),
        LETTERS[1:3]
    )
    expect_s3_class(es1, "tbl_df")
    expect_false(.is_tbl_elementset(es1))
    expect_identical(dim(es1), c(3L, 2L))
    expect_true(is.character(es$element))
    expect_true(is.character(es$to))

    es2 <- .normalize_mapping(
        letters[1:3],
        list(LETTERS[1], LETTERS[2:3], character())
    )
    expect_s3_class(es2, "tbl_df")
    expect_false(.is_tbl_elementset(es2))
    expect_identical(dim(es2), c(3L, 2L))
    expect_true(is.character(es$element))
    expect_true(is.character(es$to))

    es3 <- .normalize_mapping(
        list(letters[1:2], letters[3], character()),
        list(LETTERS[1], LETTERS[2:3], character())
    )
    expect_s3_class(es3, "tbl_df")
    expect_false(.is_tbl_elementset(es3))
    expect_identical(dim(es3), c(4L, 2L))
    expect_true(is.character(es$element))
    expect_true(is.character(es$to))
})

test_that("'map_element.BiocSet()' works", {
    metadata <- list(organism = "Homo sapiens")
    es <- BiocSet(set1 = letters, set2 = LETTERS, metadata = metadata)

    # 1:1 mapping
    es1 <- es %>% map_element(letters, LETTERS)
    expect_true(.is_tbl_elementset(es_elementset(es1)))
    expect_identical(dim(es_element(es1)), c(26L, 1L))
    expect_identical(dim(es_set(es1)), c(2L, 1L))
    expect_identical(dim(es_elementset(es1)), c(52L,2L))
    expect_identical(metadata(es1), metadata)

    # A single set example with metadata in each tibble
    element <- tibble(element = letters[1:5], foo = 1:5)
    set <- tibble(set = "set1", bar = 1)
    elementset <- tibble(
        element = letters[1:5], set = rep("set1", 5), baz = 1:5
    )
    .data = BiocSet_from_elementset(elementset, element, set, metadata(es))

    from = c("a", "b", "b", "c", "d")
    to = c("A", "B", "C", "D", "D")
    # 1:1 mapping, 1:many mapping, many:1 mapping
    es2 <- map_element(.data, from, to)
    expect_s4_class(es2, "BiocSet")
    expect_identical(dim(es_element(es2)), c(5L, 2L))
    expect_identical(dim(es_set(es2)), c(1L, 2L))
    expect_identical(dim(es_elementset(es2)), c(5L, 3L))
    expect_true(.is_tbl_elementset(es_elementset(es2)))
    expect_true(is.list(es_element(es2)$foo))
    expect_true(is.double(es_set(es2)$bar))
    expect_true(is.list(es_elementset(es2)$baz))
    expect_identical(metadata(es2), metadata)

    # 1:1 mapping, 1:many mapping, many:1 mapping, dropping unmapped element(s)
    es3 <- map_element(.data, from, to, keep_unmapped = FALSE)
    expect_s4_class(es3, "BiocSet")
    expect_identical(dim(es_element(es3)), c(4L, 2L))
    expect_identical(dim(es_set(es3)), c(1L, 2L))
    expect_identical(dim(es_elementset(es3)), c(4L, 3L))
    expect_true(.is_tbl_elementset(es_elementset(es3)))
    expect_true(is.list(es_element(es3)$foo))
    expect_true(is.double(es_set(es3)$bar))
    expect_true(is.list(es_elementset(es3)$baz))
    expect_identical(metadata(es3), metadata)

    # multiple sets with metadata in element and elementset tibble
    elementset <- tibble(
        element = c("a", "b", "c"),
        set = c("set1", "set1", "set2")
    )
    .data = BiocSet_from_elementset(elementset, metadata = metadata(es)) %>%
        mutate_element(foo = 1:3) %>%
        mutate_elementset(bar = 1:3)

    # 1:1 mapping, but in different sets
    from <- c("b", "c")
    to <- c("D", "E")
    es4 <- map_element(.data, from, to)
    expect_s4_class(es4, "BiocSet")
    expect_identical(dim(es_element(es4)), c(3L, 2L))
    expect_identical(dim(es_set(es4)), c(2L, 1L))
    expect_identical(dim(es_elementset(es4)), c(3L, 3L))
    expect_true(.is_tbl_elementset(es_elementset(es4)))
    expect_true(is.integer(es_element(es4)$foo))
    expect_true(is.integer(es_elementset(es4)$bar))
    expect_identical(metadata(es4), metadata)

    # 1:1 mappping, in different sets, dropping unmapped element(s)
    es5 <- map_element(.data, from, to, keep_unmapped = FALSE)
    expect_s4_class(es5, "BiocSet")
    expect_identical(dim(es_element(es5)), c(2L, 2L))
    expect_identical(dim(es_set(es5)), c(2L, 1L))
    expect_identical(dim(es_elementset(es5)), c(2L, 3L))
    expect_true(.is_tbl_elementset(es_elementset(es5)))
    expect_true(is.integer(es_element(es5)$foo))
    expect_true(is.integer(es_elementset(es5)$bar))
    expect_identical(to, es_element(es5)$element)
    expect_identical(to, es_elementset(es5)$element)
    expect_identical(metadata(es5), metadata)

    # many:1 mapping, in different sets
    from <- c("b", "c")
    to <- c("D", "D")
    es6 <- map_element(.data, from, to)
    expect_s4_class(es6, "BiocSet")
    expect_identical(dim(es_element(es6)), c(2L, 2L))
    expect_identical(dim(es_set(es6)), c(2L, 1L))
    expect_identical(dim(es_elementset(es6)), c(3L, 3L))
    expect_true(.is_tbl_elementset(es_elementset(es6)))
    expect_true(is.list(es_element(es6)$foo))
    expect_true(is.integer(es_elementset(es6)$bar))
    expect_identical(metadata(es6), metadata)

    # many:1 mapping, in different sets, dropping unmapped element(s)
    es7 <- map_element(.data, from, to, keep_unmapped = FALSE)
    expect_s4_class(es7, "BiocSet")
    expect_identical(dim(es_element(es7)), c(1L, 2L))
    expect_identical(dim(es_set(es7)), c(2L, 1L))
    expect_identical(dim(es_elementset(es7)), c(2L, 3L))
    expect_true(.is_tbl_elementset(es_elementset(es7)))
    expect_true(is.list(es_element(es7)$foo))
    expect_true(is.integer(es_elementset(es7)$bar))
    expect_identical(to, es_elementset(es7)$element)
    expect_identical(metadata(es7), metadata)

    # 1:many mapping, in different sets
    from <- c("b", "b", "c", "c")
    to <- c("D", "E", "F", "G")
    es8 <- map_element(.data, from, to)
    expect_s4_class(es8, "BiocSet")
    expect_identical(dim(es_element(es8)), c(5L, 2L))
    expect_identical(dim(es_set(es8)), c(2L, 1L))
    expect_identical(dim(es_elementset(es8)), c(5L, 3L))
    expect_true(.is_tbl_elementset(es_elementset(es8)))
    expect_true(is.integer(es_element(es8)$foo))
    expect_true(is.integer(es_elementset(es8)$bar))
    expect_identical(metadata(es8), metadata)

    # 1:many mapping, in different sets, dropping unmapped element(s)
    es9 <- map_element(.data, from, to, keep_unmapped = FALSE)
    expect_s4_class(es9, "BiocSet")
    expect_identical(dim(es_element(es9)), c(4L, 2L))
    expect_identical(dim(es_set(es9)), c(2L, 1L))
    expect_identical(dim(es_elementset(es9)), c(4L, 3L))
    expect_true(.is_tbl_elementset(es_elementset(es9)))
    expect_true(is.integer(es_element(es9)$foo))
    expect_true(is.integer(es_elementset(es9)$bar))
    expect_identical(to, es_element(es9)$element)
    expect_identical(to, es_elementset(es9)$element)
    expect_identical(metadata(es9), metadata)

    expect_error(es %>% map_element())
})

test_that("'map_unique()' works",
{
    metadata <- list(organism = "Homo sapiens")
    es <- BiocSet(
        set1 = c("PRKACA", "TGFA", "MAP2K1"),
        set2 = c("CREB3", "FOS"),
        metadata = metadata
    )

    es1 <- es %>% map_unique(org.Hs.eg.db, "SYMBOL", "ENSEMBL")

    expect_s4_class(es1, "BiocSet")
    expect_identical(dim(es_element(es1)), c(5L, 1L))
    expect_identical(dim(es_set(es1)), c(2L, 1L))
    expect_identical(dim(es_elementset(es1)), c(5L, 2L))
    expect_true(.is_tbl_elementset(es_elementset(es1)))
    expect_identical(metadata(es1), metadata)

    expect_error(map_unique(es, org.Hs.eg.db, "SYMBOL", "ENTREZID", "first"))
})

test_that("'map_multiple()' works",
{
    metadata <- list(organism = "Homo sapiens")
    es <- BiocSet(
        set1 = c("CFB", "DDR1"),
        set2 = c("CLIC1", "DEFB4A", "A2M"),
        metadata = metadata
    )

    es1 <- es %>% map_multiple(org.Hs.eg.db, "SYMBOL", "ENSEMBL", "list")

    expect_s4_class(es1, "BiocSet")
    expect_identical(dim(es_element(es1)), c(27L, 1L))
    expect_identical(dim(es_set(es1)), c(2L, 1L))
    expect_identical(dim(es_elementset(es1)), c(27L, 2L))
    expect_true(.is_tbl_elementset(es_elementset(es1)))
    expect_true(is.character(es_element(es1)$element))
    expect_true(is.character(es_elementset(es1)$element))
    expect_identical(metadata(es1), metadata)

    es2 <- es %>% map_multiple(org.Hs.eg.db, "SYMBOL", "ENSEMBL", "filter")

    expect_s4_class(es2, "BiocSet")
    expect_identical(dim(es_element(es2)), c(5L, 1L))
    expect_identical(dim(es_set(es2)), c(2L, 1L))
    expect_identical(dim(es_elementset(es2)), c(5L, 2L))
    expect_true(.is_tbl_elementset(es_elementset(es2)))
    expect_identical(metadata(es2), metadata)

    es3 <- es %>% map_multiple(org.Hs.eg.db, "SYMBOL", "ENSEMBL", "asNA")

    expect_s4_class(es3, "BiocSet")
    expect_identical(dim(es_element(es3)), c(2L, 1L))
    expect_identical(dim(es_set(es3)), c(2L, 1L))
    expect_identical(dim(es_elementset(es3)), c(3L, 2L))
    expect_true(.is_tbl_elementset(es_elementset(es3)))
    expect_false(all(is.na(es_element(es3)$element)))
    expect_false(all(is.na(es_elementset(es3)$element)))
    expect_identical(metadata(es3), metadata)

    es4 <- map_multiple(es, org.Hs.eg.db, "SYMBOL", "ENSEMBL", "CharacterList")

    expect_s4_class(es4, "BiocSet")
    expect_identical(dim(es_element(es4)), c(27L, 1L))
    expect_identical(dim(es_set(es4)), c(2L, 1L))
    expect_identical(dim(es_elementset(es4)), c(27L, 2L))
    expect_true(.is_tbl_elementset(es_elementset(es4)))
    expect_true(is.character(es_element(es4)$element))
    expect_true(is.character(es_elementset(es4)$element))
    expect_identical(metadata(es4), metadata)

    expect_error(map_multiple(es, org.Hs.eg.db, "SYMBOL", "ENSEMBL", "first"))
    expect_error(map_multiple(es, org.Hs.eg.db, "ENSEMBL", "SYMBOL", "list"))
    expect_error(map_multiple(es, org.Hs.eg.db, "SYMBOL", "ENSEMBL", filter()))
    expect_error(map_multiple(es, org.Hs.eg.db))
})

test_that("'map_add_element()' works",
{
    es <- BiocSet(set1 = c("PRKACA", "TGFA", "MAP2K1"), set2 = c("FOS", "BRCA1"))
    map <- map_add_element(es, org.Hs.eg.db, "SYMBOL", "ENTREZID")

    expect_identical(length(map), 5L)
    expect_identical(class(map), "character")
    expect_identical(map, c("5566", "7039", "5604", "2353", "672"))

    expect_error(map_add_element(org.Hs.eg.db, "SYMBOL", "ENTREZID"))
})
