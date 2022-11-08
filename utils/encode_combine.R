# library(modelr)
# library(purrr)
# library(dplyr)
library(rpart)
source('../data/get_data.R')



combine <- function(d, thr){                                                    # split factor levels into buckets of size >= thr
  
  d$csum <- cumsum(d$value)
  inds = nrow(d)
  
  if(inds == 1 | d[inds, 'csum'] < 2*thr){
    return(list(d$keyName))
  }
  
  maxsum <- d[inds,'csum']
  cursum  <- d[inds,'value']
  i = inds - 1
  
  while((cursum + 10^-10) < thr){                                               # use small number to avoid bugs caused by limited precision
    if(i == 1){
      inds = c(inds, i)
      cursum <- cursum + d[i,'value']
    } else if((cursum + d[i,'value'] + 10^-10) < thr |
              (cursum + d[i-1,'csum'] + 10^-10) < thr){
      inds = c(inds, i)
      cursum <- cursum + d[i,'value']
    }
    i = i - 1
  }
  
  if(maxsum - cursum < thr){
    return(list(d$keyName))
  }
  
  return(append(list(d[inds, 'keyName']), combine(d[-inds,], thr)))
}



encode.single.f <- function(d, thr){                                            # returns encoding dictionary for a given categorical feature
  tmp <- summary(d[,1], maxsum = nlevels(d[,1]))
  tmp <- data.frame(keyName = names(tmp), value = tmp, row.names = NULL)
  tmp <- tmp[order(tmp$value),]
  tmp$value <- 100*tmp$value/sum(tmp$value)

  buckets <- combine(tmp, thr)
  levels <- paste0('c', 1:length(buckets))
  dic <- do.call(rbind, Map(data.frame, A = buckets, B = levels))
  return(dic)
}



encode.combine <- function(dtr, dte, thr = 5, nmin = 0){                        # encoding that combines poorly represented categories into one
  
  if(nmin > 0){
    thr <- nmin*100/nrow(dtr)
  }
                                                   
  colnames(dtr) <- gsub(".*\\.","",colnames(dtr))
  colnames(dte) <- gsub(".*\\.","",colnames(dte))
                                                    
  cols <- colnames(dtr)[grepl('cat', colnames(dtr), fixed = TRUE)]
  target = colnames(dtr)[grepl('target', colnames(dtr), fixed = TRUE)]
  
  for(i in cols){
    dic <- encode.single.f(dtr[, c(i, 'target')], thr)
    dtr[,i] <- plyr::mapvalues(dtr[,i], from = dic$A, to = dic$B)               # better do not load plyr explicitly as it may conflict with other packages
    dte[,i] <- plyr::mapvalues(dte[,i], from = dic$A, to = dic$B)
  }

  return(list(dtr, dte))
}


