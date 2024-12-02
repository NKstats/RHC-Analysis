
suppressMessages(library(tidyverse))
suppressMessages(library(pacman))
suppressMessages(p_load(tableone))
suppressMessages(library(cobalt))
library(knitr)
library(ggpubr)

data <- suppressMessages(read_csv("data/RHCsubset.csv"))

covars <- setdiff(colnames(data), c("death", "RHC", "time"))
exposure <- "RHC"

data$death <- as.factor(as.numeric(as.factor(data$death)) - 1)
data$RHC <- as.factor(as.numeric(as.factor(data$RHC)) - 1)

formula <- as.formula(paste(exposure, "~", paste(covars, collapse = " + ")))
ps_model <- glm(formula, family = binomial(link = "logit"), data = data)
data$ps <- predict(ps_model, type = "response")


# Calculate IPTW weights
data$ipw <- ifelse(data$RHC == 1, 1/data$ps, 1/(1 - data$ps))

# Trim weights at the 1st and 99th percentiles
trim_limits <- quantile(data$ipw, c(0.01, 0.99))
data$trimmed_weight <- pmin(pmax(data$ipw, trim_limits[1]), trim_limits[2])


data1 <- data %>%
  mutate(RHC = factor(RHC, labels = c("No RHC", "RHC")))

density.p <- ggdensity(data1, x = "ps", fill = "RHC", palette = c("#E7B800", "#2E9FDF")) +
  labs(x = "Propensity Scores",fill = "Exposure") +
  theme_classic()+
  theme(legend.position = "inside",
        legend.position.inside =  c(.89, .85),
        legend.background = element_rect(color = "grey", fill = "white"),
        legend.title = element_text(size = 25),
        legend.text = element_text(size = 25),
        legend.key.size = unit(1, "cm"),
        axis.title.x = element_text(size = 30, margin = margin(t = 20)),
        axis.title.y = element_text(size = 30, margin = margin(r = 20)),
        axis.text = element_text(size = 25),
        strip.text = element_text(size = 25),
        plot.title = element_text(size = 35,hjust=0,margin = margin(b = 15)),
        plot.margin = margin(0,0,0,0))

ggsave(filename = "figures/psplot.pdf", plot = density.p, device = "pdf",
       dpi = 300, width = 15.5, height = 13, units = "in")



label <- data.frame(
  old = c(
    "age", "sex", "race_black", "race_other", "race_white",
    "income_> $50k", "income_$11-$25k", "income_$25-$50k", "income_Under $11k",
    "edu", "temp1", "wtkilo1", "scoma1", "das2d3pc", "ca", "cardiohx",
    "dementhx", "malighx", "immunhx", "liverhx", "psychhx", "chfhx", "renalhx"),
  new = c(
    "Age", "Female", "Black", "Other Race", "White", "Income > $50k",
    "Income $11k-$25k", "Income $25k-$50k", "Income Under $11k",
    "Years of Education", "Temperature", "Weight (Kg)","Glasgow Coma Score",
    "DAS Index", "Cancer", "Cardiovascular Conditions",
    "Neurological Comorbidities", "Malignancies", "Immunosuppression",
    "Liver Disease", "Psychiatric Conditions", "Congestive Heart Failure",
    "Renal Conditions")
)

p <- love.plot(formula, weights = data$trimmed_weight,
               data = data, 
               method = "weighting",
               thresholds = c(m = 0.1),
               abs = FALSE, 
               shapes = c("circle filled","triangle filled"),
               colors = c("red", "blue"), 
               e.names = c("Original", "Weighted (IPW)"),
               size = 7, 
               binary = "std", 
               continuous = "std", 
               s.d.denom = "pooled",
               var.names = label)


p <- p + scale_shape_manual(values = c(4, 2)) + 
  theme(legend.position = "inside",
        legend.position.inside =  c(.89, .93),
        legend.background = element_rect(color = "grey", fill = "white"),
        legend.title = element_text(size = 25),
        legend.text = element_text(size = 25),
        legend.key.size = unit(1, "cm"),
        axis.title.x = element_text(size = 30, margin = margin(t = 20)),
        axis.text = element_text(size = 25),
        strip.text = element_text(size = 25),
        plot.margin = margin(0,0,0,0))+
  labs(title="")


ggsave(filename = "figures/balplot.pdf", plot = p, device = "pdf", 
       dpi = 300, width = 15.5, height = 13, units = "in")

write_csv(data, "data/weighted_data.csv")
