# An Analysis of European Airbnbs: What Features Contribute to Airbnb Prices?
## Abstract
According to Airbnb,“The total price of your Airbnb reservation is based on the nightly price set by the Host, plus fees or costs determined by either the Host or Airbnb” [3]. However, it is unknown what exactly Hosts might consider when calculating their nightly price, as it is not standardized. To investigate what features contribute to Airbnb prices, we conduct regression analysis on a dataset with over 50,000 Airbnb listings in 10 European cities. We find that property features such as person capacity, number of bedrooms, and closeness to nearby attractions and restaurants are positively associated with price, while features such as a private room and distance from a metro station are negatively associated with price. These findings match our intuition about which features contribute to the price of an Airbnb property. We invite future research into whether the same can be said for the American Airbnb market.
## 1. Background and Significance
According to Airbnb, “The total price of your Airbnb reservation is based on the nightly price set by the Host, plus fees or costs determined by either the Host or Airbnb” [3] However, it is unknown what exactly Hosts might consider when calculating their nightly price, as it is not standardized. We are interested in describing the features that contribute to Airbnb prices, and are particularly interested in whether intuition is reflected in a model for Airbnb price data (for example, it is intuitive that there is a negative relationship between distance to city center and price). Additionally, modeling of Airbnb prices can help inform pricing of new properties and/or potentially reveal overpricing of existing listings. We strive to answer two research questions:
What components of an Airbnb property are significant predictors of price?
Which features have a positive relationship with price? A negative relationship?

## 2. Data
### 2.1 Data Description and Previous Research
Our dataset of interest captures 2021 Airbnb prices in 10 major European cities, originally collected via web scraping by Kristóf Gyódi and Łukasz Nawaro in their paper “Determinants of Airbnb prices in European cities: A spatial econometrics approach” [2]. In particular, the authors queried Airbnb via Selenium for accommodations in selected European cities for two people and two nights and scraped data for bookings for dates 4-6 weeks out. The data were not collected over time. For each city, a dataset was prepared separately for offers on weekdays and on weekends. 

In their analysis, they conduct various regression analyses, including spatial regression analyses, and a main focus of their analysis is comparing the results of OLS regression models to spatial models. The analysis was done on the weekday samples, as the weekend samples were used for robustness checks. Generally, they find that “size, quality, and location are all significant drivers of Airbnb prices,” as well as that there is a spatial correlation between Airbnb prices [2]. For the current analyses, we remove the latitude and longitude coordinates and do not conduct spatial analysis.

Variables in the dataset include property features, such as number of bedrooms, capacity, and cleanliness rating, host features, such as whether or not the host is a superhost, and location features, including distance from the nearest metro station, and attraction and restaurant indices that capture how close a property is to tourist attractions and restaurants. (See Appendix Table 1 for all variables).

### 2.2 Data Cleaning and Multicollinearity screening
Because of the manner the dataset was prepared by the original authors, we merged the different data files and added the city and day type (weekdays or weekends) as additional variables. ID, latitude, longitude, and non-normalized attraction and restaurant indices were excluded from analysis.

We found that there was no missing data in the dataset. However, we found there to be complete linear dependency among room_type, room_shared, and room_private, as they share the same information. Thus, we removed room_shared and room_private. We tested for multicollinearity using stepwise VIF procedure with threshold of 10 and found no multicollinearity issues for the quantitative predictors. The cleaned dataset includes 51707 rows and 15 columns.

## 3. Methods and Results
### 3.1 First-Order Model Selection
In order to find the best first-order model, we performed backward stepwise procedure with AIC and BIC criterion, resulting in two first-order models. We performed 10-fold cross validation to select the best model. We found that there was no practical difference between the two CV scores and thus chose the more parsimonious model, which was the stepwise regression model with BIC criterion with 9 predictors.

### 3.2 Interaction Model
As we were interested in whether there are significant interaction terms that could improve our model, we performed backward stepwise regression with BIC criterion, starting with our best first-order model and found a model with 20 predictors. Because of the large size of the dataset and the high number of categorical variables with multiple levels, we knew we needed a parsimonious model that BIC criterion would provide. Since this process was computationally expensive, we did not compare this interaction model with any others.

### 3.3 Transformations
Prior to model comparison, checking the residual plots for the first-order and interaction models revealed that neither model fit the data well and that a power transformation on the response is necessary (Appendix Figure A). We performed a Box Cox transformation on the first-order and interaction model ( Appendix Figure B). Because the dataset is quite large, the interval for the optimal lambda value is very narrow, and using a value other than the optimal lambda is not appropriate. Additionally, in order to compare the models, the same transformation should be applied. Luckily, the optimal lambda for both models was approximately -0.3, so we applied a power transformation with this lambda value. To maintain direction of association between the response and predictors, we additionally multiplied the response by -1. After applying the transformation, the two models’ residual plots have better equal scatter and thus better meet the constant variance assumption (Appendix Figure C).

### 3.4 Final Model Selection
We find the transformed interaction model to have a slightly higher adjusted R2 and lower AIC and BIC values than the transformed first-order model (Appendix Table 2). However, the difference in model performance does not justify the increase in model complexity in the interaction model. As a result, we move forward with the transformed first-order model as our final model.

