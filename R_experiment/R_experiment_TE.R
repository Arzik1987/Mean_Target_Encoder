library(rpart)         # for learning DT
library(rpart.plot)    # for plotting DT

#### Encoders

# Mean Tearget Encoder (as a preprocessing step)
# d - dataset to learn and apply TE
# cols - a vector of names of columns to encode
encode_te <- function(d, cols){
  require(dataPreparation)  # contains TE implementation
  colsorig <- colnames(d)   # save names of columns
  
  # Construct encoding
  te <- build_target_encoding(d, cols_to_encode = cols,
                      target_col = "target", functions = c("mean"))
  # apply encoding
  d <- data.frame(target_encode(d, target_encoding = te))
  d <- d[, !(names(d) %in% cols)]   # drop original categorical columns, retain encoded 
  colsnew <- colnames(d)
  
  # rename columns as it was originally
  colnames(d) <- gsub("target_mean_by_", "", colsnew)
  d <- d[, colsorig]   # make sure there is no extra columns
  # so 'rpart' will recognize, it is classification, not regression task:
  d$target <- as.factor(d$target)
  return(d)
}


# Factor Encoder - ensures that columns to encode have 
# 'factor' data type. 'rpart' function recognizes 
# categorical data with this type and treats it respectively
# d - dataset to learn and apply TE
# cols - a vector of names of columns to encode
encode_factor <- function(d, cols){
  for (i in cols){
    d[, i] <- as.factor(d[, i])
  }
  # so 'rpart' will recognize, it is classification, not regression task:
  d$target <- as.factor(d$target)
  return(d)
}


#### Load Data

d <- read.csv('kick.csv')   # Use a separate script to download data
d$target <- ifelse(d$target == "False", 0, 1)
cols <- colnames(d)[grepl('cat', colnames(d), fixed = TRUE)]   # names of categorical columns

#### Experiment

# MTE as preprocessing
d_te <- encode_te(d, cols)
# converting to 'factor' type (recursive MTE)
d_f <- encode_factor(data.frame(d), cols)
# converting to 'factor' type via MTE (lossy)
d_tef <- encode_factor(data.frame(d_te), cols)

# train models
dt_te <- rpart(target ~ ., d_te)   # MTE as preprocessing
dt_f <- rpart(target ~ ., d_f)     # recursive MTE
dt_tef <- rpart(target ~ ., d_tef) # lossy recursive MTE

# plot models
jpeg(height = 350, width = 350, "dt_te.jpg")
plot(dt_te)
dev.off()

jpeg(height = 350, width = 350, "dt_f.jpg")
plot(dt_f)
dev.off()

jpeg(height = 350, width = 350, "dt_tef.jpg")
plot(dt_tef)
dev.off()

# TODO: make the plots prettier! (drop split conditions)
# rpart.plot(dt_te)
# rpart.plot(dt_f)
# rpart.plot(dt_tef)
# 
# print(dt_te)
# print(dt_f)
# print(dt_tef)

