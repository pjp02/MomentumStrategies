# Momentum strategies

This repository is for my personal "out of curiosity" projects exploring momentum strategies, implemented in **R** and **Python**. This project is motivated by some approaches I encountered while writing a thesis on momentum strategies, other approaches I have come across later on. The code generates a summary table of characteristics for momentum-based decile portfolios and optionally outputs monthly portfolio data for further analysis.

## Overview
The primary purpose of this project is to form and analyze decile-based momentum portfolios using a "12-1" (common in academic research) construction method (past 12-month returns, excluding the most recent month to avoid reversal effects) and a 1-month holding period with monthly rebalancing.

### Example summary table output
|            | Mean Return (%) | Standard Deviation (%) | Skewness | Sharpe Ratio |
|------------|-----------------|------------------------|----------|--------------|
| Decile_1   | 2.31            | 36.65                 | 0.88     | 0.063        |
| Decile_2   | 6.58            | 27.42                 | 0.21     | 0.240        |
| Decile_3   | 8.59            | 22.78                 | 0.26     | 0.377        |
| ...        | ...             | ...                   | ...      | ...          |
| Decile_10  | 19.51           | 24.53                 | -0.15    | 0.795        |
| WML        | 17.19           | 31.77                 | -1.48    | 0.541        |

## "Strategy parameters"
The code allows adjusting some aspects of the momentum strategy. In particular, parameters 4) and 5) allow users to explore factors that are often excluded in academic research.

1. **Data source**: Path to the data file in CSV format (e.g., `"folder/CRSP_data.csv"`). The data should have the following columns: `date`, `CUSIP`, `PRC`, `RET`, `SHROUT`, `SICCD`.
2. **Signal (ranking method)**: 
   - `1` for pure 12-1 cumulative returns
   - `2` for volatility-controlled returns (motivation: gradual trading (Kyle, 1985) & frog in the pan (Da, et al., 2014))
3. **Portfolio formation**:
   - `1` for value-weighted
   - `2` for equally-weighted
4. **"Micro cap" exclusion**:
   - `1` to include the smallest 5% of eligible stocks
   - `2` to exclude the smallest 5%
5. **Banking and finance exclusion**:
   - `1` to include
   - `2` to exclude 

## Data
The code is designed to work with data in a standard **CRSP** format. Due to copyright restrictions and the broad availability of CRSP data, no example or pseudodata is included in this repository.

## Future development
Planning to extend this project to include different lagged (t-1) constructions and holding periods for further testing and analysis.

## Using the function
Install the packages, declare the function and then run the function with inputs from the editor or from terminal.