### 3.4 Model Diagnostics
Before finalizing our model, we checked our model diagnostics with plots (Appendix Figure D-E). The model meets the independence of errors assumption, as the time sequence plot has no pattern.  The QQ-plot appears to have significantly heavy tails, indicating a violation of normality of errors. The residual plot indicates nonconstant variance with a slight cone shape, albeit improved from the non-transformed model. Using studentized deleted residuals, we found there to be 2643 outlying observations. Although none of the points were influential using Cook’s distance, we still chose to remove them to improve model fit. In fact, the adjusted R2 went up almost 10%, so the model accounts for nearly 75% of variation in the response after accounting for model complexity. A limitation to this decision is that the model will not perform well on predicting these outlier values. 





## 4. Conclusion
### 4.1 Discussion
<img width="634" alt="Screenshot 2024-07-23 at 10 22 56 PM" src="https://github.com/user-attachments/assets/4b4ceda9-545f-49f2-bc8d-0d66351d05e7">

Above is the final model; all coefficients had a p-value of approximately zero (see Appendix Table 3 for full model output). As a note, the baseline for the city variable is Amsterdam and for room_type, the baseline is an entire house. Because of the transformation on the response, it is difficult to interpret the coefficients in this model, but we can note the direction of associations for the significant predictors. 

We find that guest capacity, whether the host has 2-4 listings, whether the host has 4+ listings, guest satisfaction, number of bedrooms, and the normalized attraction index have a positive association with the price of the listing. Conversely, whether the type of listing is a private or shared room (compared to an entire house), the distance to the closest metro station, and a different location (compared to Amsterdam) have a negative association with the price of the listing. 

These findings match our intuition about which property features increase and decrease price. For example, it is reasonable to assume that a higher guest satisfaction and attraction index, a more experienced host, and larger Airbnb would increase the price of a listing. Similarly, it makes sense for a private or shared room as opposed to an entire house and an Airbnb further from a metro station to be cheaper. 

### 4.2 Further Considerations
While analyzing the first-order model was appropriate for our research questions, it may be desirable to use a more complex model with interaction terms to predict the prices of properties or inform the pricing of new properties. Similarly, if the goal is prediction, it may not be desirable to remove non-influential outliers. 

Additionally, while the findings from our analysis make intuitive sense with respect to the relationship between property features and price, it would not be appropriate to use our model and generalize to other locations, such as the US Airbnb market. Conducting similar analyses on US Airbnb listings may provide interesting insights into similarities and differences between the US and European Airbnb markets.

Lastly, we exclude spatial data and thus did not consider the spatial relationship between the listing’s location and their price. A future study could consider this element, building on the original findings by Gyódi and Nawaro, and collect more data from across the globe in order to make a model suitable for both interpretability and predictions.
Appendix

Table 1: List of attributes and their descriptions

<img width="468" alt="Screenshot 2024-07-23 at 10 23 55 PM" src="https://github.com/user-attachments/assets/663e2953-68c2-49b4-a6f0-7ef9be30280e">

Table 2: Table of Model Selection Criteria for Transformed First-Order and Interaction Models

<img width="614" alt="Screenshot 2024-07-23 at 10 24 35 PM" src="https://github.com/user-attachments/assets/e1ec788a-78dc-4fae-b178-3458de4fbae0">

Table 3: Final Model Summary Output

<img width="420" alt="Screenshot 2024-07-23 at 10 25 00 PM" src="https://github.com/user-attachments/assets/ef816524-b971-4cf0-a631-672ca1fc3711">

Figure A. Residual Plots of First-Order and Interaction Models before Transformation

<img width="601" alt="Screenshot 2024-07-23 at 10 25 14 PM" src="https://github.com/user-attachments/assets/1ab31f01-c3d6-488d-88bc-1b8f4be33e1c">

Figure B: Box Cox Transformation on First-order (left) and Interaction Model (right)

<img width="579" alt="Screenshot 2024-07-23 at 10 25 27 PM" src="https://github.com/user-attachments/assets/19f2347a-cf59-43a5-9936-bede245adf45">

Figure C. Residual Plots of Transformed First-Order and interaction Models

<img width="598" alt="Screenshot 2024-07-23 at 10 25 40 PM" src="https://github.com/user-attachments/assets/1f0780a9-36f0-4362-91a5-f9c9ddda7b84">

Figure D. Model Diagnostics Plots for Transformed First-Order model

<img width="563" alt="Screenshot 2024-07-23 at 10 25 53 PM" src="https://github.com/user-attachments/assets/e4d4bf92-726e-4483-8512-1d5dfec8cfa3">

Figure E. Model Diagnostics After Removing Outliers for Transformed First-Order Model

<img width="511" alt="Screenshot 2024-07-23 at 10 26 03 PM" src="https://github.com/user-attachments/assets/595cc450-ae2c-476e-b1d9-3529fdee8fb1">

References
[1] Gyódi, Kristóf and Łukasz Nawaro. (2023, February). Airbnb Prices in European Cities, Version 2. Retrieved November 29, 2023 from https://www.kaggle.com/datasets/thedevastator/airbnb-prices-in-european-cities/data.
[2] Gyódi, Kristóf and Łukasz Nawaro. “Determinants of Airbnb prices in European cities: A spatial econometrics approach.” Tourism Management, Volume 86, 2021, 104319, https://doi.org/10.1016/j.tourman.2021.104319.
[3] “How Pricing Works - Airbnb Help Center.” Airbnb, www.airbnb.com/help/article/125. Accessed 14 Dec. 2023.
