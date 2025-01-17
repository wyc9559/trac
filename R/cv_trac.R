#' Perform cross validation for tuning parameter selection
#'
#' This function is to be called after calling \code{\link{trac}}.  It performs
#' \code{nfold}-fold cross validation. For classification the metric is
#' misclassification error.
#'
#' @param fit output of \code{\link{trac}} function.
#' @param Z,y,A,additional_covariates same arguments as passed to
#'    \code{\link{trac}}
#' @param folds a partition of \code{1:nrow(Z)}.
#' @param nfolds number of folds for cross-validation
#' @param summary_function how to combine the errors calculated on each
#' observation within a fold (e.g. mean or median) (only for regression task)
#' @param stratified if `TRUE` use stratified folds based on target variable
#'   only for classification. Default set to FALSE.
#' @export
cv_trac <- function(fit, Z, y, A, additional_covariates = NULL, folds = NULL,
                    nfolds = 5, summary_function = stats::median,
                    stratified = FALSE) {
  n <- nrow(Z)
  p <- ncol(Z)
  if (!is.null(additional_covariates) & !is.data.frame(additional_covariates)) {
    additional_covariates <- data.frame(additional_covariates)
  }
  stopifnot(length(y) == n)
  if (is.null(folds)) {
    if (stratified) {
      folds <- make_folds_stratified(n, nfolds, y)
    } else {
      folds <- ggb:::make_folds(n, nfolds)
    }
  } else {
    nfolds <- length(folds)
  }
  
  cv <- list()
  fit_folds <- list() # save this to reuse by log-ratio's cv function
  for (iw in seq_along(fit)) {
    if (length(fit) > 1) cat("CV for weight sequence #", iw, fill = TRUE)
    errs <- matrix(NA, ncol(fit[[iw]]$beta), nfolds)
    predicted_values <- matrix(NA, 0, ncol(fit[[iw]]$beta))
    for (i in seq(nfolds)) {
      cat("fold", i, fill = TRUE)
      # add for backward compatibility
      if (is.null(fit[[iw]]$method)) fit[[iw]]$method <- "regr"
      if (is.null(fit[[iw]]$w_additional_covariates)) {
        fit[[iw]]$w_additional_covariates <- NULL
      }
      if (is.null(fit[[iw]]$rho)) fit[[iw]]$rho <- 0
      
      
      # train on all but i-th fold (and use settings from fit):
      fit_folds[[i]] <- trac(Z = Z[-folds[[i]], ],
                             y = y[-folds[[i]]],
                             A = A,
                             additional_covariates =
                               additional_covariates[-folds[[i]], ],
                             fraclist = fit[[iw]]$fraclist,
                             w = fit[[iw]]$w,
                             w_additional_covariates =
                               fit[[iw]]$w_additional_covariates,
                             method = fit[[iw]]$method,
                             rho = fit[[iw]]$rho,
                             normalized = fit[[iw]]$normalized)
      
      if (fit[[iw]]$refit) {
        fit_folds[[i]] <- refit_trac(fit_folds[[i]], Z[-folds[[i]], ],
                                     y[-folds[[i]]], A)
      }
      if (fit[[iw]]$method == "regr" | is.null(fit[[iw]]$method)) {
        errs[, i] <- apply(
          (predict_trac(
            fit_folds[[i]],
            Z[folds[[i]], ],
            additional_covariates[folds[[i]], ])[[1]] - y[folds[[i]]])^2,
          2, summary_function
        )
      }
      
      if (fit[[iw]]$method == "classif" |
          fit[[iw]]$method == "classif_huber") {
        # loss: max(0, 1 - y_hat * y)^2
        er <- sign(predict_trac(fit_folds[[i]],
                                Z[folds[[i]],],
                                additional_covariates[folds[[i]],])[[1]]) !=
          c(y[folds[[i]]])
        errs[, i] <- colMeans(er)
      }
      
      predicted_values <- rbind(predicted_values,
                                predict_trac(
                                  fit_folds[[i]],
                                  Z[folds[[i]], ],
                                  additional_covariates[folds[[i]], ])[[1]])
    }
    m <- rowMeans(errs)
    se <- apply(errs, 1, stats::sd) / sqrt(nfolds)
    ibest <- which.min(m)
    i1se <- min(which(m <= m[ibest] + se[ibest]))
    cv[[iw]] <- list(
      errs = errs, m = m, se = se,
      lambda_best = fit[[iw]]$fraclist[ibest], ibest = ibest,
      lambda_1se = fit[[iw]]$fraclist[i1se], i1se = i1se,
      fraclist = fit[[iw]]$fraclist, w = fit[[iw]]$w,
      nonzeros = colSums(abs(fit[[iw]]$gamma) > 1e-5),
      fit_folds = fit_folds,
      predicted_values = predicted_values
    )
  }
  list(
    cv = cv,
    iw_best = which.min(lapply(cv, function(cvv) cvv$m[cvv$ibest])),
    iw_1se = which.min(lapply(cv, function(cvv) cvv$m[cvv$i1se])),
    folds = folds
  )
}

#' This function creates stratified folds for cross validation for unbalanced
#' data. The code is adopted from ggb:::make_folds
#'
#' @param n number of observations
#' @param nfolds number of folds
#' @param y variable with group assignment.

make_folds_stratified <- function(n, nfolds, y) {
  # Check if number of folds is greater than the max n of observations
  # per group. If the number is greater at least one fold will not contain
  # any observations of group of interest.
  max_n_y <- max(table(y))
  nfolds <- min(nfolds, max_n_y)
  # Initiate the list in advance
  folds <- vector(mode = "list", length = nfolds)
  for (j in unique(y)) {
    ixs <- which(y == j)
    nn <- round(length(ixs) / nfolds)
    sizes <- rep(nn, nfolds)
    sizes[nfolds] <- sizes[nfolds] + length(ixs) - nn * nfolds
    b <- c(0, cumsum(sizes))
    ii <- sample(length(ixs))
    ii <- ixs[ii]
    for (i in seq(nfolds)) {
      folds[[i]] <- c(folds[[i]], ii[seq(b[i] + 1, b[i + 1])])
    }
  }
  folds
}