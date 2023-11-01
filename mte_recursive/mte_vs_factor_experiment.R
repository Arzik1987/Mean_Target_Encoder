library(rpart)
source('../data/get_data.R')
source('../utils/encode_mte.R')

####

test_mte_factor <- function(dname, controls){
  
  accuracyf <- numeric()
  accuracymte <- numeric()

  set.seed(42)
  print(dname)

  d <- get.data(dname)
  d <- fill.na(d) 
  trind <- sample.int(nrow(d), floor(nrow(d)*0.7))
  d <- list(d[trind,], d[-trind,])
  dmte = encode_te(d[[1]], d[[2]])
      
  for(j in 1:length(controls)){
    model = rpart(target ~ ., data = d[[1]], method = "class", control = controls[[j]])
    pred <- predict(model, d[[2]], type = 'vector')
    acuracyf <- c(accuracyf, mean(d[[2]]$target == (pred - 1)))
    
    model = rpart(target ~ ., data = dmte[[1]], method = "class", control = controls[[j]])
    pred <- predict(model, dmte[[2]], type = 'vector')
    acuracymte <- c(accuracymte, mean(dmte[[2]]$target == (pred - 1)))
  }

  return(list(accuracyf, accuracymte))
}


dnames <- c('kick', 'upselling', 'internet', 'churn', 'appetency', 
            'epsilon', 'click', 'amazon', 'adult')

controls <- list(list(cp = 0, maxdepth = 2),
                 list(cp = 0, maxdepth = 4), list(cp = 0, maxdepth = 6))

for(i in 1:length(npts)){
  res <- experiment(npts[i], controls)
  write(knitr::kable(res), paste0(npts[i],'.txt'))
}

