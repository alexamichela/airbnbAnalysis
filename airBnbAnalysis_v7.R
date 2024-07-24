### BROOKE PERREAULT AND ALEXA HALIM
### STAT 318 FINAL PROJECT
### LAST UPDATED: 12/8/23

### PACKAGES##
library('usdm')
library("MASS")
##############

#######################################################
################## READ IN DATA #######################
#######################################################

############### ORIGINAL DATA PREP ####################
# read in all of the CSVs and combine them
# files <- list.files(path="dataFiles", pattern=".*\\.csv", full.names=FALSE)
# 
# df1 <- read.csv(paste('dataFiles/',files[1], sep=""), header=TRUE)
# items <- strsplit(files[1], "_")
# day <- strsplit(items[[1]][2], "[.]")[[1]][1]
# city <- items[[1]][1]
# df1$city <- rep(city, nrow(df1))
# df1$day_type <- rep(day, nrow(df1))
# 
# # for loop to generate one data frame with all of the csv files, including two new
# # columns for city and date (weekday or weekend)
# for (i in 2:length(files)) {
#   df <- read.csv(paste('dataFiles/',files[i], sep=""), header=TRUE)
#   items <- strsplit(files[i], "_")
#   day <- strsplit(items[[1]][2], "[.]")[[1]][1]
#   city <- items[[1]][1]
#   df$city <- rep(city, nrow(df))
#   df$day_type <- rep(day, nrow(df))
#   df1 <- rbind(df1, df)
# }
# 
# write.csv(df1, "cleanAirBnbData.csv", row.names=FALSE)
#######################################################

df1 <- read.csv('cleanAirBnbData.csv', header=TRUE)

################################################
############# DATA CLEANING ####################
################################################

# check for missing values
summary(df1)
table(df1$city)
table(df1$day_type)
table(df1$room_private)
table(df1$room_shared)
table(df1$room_type)
table(df1$multi)
table(df1$biz)

# remove ID and geospatial data
df1 <- df1[,-c(1, 19, 20 )] 
# remove non-normalized indexes
df1 <- df1[,-c(14,16)]

# Existence of Multicollinearity
vifstep(df1[,-c(1, 2, 3, 4, 6, 7, 8,16,17)], th=10) # NO MULTICOLLINEARITY ISSUE

# LINEAR DEPENDENCY: note that room_type, room_shared, room_private are perfectly linearly dependent because they share the same information. Thus, we just keep room_type
df1 <- df1[,-c(3,4)]

# Final dimensions
dim(df1)

#################################################################
##################### MODEL SELECTION ###########################
#################################################################
# Model Selection - Automatic Stepwise procedure

lm.full <- lm(realSum~., data=df1) # full model
    
# AIC criterion
step(lm.full,trace=0, k=2)
lm.AIC <- lm(realSum ~ room_type + person_capacity + multi + 
               biz + cleanliness_rating + guest_satisfaction_overall + bedrooms + 
               metro_dist + attr_index_norm + city + day_type, data = df1)
  
# BIC criterion
step(lm.full,trace=0, k=log(nrow(df1)))
lm.BIC <- lm(realSum ~ room_type + person_capacity + multi + 
               biz + guest_satisfaction_overall + bedrooms + metro_dist + 
               attr_index_norm + city, data = df1)

##################
# MODEL COMPARISON
##################
# 10-fold Cross validation
set.seed(193)
n <- nrow(df1)
K <- 10 # 10-fold CV

n.shuffle <- sample(1:n, n, replace=FALSE) # shuffle the n indexes
id.cv <- list()
id.cv[[1]] <- n.shuffle[1:5171]
id.cv[[2]] <- n.shuffle[5172:10342]
id.cv[[3]] <- n.shuffle[10343:15513]
id.cv[[4]] <- n.shuffle[15514:20684]
id.cv[[5]] <- n.shuffle[20685:25855]
id.cv[[6]] <- n.shuffle[25856:30855]
id.cv[[7]] <- n.shuffle[30856:36026]
id.cv[[8]] <- n.shuffle[36037:41196]
id.cv[[9]] <- n.shuffle[41197:46367]
id.cv[[10]] <- n.shuffle[46367:51707]

