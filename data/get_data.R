
library(OpenML)

####  functions

# fill NAs
fill.na <- function(d){
  colsc <- colnames(d)[grepl('cat', colnames(d), fixed = TRUE)]   # names of categorical columns
  colsn <- colnames(d)[grepl('num', colnames(d), fixed = TRUE)]   # names of numeric columns
  
  for(i in colsc){
    d[, i] <- addNA(d[, i])
  }
  
  for(i in colsn){
    d[is.na(d[, i]), i] <- mean(d[, i], na.rm = TRUE)
  }
  
  return(d)
}

# unify column names
rename.cols <- function(d, tar, pos){
  
  colnames(d)[which(colnames(d) == tar)] <- 'target'
  d$target <- ifelse(d$target == pos, 1, 0)
  
  colsc <- setdiff(names(Filter(is.factor, d)), 'target')
  colsn <- setdiff(names(Filter(is.numeric, d)), 'target')
  colsd <- setdiff(colnames(d), c('target', colsc, colsn))
  
  if(length(colsd) > 0){
    d <- d[, - which(names(d) %in% colsd)]
  }
  colnames(d)[colnames(d) %in% colsc] <- paste0('cat_', 1:length(colsc))
  colnames(d)[colnames(d) %in% colsn] <- paste0('num_', 1:length(colsn))
  
  return(d)
}


#### get datasets

get.data <- function(dname){
  
  fname <- file.path(dirname(getwd()), 'data', paste0(dname, ".csv"))
  
  if(file.exists(fname)){
    d <- read.csv(fname)
  } else {
    if(dname == 'kick'){
      d <- getOMLDataSet(41162)[['data']]
      tar <- 'IsBadBuy'
      pos <- '1'
    } else if(dname == 'upselling'){
      d <- getOMLDataSet(1114)[['data']]
      tar <- 'UPSELLING'
      pos <- '1'
    } else if(dname == 'internet'){
      d <- getOMLDataSet(43920)[['data']]
      tar <- 'who_pays_for_access_work'
      pos <- '1'
    } else if(dname == 'churn'){
      d <- getOMLDataSet(1112)[['data']]
      tar <- 'CHURN'
      pos <- '1'
    } else if(dname == 'appetency'){
      d <- getOMLDataSet(1111)[['data']]
      tar <- 'APPETENCY'
      pos <- '1'
    } else if(dname == 'epsilon'){
      d <- getOMLDataSet(42343)[['data']]
      tar <- 'TARGET_B'
      pos <- '1'
    } else if(dname == 'click'){# Original data is too large
      # Switching to a sample. Using version 10 since it indicates nominal features
      d <- getOMLDataSet(42733)[['data']]
      tar <- 'click'
      pos <- '1'
    } else if(dname == 'amazon'){
      d <- getOMLDataSet(43900)[['data']]
      tar <- 'ACTION'
      pos <- '1'
    } else if(dname == 'adult'){
      d <- getOMLDataSet(1590)[['data']]
      tar <- 'class'
      pos <- '>50K'
    } else {
      stop('incorrect dataset name')
    }
    d <- rename.cols(d, tar, pos)
    write.csv(d, fname, row.names = FALSE)
  }
  
  d <- fill.na(d)
  d
}


