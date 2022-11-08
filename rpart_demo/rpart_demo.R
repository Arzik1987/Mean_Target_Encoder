library(rpart)                                                                  # for learning DT
library(OpenML)
source('../utils/get_data.R')
source('../utils/encode_mte.R')


d <- get.data("kick")                                                           # load kick dataset
d <- fill.na(d)                                                                 # fill missing values
dte <- encode.mte(d)[[1]]                                                            # preprocess with MTE

dt_te <- rpart(target ~ ., dte, method = "class")                               # DT with MTE as preprocessing
dt_f <- rpart(target ~ ., d, method = "class")                                  # DT with recursive MTE

jpeg(height = 350, width = 350, "dt_te.jpg")                                    # plot DTs
plot(dt_te)
dev.off()

jpeg(height = 350, width = 350, "dt_f.jpg")
plot(dt_f)
dev.off()

print(dt_te)                                                                    # print DT models
print(dt_f)