CV.scoreAIC <- 0
CV.scoreBIC <- 0
for (i in 1:K) {
  # fit the model based on the data excluding the ith fold
  fitAIC <- lm(realSum ~ room_type + person_capacity + multi + 
                 biz + cleanliness_rating + guest_satisfaction_overall + bedrooms + 
                 metro_dist + attr_index_norm + city + day_type, data = df1[-id.cv[[i]],])
  fitBIC <- lm(realSum ~ room_type + person_capacity + multi + 
                 biz + guest_satisfaction_overall + bedrooms + metro_dist + 
                 attr_index_norm + city, data = df1[-id.cv[[i]],])
  # make prediction on each observation in the ith fold
  predAIC <- predict(fitAIC, newdata=df1[id.cv[[i]],])
  predBIC <- predict(fitBIC, newdata=df1[id.cv[[i]],])
  # compute average squared error for the ith fold
  CV.scoreAIC <- CV.scoreAIC + (1/n) * sum((df1$realSum[id.cv[[i]]]-predAIC)^2)
  CV.scoreBIC <- CV.scoreBIC + (1/n) * sum((df1$realSum[id.cv[[i]]]-predBIC)^2)
}
# square root CV scores to see on original scale (euros)
sqrt(CV.scoreAIC) # 285.7253
sqrt(CV.scoreBIC) # 285.7554

# Additional comparison criteria
AIC(lm.AIC) # 731540.3
AIC(lm.BIC) # 731551.4
BIC(lm.AIC) # 731735.1
BIC(lm.BIC) # 731728.5

summary(lm.AIC)$adj.r.squared # 0.2413644
summary(lm.BIC)$adj.r.squared # 0.2411725

# We can see that there is little practical difference in the difference in CV scores.
# Thus, we will go with the smaller model, which is the BIC model.

##########################################################
############### INTERACTION TERMS ########################
##########################################################
# We will use stepwise procedure with BIC criterion to find best interaction model, starting from the best first order model
step(lm.BIC,.~.^2, direction='both', k=log(nrow(df1)), trace=0)

lm.BIC.i <- lm(realSum ~ room_type + person_capacity + biz + guest_satisfaction_overall + 
                 bedrooms + metro_dist + attr_index_norm + city + bedrooms:attr_index_norm + 
                 person_capacity:city + room_type:city + attr_index_norm:city + 
                 person_capacity:bedrooms + bedrooms:city + guest_satisfaction_overall:bedrooms + 
                 guest_satisfaction_overall:attr_index_norm + room_type:attr_index_norm + 
                 room_type:biz + biz:city, data = df1)

##########################################################################
########## MODEL COMPARISON - FIRST ORDER MODEL AND INTERACTION MODEL
##########################################################################
# Cross Validation to compare the interaction model and the best first-order model
  # k-fold
n <- nrow(df1)
K <- 10 # 10-fold CV

# Use same folds as before

CV.scoreBIC <- 0
CV.scoreBIC.i <- 0
for (i in 1:K) {
  # fit the model based on the data excluding the ith fold
  fitBIC <- lm(realSum ~ room_type + person_capacity + multi + 
                 biz + guest_satisfaction_overall + bedrooms + metro_dist + 
                 attr_index_norm + city, data = df1[-id.cv[[i]],])
  fitBIC.i <- lm(realSum~room_type + person_capacity + biz + guest_satisfaction_overall + 
                   bedrooms + metro_dist + attr_index_norm + city + bedrooms:attr_index_norm + 
                   person_capacity:city + room_type:city + attr_index_norm:city + 
                   person_capacity:bedrooms + bedrooms:city + guest_satisfaction_overall:bedrooms + 
                   guest_satisfaction_overall:attr_index_norm + room_type:attr_index_norm + 
                   room_type:biz + biz:city, data = df1[-id.cv[[i]],])
  # make prediction on each observation in the ith fold
  predBIC <- predict(fitBIC, newdata=df1[id.cv[[i]],])
  predBIC.i <- predict(fitBIC.i, newdata=df1[id.cv[[i]],])
  # compute average squared error for the ith fold
  CV.scoreBIC <- CV.scoreBIC + (1/n) * sum((df1$realSum[id.cv[[i]]]-predBIC)^2)
  CV.scoreBIC.i <- CV.scoreBIC.i + (1/n) * sum((df1$realSum[id.cv[[i]]]-predBIC.i)^2)
}
CV.scoreBIC # 81656.15
CV.scoreBIC.i # 74645.17
# square root CV scores to see on original scale (euros)
sqrt(CV.scoreBIC)
sqrt(CV.scoreBIC.i)
# CV.scoreBIC: 81656.15 squared euros or 285.7554 euros
# CV.scoreBIC.i: 74645.17 squared euros or 273.2127 euros
# There is a difference in 12 euros. Adding ~15 interaction terms only made a difference 
# in 12 euros, thus there is little practical difference in the difference in CV scores.

