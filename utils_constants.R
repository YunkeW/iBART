#' @title Parse descriptor strings to identify feature and operation type
#' @description Extracts feature name and operation type from descriptor strings like "log((x.2+CONST))"
#' @param descr_string The descriptor string to parse
#' @return List containing type and feature name
parse_descriptor <- function(descr_string) {
  descr_string <- trimws(descr_string)
  
  # 1) log( ( x.<i> + CONST ) )
  if (grepl("^log\\s*\\(\\s*\\(x\\.\\d+\\+CONST\\)\\s*\\)\\s*$", descr_string)) {
    feature_name <- sub("^log\\s*\\(\\s*\\((x\\.\\d+)\\+CONST\\)\\s*\\)\\s*$",
                        "\\1", descr_string)
    return(list(type = "LOG_PLUS_CONST", feature = feature_name))
  }
  
  # 2) log(abs( ( x.<i> + CONST ) ))
  if (grepl("^log\\s*\\(\\s*abs\\s*\\(\\s*\\(x\\.\\d+\\+CONST\\)\\s*\\)\\s*\\)\\s*$", descr_string)) {
    feature_name <- sub("^log\\s*\\(\\s*abs\\s*\\(\\s*\\((x\\.\\d+)\\+CONST\\)\\s*\\)\\s*\\)\\s*$",
                        "\\1", descr_string)
    return(list(type = "LOG_ABS_PLUS_CONST", feature = feature_name))
  }
  
  # 3) sin( ( x.<i> + CONST ) )
  if (grepl("^sin\\s*\\(\\s*\\(x\\.\\d+\\+CONST\\)\\s*\\)\\s*$", descr_string)) {
    feature_name <- sub("^sin\\s*\\(\\s*\\((x\\.\\d+)\\+CONST\\)\\s*\\)\\s*$",
                        "\\1", descr_string)
    return(list(type = "SIN_PLUS_CONST", feature = feature_name))
  }
  
  # 4) exp( ( x.<i> + CONST ) )
  if (grepl("^exp\\s*\\(\\s*\\(x\\.\\d+\\+CONST\\)\\s*\\)\\s*$", descr_string)) {
    feature_name <- sub("^exp\\s*\\(\\s*\\((x\\.\\d+)\\+CONST\\)\\s*\\)\\s*$",
                        "\\1", descr_string)
    return(list(type = "EXP_PLUS_CONST", feature = feature_name))
  }
  
  stop("parse_descriptor(): Unknown descriptor pattern: ", descr_string)
}

#' @title Build design matrix for inside‐constant optimization (and plain evaluation)
#' @description Constructs design matrix Φ(X; C).  If a descriptor string contains "+CONST",
#'              then parse it via parse_descriptor() and compute f(x + C).  Otherwise,
#'              simply evaluate the descriptor as ordinary R code.
#' @param X Design matrix (numeric matrix whose columns are named "x.1", "x.2", …)
#' @param descriptor_strings Vector of descriptor strings
#' @param C Vector of inside‐constants (one entry for each descriptor that has "+CONST")
#' @return An n×k numeric matrix: 
#'         - For each j where descriptor_strings[j] has "+CONST", compute f( X[,feature_j] + C[j] ). 
#'         - For each j with no "+CONST", evaluate descriptor_strings[j] directly via eval(parse(...)) in a "with(as.data.frame(X), …)" context.
build_design_matrix <- function(X, descriptor_strings, C) {
  n <- nrow(X)
  k <- length(descriptor_strings)
  Phi <- matrix(NA_real_, nrow = n, ncol = k)
  colnames(Phi) <- paste0("Φ", seq_len(k))
  
  # Turn X into a data.frame so that `with(Xdf, eval(expr))` can find columns x.1, x.2, etc.
  Xdf <- as.data.frame(X, stringsAsFactors = FALSE)
  # If a "CONST" column is needed (for completeness), ensure it's there.
  if (!("CONST" %in% colnames(Xdf))) {
    Xdf$CONST <- 1
  }
  
  for (j in seq_len(k)) {
    ds <- descriptor_strings[j]
    
    if (grepl("\\+CONST", ds, fixed = TRUE)) {
      # "+CONST" case → parse & shift
      info <- parse_descriptor(ds)
      xj <- X[, info$feature]
      if (info$type == "LOG_PLUS_CONST") {
        Phi[, j] <- log(xj + C[j])
      } else if (info$type == "LOG_ABS_PLUS_CONST") {
        Phi[, j] <- log(abs(xj + C[j]))
      } else if (info$type == "SIN_PLUS_CONST") {
        Phi[, j] <- sin(xj + C[j])
      } else if (info$type == "EXP_PLUS_CONST") {
        Phi[, j] <- exp(xj + C[j])
      } else {
        stop("Unhandled CONST descriptor in build_design_matrix(): ", ds)
      }
      
    } else {
      # No "+CONST" → plain evaluation of the descriptor as R code
      # e.g. "((x.6 - x.9))^2", "sin(x.1)", "log(x.3)", etc.
      expr_j <- parse(text = ds)[[1]]
      Phi[, j] <- with(Xdf, eval(expr_j))
    }
  }
  
  return(Phi)
} 