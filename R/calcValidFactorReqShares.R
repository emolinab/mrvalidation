#' @title calcValidFactorReqShares
#'
#' @description calculates the validation data for labor and capital requirement shares in agriculture
#' (currently the same shares for crop and livestock production based on USDA data)
#' @param subtype for which to report requirement shares, either "crop" or "livestock"
#'
#' @return List of magpie objects with results on country level, weight on country level, unit and description.
#' @author Debbora Leip
#' @examples
#' \dontrun{
#' calcOutput("ValidFactorReqShares")
#' }
#'
calcValidFactorReqShares <- function(subtype = "crop") {

  if (!(subtype %in% c("crop", "livestock"))) stop("subtype must be either 'crop' or 'livestock'")

  out <- setNames(calcOutput("AgCapLabourShare", aggregate = FALSE),
                  paste0("Factor requirement shares|", stringr::str_to_title(subtype),
                         " products|+|Capital requirement share (%)"))
  out <- mbind(out, setNames(1 - out, paste0("Factor requirement shares|", stringr::str_to_title(subtype),
                                             " products|+|Labor requirement share (%)")))

  # convert to percentage
  out <- out * 100

  out <- add_dimension(out, dim = 3.1, add = "scenario", nm = "historical")
  out <- add_dimension(out, dim = 3.2, add = "model", nm = "USDA")


  # factor costs as weight
  factorCostsCrops <- dimSums(calcOutput("FactorCostsCrops", aggregate = FALSE), dim = 3.1)
  factorCostsLivst <- dimSums(calcOutput("FactorCostsLivst", aggregate = FALSE), dim = 3.1)
  weight <- factorCostsCrops + factorCostsLivst

  # add missing years to weight
  missingYears <- setdiff(getYears(out, as.integer = TRUE), getYears(weight, as.integer = TRUE))
  if (any(missingYears > min(getYears(weight, as.integer = TRUE)))) {
    stop("Need to fix weight for new years not covered in factor costs dataset")
  }
  minYear <- min(getYears(weight, as.integer = TRUE))
  weight <- magpiesort(add_columns(weight, dim = 2, addnm = paste0("y", missingYears)))
  weight[, missingYears, ] <- weight[, minYear, ]

  # Give 0 weigh to countries with unexpectedly high capital shares
  weight[c("BLZ", "CRI", "DOM", "HND", "JAM", "MEX", "NIC", "PAN", "SLV"), , ] <- 0

  years <- intersect(getYears(weight), getYears(out))
  weight <- weight[, years, ]
  out <- out[, years, ]
  weight[out[, , "Capital", pmatch = TRUE] == 0] <- 0
  weight[weight == 0] <- 10^-10


  return(list(x = out,
              weight = weight,
              unit = "%",
              description = "Factor requirement shares based on USDA data")
  )
}
