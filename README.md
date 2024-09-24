# Earthquake Magnitude Prediction and Hybrid Time Series Forecasting

This repository contains R code and models for predicting earthquake magnitudes in Indonesia using ARIMA, Support Vector Regression (SVR), Random Forest, and XGBoost models. The project focuses on time series forecasting with hybrid models to improve the accuracy of predictions by combining statistical and machine learning approaches.

## Table of Contents
1. [Project Overview](#project-overview)
2. [Dataset](#dataset)
3. [Requirements](#requirements)
4. [Installation](#installation)
5. [Usage](#usage)
6. [Modeling Approach](#modeling-approach)
7. [Evaluation Metrics](#evaluation-metrics)
8. [Results](#results)
9. [Contributing](#contributing)
10. [License](#license)

## Project Overview
This project aims to:
- Predict earthquake magnitudes in Indonesia using time series data from 1906 to 2022.
- Build **ARIMA** models for basic forecasting and enhance predictions using **Support Vector Regression (SVR)**, **Random Forest (RF)**, and **XGBoost** for residual modeling (hybrid models).
- Compare the performance of individual models and hybrid approaches.

## Dataset
The dataset consists of earthquake records from Indonesia, extracted from a larger dataset of global earthquake data (`earthquake.csv`). The key features include:
- **Date**: The date of the earthquake.
- **Magnitude**: The magnitude of the earthquake.

Data cleaning steps include filtering earthquakes that occurred in Indonesia and filling missing dates with zeros to ensure a continuous time series.

## Requirements
To run this project, you will need the following R packages:
- `forecast`
- `tseries`
- `lubridate`
- `dplyr`
- `tidyr`
- `ggplot2`
- `randomForest`
- `e1071` (for SVR)
- `xgboost`

Install the required packages by running:
```r
install.packages(c("forecast", "tseries", "lubridate", "dplyr", "tidyr", "ggplot2", "randomForest", "e1071", "xgboost"))
