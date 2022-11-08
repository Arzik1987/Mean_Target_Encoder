fill.na <- function(d){                                                         # fill NA values
  
  colsc <- colnames(d)[grepl('cat', colnames(d), fixed = TRUE)]                 # names of categorical columns
  colsn <- colnames(d)[grepl('num', colnames(d), fixed = TRUE)]                 # names of numeric columns
  
  for(i in colsc){
    d[,i] <- as.factor(as.character(d[,i]))
    d[,i] <- addNA(d[, i])
  }
  
  for(i in colsn){
    d[is.na(d[,i]), i] <- mean(d[,i], na.rm = TRUE)
  }
  
  return(d)
}


rename.cols <- function(d, tar, pos){                                           # name columns with 'target', 'cat_X', and 'num_X'
  
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


get.data <- function(dname){                                                    # (down)load datasets
  
  require(OpenML)
  fname <- file.path(dirname(getwd()), 'utils', paste0(dname, ".csv"))
  dnames <- c('kick','upselling', 'internet', 'churn', 'appetency',
              'epsilon', 'click', 'amazon', 'adult')
  ids <- c(41162, 1114, 43920, 1112, 1111, 42343, 42733, 43900, 1590)
  poss <- c(rep('1',8), '>50K')
  
  if(file.exists(fname)){
    d <- read.csv(fname)
  } else {
    ind <- which(dnames == dname)
    d <- getOMLDataSet(ids[ind])
  } else {
      stop('incorrect dataset name')
  }
  
  d <- rename.cols(d$data, tar = d$target.features[1], pos = poss[ind])
  write.csv(d, fname, row.names = FALSE)
  d
}