library(modelr)
library(purrr)
library(dplyr)
library(rpart)
source('../data/get_data.R')


#### helpers

# get predictions for cv

get_pred2  <- function(model, test_data){
  data  <- as.data.frame(test_data)
  pred  <- add_predictions(data, model, type = 'vector')
  return(pred)
}

# reduce the number of factor levels for sub samples
# this should not affect the result, but hopefully makes calculations faster
dsimplify <- function(d){
  cols <- colnames(d)[grepl('cat', colnames(d), fixed = TRUE)]
  for(i in cols){
    d[,i] <- as.factor(as.character(d[,i]))
    d[,i] <- addNA(d[,i])
  }
  d
}

# split factor levels into buckets of size >= thr
combine <- function(d, thr){
  
  d$csum <- cumsum(d$value)
  inds = nrow(d)
  
  if(inds == 1 | d[inds, 'csum'] < 2*thr){
    return(list(d$keyName))
  }
  
  maxsum <- d[inds,'csum']
  cursum  <- d[inds,'value']
  i = inds - 1
  
  while((cursum + 10^-10) < thr){
    if(i == 1){
      inds = c(inds, i)
      cursum <- cursum + d[i,'value']
    } else if((cursum + d[i,'value'] + 10^-10) < thr | (cursum + d[i-1,'csum'] + 10^-10) < thr){
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

# returns encoding dictionary for a given categorical feature
encode.single.f <- function(d, thr){
  tmp <- summary(d[,1], maxsum = nlevels(d[,1]))
  tmp <- data.frame(keyName = names(tmp), value = tmp, row.names = NULL)
  tmp <- tmp[order(tmp$value),]
  tmp$value <- 100*tmp$value/sum(tmp$value)

  buckets <- combine(tmp, thr)
  levels <- paste0('c', 1:length(buckets))
  dic <- do.call(rbind, Map(data.frame, A = buckets, B = levels))
  return(dic)
}

# encoding that combines poorly represented categories into one
encode_combine <- function(dtr, dte, thr = 5, nmin = 0){
  
  if(nmin > 0){
    thr <- nmin*100/nrow(dtr)
  }
                                                   
  colnames(dtr) <- gsub(".*\\.","",colnames(dtr))
  colnames(dte) <- gsub(".*\\.","",colnames(dte))
                                                    
  cols <- colnames(dtr)[grepl('cat', colnames(dtr), fixed = TRUE)]
  target = colnames(dtr)[grepl('target', colnames(dtr), fixed = TRUE)]
  
  for(i in cols){
    dic <- encode.single.f(dtr[, c(i, 'target')], thr)
    dtr[,i] <- plyr::mapvalues(dtr[,i], from = dic$A, to = dic$B)               # do not load plyr explicitly!
    dte[,i] <- plyr::mapvalues(dte[,i], from = dic$A, to = dic$B)
  }

  return(list(dtr, dte))
}


#### the main experiment

# experiment <- function(dsize = -1, controls, thresholds){
#   
#   dnames <- c('kick', 'upselling', 'internet', 'churn', 'appetency', 
#               'epsilon', 'click', 'amazon', 'adult')
#   
#   accuracy <- list()
#   for(j in 1:length(controls)){
#     accuracy[[j]] <- tibble()
#   }
#   
#   for(dname in dnames){
#     
#     print(dname)
#     set.seed(dsize)
#     if(dsize <= 0){
#       cv <- crossv_kfold(get.data(dname), k = 5)
#     } else {
#       cv <- crossv_kfold(dsimplify(sample_n(get.data(dname), dsize)), k = 5)
#     }
#     
#     tmpacc <- list()
#     for(j in 1:length(controls)){
#       models <- map(cv$train, ~rpart(target ~ ., data = ., method = "class", control = controls[[j]]))
#       
#       pred  <- map2_df(models, cv$test, get_pred2, .id = "Run")
#       tmpacc[[j]] <- pred %>% group_by(Run) %>% summarise(fe = mean(target == (pred - 1)))
#       tmpacc[[j]]$dname = dname
#     }
#     
#     for(i in 1:nrow(cv)){
#       print(i)
#       
#       for(k in thresholds){
#         tmp = encode_combine(as.data.frame(cv$train[i]), as.data.frame(cv$test[i]), thr = k)
#         
#         for(j in 1:length(controls)){
#           model = rpart(target ~ ., data = tmp[[1]], method = "class", control = controls[[j]])
#           
#           predte <- predict(model, tmp[[2]], type = 'vector')
#           tmpacc[[j]][i, paste0('ec', k)] = mean(tmp[[2]]$target == (predte - 1))
#         }
#       }
#     }
#     
#     for(j in 1:length(controls)){
#       accuracy[[j]] <- rbind(accuracy[[j]], tmpacc[[j]])
#     }
#   }
#   
#   res <- list()
#   i <- 1
#   for(k in thresholds){
#     res[[i]] <- accuracy %>% map(function(x) sign(x$fe-x[,paste0('ec', k)])) %>% rbind.data.frame()
#     colnames(res[[i]]) <- controls %>% map(function(x) paste0('depth = ',x[[2]]))
#     res[[i]] <- cbind(apply(res[[i]], 2, function(x) sum(x == 1)),
#                       apply(res[[i]], 2, function(x) sum(x == 0)),
#                       apply(res[[i]], 2, function(x) sum(x == -1)))
#     colnames(res[[i]]) <- c('w', 'd', 'l')
#     i = i + 1
#   }
#   
#   res
# }
# 
# 
# controls <- list(list(cp = 0, maxdepth = 2),
#                  list(cp = 0, maxdepth = 4), list(cp = 0, maxdepth = 6))
# npts <- c(1000, 2000, 5000, 0)
# thresholds <- c(1,2,5,10)
# 
# for(i in 1:length(npts)){
#   res <- experiment(npts[i], controls, thresholds)
#   for(k in 1:length(thresholds)){
#     write(knitr::kable(res[k]), paste0(npts[i], '_', thresholds[k], '.txt'))
#   }
# }


#### with restriction on minimum number of points

experiment2 <- function(dsize = -1, controls, nmins){
  
  dnames <- c('kick', 'upselling', 'internet', 'churn', 'appetency', 
              'epsilon', 'click', 'amazon', 'adult')
  
  accuracy <- list()
  for(j in 1:length(controls)){
    accuracy[[j]] <- tibble()
  }
  
  for(dname in dnames){
    
    print(dname)
    set.seed(dsize)
    if(dsize <= 0){
      cv <- crossv_kfold(get.data(dname), k = 5)
    } else {
      cv <- crossv_kfold(dsimplify(sample_n(get.data(dname), dsize)), k = 5)
    }
    
    tmpacc <- list()
    for(j in 1:length(controls)){
      models <- map(cv$train, ~rpart(target ~ ., data = ., method = "class", control = controls[[j]]))
      
      pred  <- map2_df(models, cv$test, get_pred2, .id = "Run")
      tmpacc[[j]] <- pred %>% group_by(Run) %>% summarise(fe = mean(target == (pred - 1)))
      tmpacc[[j]]$dname = dname
    }
    
    for(i in 1:nrow(cv)){
      print(i)
      
      for(k in nmins){
        tmp = encode_combine(as.data.frame(cv$train[i]), as.data.frame(cv$test[i]), nmin = k)
        
        for(j in 1:length(controls)){
          model = rpart(target ~ ., data = tmp[[1]], method = "class", control = controls[[j]])
          
          predte <- predict(model, tmp[[2]], type = 'vector')
          tmpacc[[j]][i, paste0('ec', k)] = mean(tmp[[2]]$target == (predte - 1))
        }
      }
    }
    
    for(j in 1:length(controls)){
      accuracy[[j]] <- rbind(accuracy[[j]], tmpacc[[j]])
    }
  }
  
  res <- list()
  i <- 1
  for(k in nmins){
    res[[i]] <- accuracy %>% map(function(x) sign(x$fe-x[,paste0('ec', k)])) %>% rbind.data.frame()
    colnames(res[[i]]) <- controls %>% map(function(x) paste0('depth = ',x[[2]]))
    res[[i]] <- cbind(apply(res[[i]], 2, function(x) sum(x == 1)),
                      apply(res[[i]], 2, function(x) sum(x == 0)),
                      apply(res[[i]], 2, function(x) sum(x == -1)))
    colnames(res[[i]]) <- c('w', 'd', 'l')
    i = i + 1
  }
  
  res
}


controls <- list(list(cp = 0, maxdepth = 2),
                 list(cp = 0, maxdepth = 4), list(cp = 0, maxdepth = 6))
npts <- c(0)
nmins <- c(50, 100, 200)

for(i in 1:length(npts)){
  res <- experiment2(npts[i], controls, nmins)
  for(k in 1:length(nmins)){
    write(knitr::kable(res[k]), paste0(npts[i], '_', nmins[k], '.txt'))
  }
}



# encode.single.te <- function(d, thr){
#   tmp <- summary(d[,1])
#   tmp <- data.frame(keyName = names(tmp), value = tmp, row.names = NULL)
#   tmp <- tmp[order(tmp$value),]
#   tmp$value <- 100*tmp$value/sum(tmp$value)
#   
#   buckets <- combine(tmp, thr)
#   
#   cat.means <- function(cat, df){
#     mean(df$target[df[,1] %in% cat])
#   }
#   
#   levels <- lapply(buckets, cat.means, df = d)
#   return(do.call(rbind, Map(data.frame, A = buckets, B = levels)))
# }

