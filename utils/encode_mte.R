encode.mte <- function(dtr, dte = NULL){
  require(dataPreparation)                                                      # contains TE implementation
  colnames(dtr) <- gsub(".*\\.","",colnames(dtr))
  
  colsorig <- colnames(dtr)                                                     # save names of columns
  cols <- colnames(dtr)[grepl('cat', colnames(dtr), fixed = TRUE)]              # names of categorical columns
  target = colnames(dtr)[grepl('target', colnames(dtr), fixed = TRUE)]
  
  te <- build_target_encoding(dtr, cols_to_encode = cols,
                              target_col = target, functions = c("mean"))       # Construct encoding
  
  dtr <- data.frame(target_encode(dtr, target_encoding = te))                   # apply encoding train
  
  if(!is.null(dte)){
    colnames(dte) <- gsub(".*\\.","",colnames(dte))
    dte <- data.frame(target_encode(dte, target_encoding = te))                 # apply encoding test
    dte <- dte[, !(names(dte) %in% cols)]                                       # drop original categorical columns, retain encoded 
    colnames(dte) <- gsub("target_mean_by_", "", colnames(dte))                 # rename columns as it was originally
    dte <- dte[, colsorig]                                                      # make sure there is no extra columns
  }
  
  dtr <- dtr[, !(names(dtr) %in% cols)]                                         # drop original categorical columns, retain encoded 
  colnames(dtr) <- gsub("target_mean_by_", "", colnames(dtr))                   # rename columns as it was originally
  dtr <- dtr[, colsorig]                                                        # make sure there is no extra columns
  return(list(dtr, dte))
}