######################################################
# Earthquake Data Regression and Hybrid Forecasting
######################################################

###################### DATASET PROCESSING #############################

# List all files in the current working directory
dir()
# Get the current working directory
getwd()

# Read the earthquake data from a CSV file
data <- read.csv("earthquake.csv")

# Filter rows that contain "Indonesia" in the "place" column
indonesia_data <- subset(data, grepl("Indonesia", data$place))

# Preview the filtered data
head(indonesia_data)

# Use Indonesia data as the working dataset
data <- indonesia_data
head(data)
tail(data)

# Keep the first 5 columns of data
data <- data[, c(1:5)]
head(data)
tail(data)

# Load required libraries
library(oce)
library(lubridate)

# Extract the date from the first column
my_datetime <- data[, 1]
time <- substr(my_datetime, 1, 10)
head(time)

# Combine the new time data with the rest of the columns, excluding the original time column
time <- as.matrix(time)
data <- cbind(time, data[, -1])
head(data)

# Define start and end date for filtering
start_date <- as.Date("1906-01-01")
end_date <- as.Date("2022-12-31")

# Filter data between start and end dates
subset_data <- subset(data, time >= start_date & time <= end_date)
head(subset_data)
tail(subset_data)

# Select only the date and magnitude columns
subset_data <- subset_data[, c(1, 5)]
colnames(subset_data)[1] <- "date"

# Create a complete date range for merging with the earthquake data
date_range <- data.frame(date = seq(as.Date("1906-01-01"), as.Date("2022-12-31"), by = "day"))
subset_data$date <- as.Date(subset_data$date)

# Merge earthquake data with the complete date range and fill missing values with 0
merged_data <- merge(date_range, subset_data, by = "date", all = TRUE)
merged_data[is.na(merged_data)] <- 0
head(merged_data)
tail(merged_data)

# Save the cleaned data as a CSV file
write.csv(data, file = "~/Desktop/merged_data.csv", row.names = FALSE)

# Convert magnitude values >= 6 to 1 (binary classification for strong earthquakes)
merged_data$mag[merged_data$mag >= 6] <- 1
earthquake_data <- merged_data
colnames(earthquake_data)[2] <- "magnitude_type"

# Convert the date column to Date format
earthquake_data$date <- as.Date(earthquake_data$date, "%Y-%m-%d")

# Convert magnitude_type to a factor for categorical analysis
earthquake_data$magnitude_type <- as.factor(earthquake_data$magnitude_type)

library(dplyr)
library(tidyr)

# Seismic level analysis: count occurrences of magnitude_type 1 by month per year
df1 <- earthquake_data %>%
  filter(magnitude_type == 1) %>%
  mutate(year = format(date, "%Y"), month = format(date, "%m")) %>%
  count(year, month) %>%
  complete(year, month, fill = list(n = 0))

# Convert year and month to a proper date format for time series
df1$date <- as.Date(paste(df1$year, df1$month, "01", sep = "-"))
head(df1)
tail(df1)

###################### Time Series Processing #############################

# Convert data to time series format
ts_data <- ts(df1$n, start = c(1906, 1), frequency = 12)

###################### ARIMA Model ####################################

# Train ARIMA model on data from 1906 to 2021
train_time <- window(ts_data, end = c(2021, 12))
test_time <- window(ts_data, start = c(2022, 1))

# Plot training data
plot(train_time, main = "Monthly Data from 1906 to 2021", ylab = "Values", xlab = "Year")

# Find the best ARIMA model by testing different parameters
max_ar <- 3  # Maximum AR order
max_diff <- 1  # Maximum differencing order
max_ma <- 3  # Maximum MA order

# Store AIC values for different ARIMA orders
aic_data <- data.frame(order = character(), aic = numeric(), stringsAsFactors = FALSE)

# Loop through different ARIMA model configurations
for (p in 0:max_ar) {
  for (d in 0:max_diff) {
    for (q in 0:max_ma) {
      # Fit ARIMA model
      model <- arima(train_time, order = c(p, d, q))
      # Store AIC value
      aic <- AIC(model)
      aic_data <- rbind(aic_data, data.frame(order = paste(p, d, q, sep = ","), aic = aic))
    }
  }
}

# Print AIC values and find the minimum
print(aic_data)
min(aic_data$aic)

# Fit the best ARIMA model automatically
arima_fit <- auto.arima(train_time)
summary(arima_fit)

# Forecast for the next 12 months
forecast_ar <- forecast(arima_fit, h = 12)

# Prepare actual vs predicted values for evaluation
time_test <- cbind(as.data.frame(test_time), as.data.frame(forecast_ar$mean))
colnames(time_test) <- c("actual", "predicted")

# Calculate RMSE and MAE for ARIMA model on test data
ARIAM_rmse_test <- sqrt(mean((time_test$actual - time_test$predicted)^2))
ARIAM_mae_test <- mean(abs(time_test$actual - time_test$predicted))

# Print RMSE and MAE
ARIAM_rmse_test
ARIAM_mae_test

###################### Hybrid Models: ARIMA + SVR / Random Forest / XGBoost #############################

# Calculate residuals from ARIMA model
residuals <- time_test$actual - time_test$predicted

# Train SVR, Random Forest, and XGBoost on residuals for hybrid modeling
# Example: SVR on residuals
library(e1071)

# Tune SVR model
svm_model <- svm(residuals ~ actual, data = time_test, kernel = "radial")
# Predict residuals
svm_forecast <- predict(svm_model, time_test$actual)

# Combine ARIMA predictions with SVR predictions
final_forecast <- time_test$predicted + svm_forecast

# Calculate RMSE and MAE for the hybrid model
rmse_hybrid_svr <- sqrt(mean((time_test$actual - final_forecast)^2))
mae_hybrid_svr <- mean(abs(time_test$actual - final_forecast))

# Print hybrid model results
rmse_hybrid_svr
mae_hybrid_svr

###################### Visualizing the Results #############################

library(ggplot2)

# Plot actual vs predicted for ARIMA and hybrid models
ggplot(time_test, aes(x = as.Date("2022-01-01") + months(0:11))) +
  geom_line(aes(y = actual, color = "Actual"), size = 1) +
  geom_line(aes(y = predicted, color = "ARIMA"), size = 1, linetype = "dashed") +
  geom_line(aes(y = final_forecast, color = "ARIMA + SVR"), size = 1, linetype = "dotted") +
  labs(title = "Actual vs Predicted Earthquake Magnitude",
       x = "Date", y = "Magnitude") +
  scale_color_manual(values = c("Actual" = "black", "ARIMA" = "blue", "ARIMA + SVR" = "red")) +
  theme_minimal()