# ADDITIONAL COMPARISON CRITERIA
AIC(lm.BIC.i) # 726721.3
BIC(lm.BIC.i) # 727438.4
summary(lm.BIC.i)
summary(lm.BIC.i)$adj.r.squared # 0.3096609

# Interaction model is slightly better (lower AIC, BIC, CV, and higher AdjR2), but it is quite complex. Before deciding on a model, let's check the residual plots.

##########################################################################
########## RESIDUAL PLOTS AND POWER TRANSFORMATION FOR BEST MODELS #######
##########################################################################

# FIRST ORDER MODEL
plot(resid(lm.BIC)~fitted(lm.BIC), main="First Order Model") # cone-shaped so power transformation
bcobj<-boxcox(lm.BIC)
lambda <- bcobj$x[which.max(bcobj$y)] # lambda value is -0.3030303

# INTERACTION MODEL
plot(resid(lm.BIC.i)~fitted(lm.BIC.i), main="Interaction Model")
bc.int <- boxcox(lm.BIC.i) # boxcox transformation on interaction model
lambda.int <- bc.int$x[which.max(bc.int$y)] # lambda value is -0.2626263

# since we cannot compare the two models unless the powers used in the transformation are the same, we will round the lambda values to -0.3 to apply the same transformation and compare
shared.lambda <- -0.3
lm.transformed.first <- lm(-(realSum)^shared.lambda ~ room_type + person_capacity + multi + 
                biz + guest_satisfaction_overall + bedrooms + metro_dist + 
                attr_index_norm + city, data = df1)
# RESIDUAL PLOT AFTER TRANSFORMATION
plot(resid(lm.transformed.first)~fitted(lm.transformed.first), main="Transformed First Order Model")
# better constant variance

AIC(lm.transformed.first) # -258528.4
BIC(lm.transformed.first) # -258351.4
summary(lm.transformed.first)$adj.r.squared # 0.6593307

lm.transformed.interaction <- lm(-(realSum)^(shared.lambda) ~ room_type + person_capacity + 
                                   biz + guest_satisfaction_overall + bedrooms + metro_dist + 
                                   attr_index_norm + city + bedrooms:attr_index_norm + person_capacity:city + 
                                   room_type:city + attr_index_norm:city + person_capacity:bedrooms + 
                                   bedrooms:city + guest_satisfaction_overall:bedrooms + guest_satisfaction_overall:attr_index_norm + 
                                   room_type:attr_index_norm + room_type:biz + biz:city, data = df1)

# RESIDUAL PLOT AFTER TRANSFORMATION
plot(resid(lm.transformed.interaction)~fitted(lm.transformed.interaction), main="Transformed Interaction Model")

AIC(lm.transformed.interaction) # -263071.7
BIC(lm.transformed.interaction) # -262354.6
summary(lm.transformed.interaction)$adj.r.squared # 0.6883539

