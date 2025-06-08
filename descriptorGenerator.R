descriptorGenerator <- function(data = NULL, opt = "binary", sin_cos = FALSE, apply_pos_opt_on_neg_x = TRUE, verbose = TRUE) {
  if (opt == "binary") {
    if (verbose) cat("Constructing descriptors using binary operators... \n")
    data <- binary(data, sin_cos)
  } else if (opt == "unary") {
    if (verbose) cat("Constructing descriptors using unary operators... \n")
    
    # Create new descriptors by applying unary ops *only* to the "(x.i+CONST)" columns
    new_descrs <- character(0)
    new_X      <- matrix(0, nrow = nrow(data$X), ncol = 0)
    new_unit   <- if (is.null(data$unit)) NULL else matrix(0, nrow = nrow(data$unit), ncol = 0)
    
    # Loop over all existing column names, but SKIP anything without "+CONST"
    for (i in seq_along(data$name)) {
      nm <- data$name[i]
      if (!grepl("\\+CONST", nm)) next
      
      # now do exactly: log((x.i+CONST)), sqrt((x.i+CONST)), abs((x.i+CONST))
      new_descrs <- c(new_descrs,
        paste0("log(",  nm, ")"),
        paste0("sqrt(", nm, ")"),
        paste0("abs(",  nm, ")")
      )
      new_X <- cbind(new_X,
        log( data$X[,i] ),
        sqrt(data$X[,i] ),
        abs( data$X[,i] )
      )
      if (!is.null(data$unit)) {
        new_unit <- cbind(new_unit, matrix(0, nrow=nrow(data$unit), ncol=3))
      }
    }
    
    # Update the data object with new descriptors
    data$X    <- cbind(data$X, new_X)
    data$name <- c(data$name, new_descrs)
    if (!is.null(data$unit)) data$unit <- cbind(data$unit, new_unit)
    
    # SKIP dataprocessing here so that the two inside-constant log descriptors survive
    # data <- dataprocessing(data)
    
    cat(paste0("Building X.unary... Initial p = ", ncol(data$X) - length(new_descrs), 
                "; New p = ", ncol(data$X)), "\n")
    
  } else {
    if (verbose) cat("Constructing descriptors using all operators... \n")
    data_unary <- unary(data, sin_cos, apply_pos_opt_on_neg_x)
    data_binary <- binary(data, sin_cos)
    data$X <- cbind(data_unary$X, data_binary$X)
    data$name <- c(data_unary$name, data_binary$name)
    data$unit <- cbind(data_unary$unit, data_binary$unit)
    data <- dataprocessing(data)
  }
  return(data)
}
