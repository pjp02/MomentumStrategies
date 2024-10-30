##### Install Necessary Packages #####
install.packages("tidyverse")
install.packages("zoo")
install.packages("lubridate")
install.packages("e1071") #skewness

library(tidyverse)
library(zoo)
library(lubridate)
library(e1071)

##### Function for Cross-Sectional Momentum 12-1, see guide at the bottom! #####
# Note 1: Holding period is always 1 month, to be added
# Data format standard CRSP CSV

csMomentumFunction <- function(dataSource, signal, portfolioFormation, microCaps, banksFinance, outputName) {
  
  ### Read data ### 
  rawData <- read.csv(dataSource)
  
  
  
  ### Prepare data ###
  crspRetData <- rawData %>%
    filter(grepl("^-?\\d*(\\.\\d+)?$", RET)) %>% # keep if ret numeric, robustness for errors
    mutate(RET = as.numeric(RET)) %>%
    filter(!is.na(RET)) %>%
    {if (banksFinance == 2) filter(., !(6000 <= SICCD & SICCD <= 6999)) else .} %>%
    select(CUSIP, date, RET, SHROUT, PRC) %>%
    mutate(date = as.Date(as.character(date), format = "%Y%m%d"),
           yearMonth = format(date, "%Y%m")) %>%
    mutate(tm2YM = format(date %m-% months(2), "%Y%m")) %>% # via lubridate
    group_by(CUSIP) %>%
    arrange(date, .by_group = TRUE) %>% 
    mutate(logRets = log(1 + RET)) %>% # returns
    mutate(
      lag_yearMonth = lag(yearMonth, 2),
      lag_SHROUT = lag(SHROUT, 2),
      lag_PRC = lag(PRC, 2),
      marketCap = if_else(
        lag_yearMonth == tm2YM & !is.na(PRC) & !is.na(SHROUT) & !is.na(RET), # ensure validity for later
        abs(lag_SHROUT * lag_PRC),
        NA_real_
      )
    ) %>%
    # clean up
    select(-lag_yearMonth, -lag_SHROUT, -lag_PRC, -tm2YM) %>%
    ungroup()
  
  
  
  # Function for cumulative return, check NA in the rolling 11month window, summing the logs
  cumRetFunction <- function(x) {
    if (sum(is.na(x)) == 0 && length(x) == 11) {
      return(sum(x))
    } else {
      return(NA_real_)
    }
  }
  
  ### Calculate Return Signal ###
  crspCumRetData <- crspRetData %>%
    # Group by CUSIP and arrange data by date
    group_by(CUSIP) %>%
    arrange(date, .by_group = TRUE) %>%
    mutate(
      validMarketCapCount = rollapply(
        marketCap,
        width = 11,
        FUN = function(x) sum(!is.na(x) & x > 0),
        align = "right",
        fill = NA
      )
    ) %>%
    mutate(
      cumRet_raw = if (signal == 1) {
        exp(rollapply(
          logRets,
          width = 11,
          FUN = cumRetFunction,
          align = "right",
          fill = NA
        )) - 1
      } else if (signal == 2) {
        (exp(rollapply(
          logRets,
          width = 11,
          FUN = cumRetFunction,
          align = "right",
          fill = NA
        )) - 1) / rollapply(
          logRets,
          width = 11,
          FUN = function(x) sqrt(var(x, na.rm = TRUE)),
          align = "right",
          fill = NA
        )
      },
      cumRet = if_else(
        validMarketCapCount == 11,
        lag(cumRet_raw, 2),
        NA_real_
      )
    ) %>%
    ungroup()
  
  
  
  ### Portfolio weighting ###
  crspRetDecSplits <- crspCumRetData %>%
    group_by(date) %>%
    filter(!is.na(cumRet)) %>%
    {if (microCaps == 2) filter(., marketCap > quantile(marketCap, 0.05, na.rm = TRUE)) else .} %>% # clean out smallest 5%
    mutate(cumRetDecile = ntile(cumRet, 10)) %>%
    ungroup()
  
  
  
  ### Portfolio weighting ###
  crspRetWeights <- crspRetDecSplits %>%
    group_by(date, cumRetDecile) %>%
    mutate(
      weight = if (portfolioFormation == 1) {
        marketCap / sum(marketCap, na.rm = TRUE)
      } else if (portfolioFormation == 2) {
        1 / n()
      }
    ) %>%
    ungroup()
  
  
  
  ### Decile Returns and WML TABLE###
  crspRetDecileTable <- crspRetWeights %>%
    group_by(date, cumRetDecile) %>%
    summarise(decRet = sum(weight * RET, na.rm = TRUE), .groups = "drop") %>%
    pivot_wider(
      names_from = cumRetDecile,
      values_from = decRet,
      names_prefix = "Decile_"
    ) %>%
    mutate(WML = Decile_10 - Decile_1)
  
  
  
  ### OUTPUT ###
  
  # Calculate annualized returns and volas for each decile and WML
  annualizedReturns <- colMeans(crspRetDecileTable[-1], na.rm = TRUE) * 12
  annualizedSD <- sqrt(apply(crspRetDecileTable[-1], 2, var, na.rm = TRUE)) * sqrt(12)
  SharpeRatio <- round(annualizedReturns / annualizedSD, 3)
  skewnessReturns <- apply(crspRetDecileTable[-1], 2, skewness, na.rm = TRUE)
    
  summaryTable <- data.frame(
    "Mean Return" = round(annualizedReturns*100, 2),
    "Standard Deviation" = round(annualizedSD*100, 2),
    "Skewness" = round(skewnessReturns, 2),
    "Sharpe Ratio" = SharpeRatio
  )
    
  rownames(summaryTable) <- colnames(crspRetDecileTable[-1])
  
  settings <- paste(
    "######",
    paste("Data Source:", dataSource),
    paste("Signal:", if (signal == 1) "Pure 12-1 cumulative returns" else "Volatility controlled"),
    paste("Portfolio Formation:", if (portfolioFormation == 1) "Value-weighted" else "Equally weighted"),
    paste("Micro Caps:", if (microCaps == 1) "Included" else "Excluded"),
    paste("Banks & Finance:", if (banksFinance == 1) "Included" else "Excluded"),
    paste("Output File:", if (is.na(outputName)) "None" else outputName),
    "######",
    sep = "\n"
  )
  
  cat(settings, "\n")
  print(summaryTable)
  
  if (!is.na(outputName)) {
    write.csv(crspRetDecileTable, outputName)
    cat("created output file:", outputName, "\n")
  }
}



# INPUTS for the csMomentumFunction are as follows:
# 1) dataSource         : "folder/CRSP_data.csv", requires columns for date, CUSIP, PRC, RET, SHROUT, SICCD
# 2) signal             : 1 for pure 12-1 cumulative returns, 2 for volatility controlled -||- 
# 3) portfolioFormation : 1 for value weighted, 2 for equally weighted
# 4) microCaps          : 1 for including smallest 5% otherwise eligible, 2 for excluding -||-
# 5) banksFinance       : 1 for including banks and finance, 2 for excluding -||-  
# 6) outputName         : NA if no output, for output "folder/CRSP_data.csv"

csMomentumFunction("folder/CRSP_data.csv",
                   2,
                   1,
                   2,
                   2,
                   NA
                   )