############################################
### CROSS VALIDATION WITH TRANSFORMED MODELS
############################################
df.trans <- df1
df.trans$realSum <- (df1$realSum)^shared.lambda
cv.first <- 0
CV.int <- 0
for (i in 1:K) {
  # fit the model based on the data excluding the ith fold
  fitBIC <- lm(-(realSum)^shared.lambda ~ room_type + person_capacity + 
                 multi + biz + guest_satisfaction_overall + bedrooms + metro_dist + attr_index_norm + city, data = df.trans[-id.cv[[i]],])
  fitBIC.i <- lm(-(realSum)^(shared.lambda) ~ room_type + person_capacity + 
                   biz + guest_satisfaction_overall + bedrooms + metro_dist + 
                   attr_index_norm + city + bedrooms:attr_index_norm + person_capacity:city + 
                   room_type:city + attr_index_norm:city + person_capacity:bedrooms + 
                   bedrooms:city + guest_satisfaction_overall:bedrooms + guest_satisfaction_overall:attr_index_norm + 
                   room_type:attr_index_norm + room_type:biz + biz:city, data = df.trans[-id.cv[[i]],])
  # make prediction on each observation in the ith fold
  predBIC <- predict(fitBIC, newdata=df1[id.cv[[i]],])
  predBIC.i <- predict(fitBIC.i, newdata=df1[id.cv[[i]],])
  # compute average squared error for the ith fold
  cv.first<- cv.first + (1/n) * sum((df.trans$realSum[id.cv[[i]]]-predBIC)^2)
  CV.int <- CV.int + (1/n) * sum((df.trans$realSum[id.cv[[i]]]-predBIC.i)^2)
}

cv.first # 3.353726
CV.int # 3.353888
sqrt(cv.first)^(1/shared.lambda)  # CV score on original scale (euros) # 0.1330824
sqrt(CV.int)^(1/shared.lambda) # CV score on original scale (euros) # 0.1330717


# We will pick the first order model. The differences in evaluation criteria do not justify the more complex interaction model, especially for our research questions (which focus on interpretability).

###################################################
################ MODEL DIAGNOSTICS ################
###################################################
qqnorm(resid(lm.transformed.first))
qqline(resid(lm.transformed.first))
# Normality assumption not entirely met. Data is may be skewed or with heavy tails.

plot(resid(lm.transformed.first), main="Time Sequence Plot")
# there is no pattern in this plot


## CHECKING FOR OUTLIERS WITH STUDENTIZED DELETED RESIDUALS #############
p <- length(coef(lm.transformed.first))
sdr <- rstudent(lm.transformed.first)
pct.25 <- qt(0.025, df=n-p-1)
pct.975 <- qt(0.975, df=n-p-1)
out.id <- which(sdr<pct.25 | sdr>pct.975)
length(out.id)

# There are 2643 outliers with respect to y. Let's check if they are influential
cooks.dist <- cooks.distance(lm.transformed.first)
f.pct.50 <- qf(.50, df1=p, df2=n-p) # 50th percentile of F distribution
length(which(cooks.dist>=f.pct.50))

# There are no influential observations, but removing outliers improves model fit greatly, so we will do that.

lm.last <- lm(-(realSum)^shared.lambda ~ room_type + person_capacity + multi + 
                biz + guest_satisfaction_overall + bedrooms + metro_dist + 
                attr_index_norm + city, data = df1[-out.id, ])

# Residual plot and QQNorm plot after removing outliers
plot(resid(lm.last)~fitted(lm.last), main="Residual plot after removing outliers")
qqnorm(resid(lm.last))
qqline(resid(lm.last))

# INTERPRETING COEFS for research question
summary(lm.last)
# because of the applied power transformation, we cannot directly interpret the 
# coefficients, but we can look at the direction of association because we maintained
# direction of the response.
# person_capacity, multi, biz, guest_satisfaction_overall, bedrooms,
# attr_index_norm have a positive association with price
# compared to the baseline of Amsterdam, all the other cities have a negative 
# association with the price, which means that they are less expensive than Amsterdam
# compared to the baseline of entire home/apt, a room type of a private room or 
# shared room has a negative association with price, which makes sense.
# metro_dist has a negative association with price, which makes sense.



