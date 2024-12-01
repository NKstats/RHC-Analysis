suppressMessages(library(tidyverse))
suppressMessages(library(cobalt))
suppressMessages(library(survey))
suppressMessages(library(marginaleffects))
suppressMessages(library(ggpubr))
suppressMessages(library(cowplot))


data <- suppressMessages(read_csv("data/weighted_data.csv"))

design <- svydesign(ids = ~1, weights = ~trimmed_weight, data = data)
outcome_model <- svyglm(death~RHC, design = design, family = "quasibinomial")

# ADJUSTED ESTIMATIONS
adjusted_rr <- avg_comparisons(outcome_model, variables = "RHC", 
                               comparison = "lnratioavg", 
                               transform = "exp", wts = "(weights)")

adjusted_rd <- avg_comparisons(outcome_model, variables = "RHC", 
                               comparison = "difference", wts = "(weights)")

adjusted_or <- avg_comparisons(outcome_model, variables = "RHC", 
                               comparison = "lnoravg", 
                               transform = "exp", wts = "(weights)")


# UNADJUSTED ESTIMATIONS
crude_model <- glm(death ~ RHC, family =  "quasibinomial", data = data)

crude_rr <- avg_comparisons(crude_model, variables = "RHC", 
                            comparison = "lnratioavg", transform = "exp")

crude_rd <- avg_comparisons(crude_model, variables = "RHC", 
                            comparison = "difference")

crude_or <- avg_comparisons(crude_model, variables = "RHC", 
                            comparison = "lnoravg", transform = "exp")


results <- tibble(
  " " = c("Risk Ratio", "Risk Difference", "Odds Ratio"),
  Unadjusted = c(
    sprintf("%.3f (%.3f, %.3f)", crude_rr$estimate,
            crude_rr$conf.low, crude_rr$conf.high),
    sprintf("%.3f (%.3f, %.3f)", crude_rd$estimate,
            crude_rd$conf.low, crude_rd$conf.high),
    sprintf("%.3f (%.3f, %.3f)", crude_or$estimate,
            crude_or$conf.low, crude_or$conf.high)
  ),
  Adjusted = c(
    sprintf("%.3f (%.3f, %.3f)", adjusted_rr$estimate,
            adjusted_rr$conf.low, adjusted_rr$conf.high),
    sprintf("%.3f (%.3f, %.3f)", adjusted_rd$estimate,
            adjusted_rd$conf.low, adjusted_rd$conf.high),
    sprintf("%.3f (%.3f, %.3f)", adjusted_or$estimate,
            adjusted_or$conf.low, adjusted_or$conf.high)
  )
)


res <- ggtexttable(results, rows=NULL,
                   theme = ttheme("blank", padding = unit(c(6, 8), "mm"),
                                  tbody.style = tbody_style(fill="white", hjust=1, x=1)))%>%
  tab_add_hline(at.row = 1:2, row.side = "top", linewidth = 1)%>%
  tab_add_hline(at.row = 4, row.side = "bottom", linewidth = 1)

ggsave(filename = "figures/estimates.pdf", plot = res,
       dpi = 300, bg = "transparent", device = "pdf",width = 5,height = 2,)
