suppressMessages(library(tidyverse))
suppressMessages(library(tableone))
suppressMessages(library(ggpubr))

data <- suppressMessages(read_csv("data/RHCsubset.csv"))

data <- data %>%
  mutate(RHC = factor(RHC, labels = c("No RHC", "RHC"))) %>%
  mutate(sex = factor(sex, labels = c("Male", "Female")))

data <- data %>%
  mutate(across(where(~ all(.x %in% c(0, 1))), as.factor))

label <- data.frame(
  old = names(data),
  new = c(
    "Death", "RHC", "Age", "Sex", "Race", "Income",
    "Years of Education", "Temperature", "Weight","Glasgow Coma Score",
    "DAS Index", "Cancer", "Cardiovascular Conditions",
    "Neurological Comorbidities", "Malignancies", "Immunosuppression",
    "Liver Disease", "Psychiatric Conditions", "Congestive Heart Failure",
    "Renal Conditions", "time")
)

rename_map <- setNames(label$new, label$old)
data <- data %>%
  rename_with(~ rename_map[.x], .cols = names(rename_map))

covars <- setdiff(colnames(data), c("Death", "RHC", "time"))
exposure <- "RHC"

tabUnmatched <- CreateTableOne(vars = covars, strata = exposure, 
                               data = data, test = FALSE,addOverall = TRUE)

df <- as.data.frame(print(tabUnmatched, smd = TRUE))

df <- ggtexttable(df, 
                  theme = ttheme("blank", padding = unit(c(8, 8), "mm"),
                                 tbody.style = tbody_style(fill="white", 
                                                           fontface = "plain",
                                                           hjust=1, x=1,size = 12,),
                                 rownames.style = rownames_style(
                                   color = "black",
                                   face = "plain"
                                 ),
                                 colnames.style = colnames_style(
                                   hjust=0,
                                   fill="white")))%>%
  tab_add_hline(at.row = 3, row.side = "top", linewidth = 1)%>%
  tab_add_hline(at.row = 1, row.side = "top", linewidth = 1)%>%
  tab_add_hline(at.row = 27, row.side = "bottom", linewidth = 1)

ggsave(filename = "figures/descriptive.pdf",
       plot = df, dpi = 300, bg = "transparent", 
       device = "pdf",width = 9,height = 12)

