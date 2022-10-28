library(modelr)
library(purrr)
library(dplyr)
library(rpart)
source('../data/get_data.R')


####

get_pred  <- function(model, test_data){
  data  <- as.data.frame(test_data)
  pred  <- add_predictions(data, model)
  return(pred)
}

get_pred2  <- function(model, test_data){
  data  <- as.data.frame(test_data)
  pred  <- add_predictions(data, model, type = 'vector')
  return(pred)
}

encode_te <- function(dtr, dte){
  require(dataPreparation)                                                      # contains TE implementation
  colnames(dtr) <- gsub(".*\\.","",colnames(dtr))
  colnames(dte) <- gsub(".*\\.","",colnames(dte))
  
  colsorig <- colnames(dtr)                                                     # save names of columns
  cols <- colnames(dtr)[grepl('cat', colnames(dtr), fixed = TRUE)]              # names of categorical columns
  target = colnames(dtr)[grepl('target', colnames(dtr), fixed = TRUE)]
  
  te <- build_target_encoding(dtr, cols_to_encode = cols,
                              target_col = target, functions = c("mean"))       # Construct encoding
  
  dtr <- data.frame(target_encode(dtr, target_encoding = te))                   # apply encoding train
  dte <- data.frame(target_encode(dte, target_encoding = te))                   # apply encoding test
  
  dte <- dte[, !(names(dte) %in% cols)]                                         # drop original categorical columns, retain encoded 
  colnames(dte) <- gsub("target_mean_by_", "", colnames(dte))                   # rename columns as it was originally
  dte <- dte[, colsorig]                                                        # make sure there is no extra columns
  
  dtr <- dtr[, !(names(dtr) %in% cols)]                                         # drop original categorical columns, retain encoded 
  colnames(dtr) <- gsub("target_mean_by_", "", colnames(dtr))                   # rename columns as it was originally
  dtr <- dtr[, colsorig]                                                        # make sure there is no extra columns
  return(list(dtr, dte))
}


####

experiment <- function(dsize = -1, controls){
  
  accuracy <- list()
  for(j in 1:length(controls)){
    accuracy[[j]] <- tibble()
  }
  dnames <- c('kick', 'upselling', 'internet', 'churn', 'appetency', 
              'epsilon', 'click', 'amazon', 'adult')
  
  for(dname in dnames){
    
    print(dname)
    set.seed(dsize)
    if(dsize <= 0){
      cv <- crossv_kfold(get.data(dname), k = 5)
    } else {
      cv <- crossv_kfold(sample_n(get.data(dname), dsize), k = 5)
    }
    
    tmpacc <- list()
    for(j in 1:length(controls)){
      models <- map(cv$train, ~rpart(target ~ ., data = ., method = "class", control = controls[[j]]))
      
      pred  <- map2_df(models, cv$test, get_pred2, .id = "Run")
      tmpacc[[j]] <- pred %>% group_by(Run) %>% summarise(fe = mean(target == (pred - 1)))
      tmpacc[[j]]$dname = dname
      tmpacc[[j]]$te = NA
    }
    
    for(i in 1:nrow(cv)){
      print(i)
      tmp = encode_te(as.data.frame(cv$train[i]), as.data.frame(cv$test[i]))
      
      for(j in 1:length(controls)){
        model = rpart(target ~ ., data = tmp[[1]], method = "class", control = controls[[j]])
        
        predte <- predict(model, tmp[[2]], type = 'vector')
        tmpacc[[j]]$te[i] = mean(tmp[[2]]$target == (predte - 1))
      }
    }
    
    for(j in 1:length(controls)){
      accuracy[[j]] <- rbind(accuracy[[j]], tmpacc[[j]])
    }
  }
  accuracy <- accuracy %>% map(function(x) sign(x$fe-x$te)) %>% rbind.data.frame()
  colnames(accuracy) <- controls %>% map(function(x) paste0('depth = ',x[[2]]))
  accuracy <- cbind(apply(accuracy, 2, function(x) sum(x == 1)),
                    apply(accuracy, 2, function(x) sum(x == 0)),
                    apply(accuracy, 2, function(x) sum(x == -1)))
  colnames(accuracy) <- c('w', 'd', 'l')
  accuracy
}


controls <- list(list(cp = 0, maxdepth = 2),
                 list(cp = 0, maxdepth = 4), list(cp = 0, maxdepth = 6))
npts <- c(1000, 2000, 5000, 0)

for(i in 1:length(npts)){
  res <- experiment(npts[i], controls)
  write(knitr::kable(res), paste0(npts[i],'.txt'))
}

