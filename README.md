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

From BSc thesis: Conditioning short-leg of WML on short run market state vs long run market state "level" in order to anticipate crashes and the subsequent rebounds, which also rebound the short leg of WML, causing the strategy to crash. Interesting results, yet maybe not so interesting "function" wise as it needs some in-sample calibration and out-of-sample testing. 

### Panic state indicator and conditional portfolio return formula

The panic state indicator $I_t^P(\delta)$ for period $t$ is defined as:

$$
I_t^P(\delta) = \begin{cases} 
1, & r_{m,t}^{SR} < r_{m,t}^{LR} - \delta \sigma_{m,t}^{LR} \\ 
0, & r_{m,t}^{SR} \geq r_{m,t}^{LR} - \delta \sigma_{m,t}^{LR} 
\end{cases}
$$

where with some illustrative lookback periods:
- $r_{m,t}^{SR} = \frac{1}{3} \sum_{i=-4}^{-2} r_{m,i}$: short run average return
- $r_{m,t}^{LR} = \bar{r_t} = \frac{1}{120} \sum_{i=-121}^{-2} r_{m,i}$: long run average return
- $\sigma_{m,t}^{LR} = \sqrt{\frac{1}{119} \sum_{i=-121}^{-2} (r_{m,i} - \bar{r_t})^2}$: long run standard deviation

Here, $\delta \in \mathbb{R}_+$ represents a positive scalar. This $\delta$ must be calibrated by in-sample simulations.

When $I_t^P = 0$, the market is stable. When $I_t^P = 1$, the market is in a state of panic.

The portfolio return $r_{p,t}(\delta)$ is then given by:

$$
r_{p,t}(\delta) = (1 - I_t^P(\delta))(r_{W,t} - r_{L,t}) + I_t^P(\delta) \left( \frac{1}{2}(r_{W,t} + r_{L,t}) - r_{f,t} \right)
$$

where:
- $r_{W,t}$: return of the 10th (winner) momentum decile
- $r_{L,t}$: return of the 1st (loser) momentum decile
- $r_{f,t}$: risk-free rate


## Using the function
Install the packages, declare the function and then run the function with inputs from the editor or from terminal. 

Performance not optimized, yet redundant and over-lapping operations avoided, modern PC runs roughly 1 million return observations in 1 minute. Past 50 years of CRSP data from major US stock exchanges took roughly 3-4 minutes.

