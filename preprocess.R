
suppressMessages(library(tidyverse))
suppressMessages(library(Hmisc))

getHdata(rhc)
rhc <- as_tibble(rhc)

var <- c("death", "swang1", "age", "sex", "race", "income", "edu",
         "temp1", "wtkilo1", "sadmdte", "dschdte", "dthdte", "lstctdte",
         "scoma1", "das2d3pc", "ca", "cardiohx", "dementhx", "malighx",
         "immunhx", "liverhx", "psychhx", "chfhx", "renalhx")

cat_vars <- c("cardiohx", "dementhx", "malighx", "immunhx",
              "liverhx", "psychhx", "chfhx", "renalhx",
              "sadmdte", "dschdte", "dthdte", "lstctdte")

data <- rhc %>%
  
  dplyr::select(all_of(var)) %>%
  
  mutate(across(where(~inherits(.,"labelled") | inherits(.,"label")), as.numeric)) %>%
  
  mutate(across(all_of(cat_vars), as.factor)) %>%
  
  mutate(ca = recode(ca, "Metastatic" = "Yes")) %>%
  
  mutate(across(c(sadmdte, dschdte, dthdte, lstctdte), 
                ~ as.Date(as.numeric(as.character(.)), origin = "1960-01-01"))) %>%
  
  # Define the end_date: death date if the patient died, otherwise last contact date
  mutate(end_date = if_else(death == "Yes", dthdte, lstctdte)) %>%
  
  # Calculate time-to-event (in days) from admission to end_date
  mutate(
    time = as.numeric(end_date - sadmdte)
  ) %>%
  
  mutate(across(where(is.factor), droplevels)) %>%
  
  select(-c(sadmdte, dschdte, dthdte, lstctdte, end_date))


data <- data %>%
  mutate(ca = ifelse(ca == "Yes", 1, 0),
         death = ifelse(death == "Yes", 1, 0),
         sex = ifelse(sex == "Female", 1, 0)) %>%
  
  rename(RHC = swang1) %>% mutate(RHC = ifelse(RHC=="RHC", 1, 0))


write_csv(data, "data/RHCsubset.csv")


