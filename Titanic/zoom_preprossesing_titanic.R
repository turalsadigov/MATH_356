# load libraries
library(readr)
library(tidyverse)
library(caret)
install.packages('Amelia')
library(Amelia)


# import datasets
titanic <- read_csv('train.csv')
test_titanic <- read_csv('test.csv')

# dig into data
str(titanic)
dplyr::glimpse(titanic)
Amelia::missmap(titanic)
Amelia::missmap(test_titanic)
summary(titanic)

# make those changes
titanic <- titanic %>% 
  select(-c(PassengerId, Name, Ticket, Cabin)) %>% 
  mutate(Survived = as.factor(Survived)) %>% 
  mutate(Sex = as.factor(Sex)) %>% 
  mutate(Pclass = as.factor(Pclass)) %>% 
  mutate(Embarked = as.factor(Embarked))

# dig into data
dplyr::glimpse(titanic)
summary(titanic)


# fill embarked
embarked <- titanic$Embarked
missing_indices <- is.na(embarked)
which(is.na(embarked))
titanic$Embarked[missing_indices] <- 'S'

Amelia::missmap(titanic)

# fill age variable: lazy imputation
mu_tilde_age_train <- median(titanic$Age, na.rm = T)
missing_indices <- is.na(titanic$Age)
titanic$Age[missing_indices] <- mu_tilde_age_train

# dig data again
Amelia::missmap(titanic)
summary(titanic)


# combine siblings, parents together
titanic <- titanic %>% 
  mutate(Travelers = SibSp + Parch + 1) %>% 
  select(-c(SibSp, Parch))

# TIDY data
View(titanic)

# ==== clean testing data correctly
# make those changes
test_titanic <- test_titanic %>% 
  select(-c(PassengerId, Name, Ticket, Cabin)) %>% 
  mutate(Sex = as.factor(Sex)) %>% 
  mutate(Pclass = as.factor(Pclass)) %>% 
  mutate(Embarked = as.factor(Embarked)) %>% 
  mutate(Travelers = SibSp + Parch + 1) %>% 
  select(-c(SibSp, Parch))

summary(test_titanic)

# fill single missing 
which(is.na(test_titanic$Fare))
test_titanic$Fare[153] <- median(titanic$Fare)
summary(test_titanic)

# fill age
missing_indices <- is.na(test_titanic$Age)
test_titanic$Age[missing_indices] <- mu_tilde_age_train


# dig back into testing data
summary(test_titanic)
missmap(test_titanic)
