library(rpart)         # for learning DT
library(OpenML)


#### MTE encoder

# Mean Tearget Encoder (as a preprocessing step)
# d --- dataset to learn and apply TE
# cols --- a vector of names of columns to encode

encode_te <- function(d, cols){
  require(dataPreparation)  # contains TE implementation
  colsorig <- colnames(d)   # save names of columns
  
  # Construct encoding
  te <- build_target_encoding(d, cols_to_encode = cols,
                      target_col = "target", functions = c("mean"))
  
  d <- data.frame(target_encode(d, target_encoding = te))   # apply encoding
  d <- d[, !(names(d) %in% cols)]   # drop original categorical columns, retain encoded 
  colsnew <- colnames(d)
  
  colnames(d) <- gsub("target_mean_by_", "", colsnew)   # rename columns as it was originall
  d <- d[, colsorig]   # make sure there is no extra columns
  return(d)
}

#### fill NAs

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


#### kick dataset

d <- getOMLDataSet(41162)[['data']]
colnames(d)[which(colnames(d) == 'IsBadBuy')] <- 'target'
d$target <- ifelse(d$target == "0", 0, 1)

catcols <- c("PurchDate", "Auction", "Make", "Model", "Trim", "SubModel", "Color", "Transmission", 
             "WheelTypeID", "WheelType", "Nationality", "Size", "TopThreeAmericanName", 
             "PRIMEUNIT", "AUCGUART", "BYRNO", "VNZIP1", "VNST", "IsOnlineSale")

colnames(d)[!colnames(d) %in% c(catcols, 'target')] <- paste0('num_', 1:(ncol(d) - length(catcols) - 1))
colnames(d)[colnames(d) %in% catcols] <- paste0('cat_', 1:length(catcols))

d <- fill.na(d)
cols <- colnames(d)[grepl('cat', colnames(d), fixed = TRUE)]   # names of categorical columns


#### Experiment

d_te <- encode_te(d, cols) # MTE as preprocessing
dt_te <- rpart(target ~ ., d_te, method = "class")   # MTE as preprocessing

dt_f <- rpart(target ~ ., d, method = "class")     # recursive MTE


# plot models
jpeg(height = 350, width = 350, "dt_te.jpg")
plot(dt_te)
dev.off()

jpeg(height = 350, width = 350, "dt_f.jpg")
plot(dt_f)
dev.off()

print(dt_te)
print(dt_f)



# d_tef <- encode_factor(data.frame(d_te), cols) # converting to 'factor' type via MTE (lossy)
# dt_tef <- rpart(target ~ ., d_tef, method = "class") # lossy recursive MTE
# rpart.plot(dt_tef)

# jpeg(height = 350, width = 350, "dt_tef.jpg")
# plot(dt_tef)
# dev.off()

# print(dt_tef)

