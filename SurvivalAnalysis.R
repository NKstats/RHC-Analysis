suppressMessages(library(tidyverse))
suppressMessages(library(survival))
suppressMessages(library(survminer))
suppressMessages(library(ggsurvfit))
suppressMessages(library(patchwork))
suppressMessages(library(cowplot))


data <- suppressMessages(read_csv("data/weighted_data.csv"))
covars <- setdiff(colnames(data), c("death", "RHC", "time", 
                                    "ps", "ipw", "trimmed_weight"))

surv_object <- Surv(time = data$time, event = data$death)
km_model <- survfit(surv_object ~ RHC, data=data,weights = data$trimmed_weight)

cox_unadjusted <- coxph(Surv(time, death) ~ RHC, data = data)
cox_summary_unadjusted <- summary(cox_unadjusted)

cox_formula_adjusted <- as.formula(paste("Surv(time, death) ~ RHC +", 
                                         paste(covars, collapse = " + ")))

cox_adjusted <- coxph(cox_formula_adjusted, data = data, weights = trimmed_weight)
cox_summary_adjusted <- summary(cox_adjusted)


hr1 <- round(cox_summary_unadjusted$coefficients[,"exp(coef)"],3)[1]
ci1 <- round(cox_summary_unadjusted$conf.int[,"lower .95"], 3)[1]
cu1 <- round(cox_summary_unadjusted$conf.int[,"upper .95"], 3)[1]

hr2 <- round(cox_summary_adjusted$coefficients[,"exp(coef)"],2)[1]
ci2 <- round(cox_summary_adjusted$conf.int[,"lower .95"], 2)[1]
cu2 <- round(cox_summary_adjusted$conf.int[,"upper .95"], 2)[1]

cox1 <- paste0("HR (unadj.): ", hr1, " (95% CI: ",ci1, "-",cu1, ")")
cox2 <- paste0("HR: ", hr2, " (95% CI: ",ci2, "-",cu2, ")")

surv_plot <- ggsurvplot(
  km_model,
  data = data,
  conf.int = TRUE,
  pval = FALSE,
  ggtheme = theme_classic() +
    theme(
      axis.title.x = element_text(size = 25, margin = margin(t = 20)),
      axis.title.y = element_text(size = 25, margin = margin(r = 20)),
      axis.text.x = element_text(size = 25),
      axis.text.y = element_text(size = 25),
      legend.title = element_text(size = 25),
      legend.text = element_text(size = 25),
      text = element_text(size = 20),
      legend.key.size = unit(1, "cm")
    ),
  conf.int.style = "step",#"ribbon"
  conf.int.alpha = 0.3,
  conf.int.size = 1.2,
  legend.title = "Exposure",
  legend.labs = c("No RHC", "RHC"),
  risk.table = TRUE,
  risk.table.col = "strata",
  risk.table.y.text.col=FALSE,
  palette = c("#E7B800", "#2E9FDF"),
  ylab = "Survival Probability",
  xlab = "Time (months)",
  xscale="d_m",
  tables.height = 3,
  break.time.by = 300,
  fontsize = 9,
  size = 1.5,
  legend="top"
)

surv_plot$table <- surv_plot$table + labs(y = NULL) +
  theme(
    legend.position = "none",
    axis.text = element_text(size = 20),
    axis.title = element_text(size = 15),
    axis.text.y = element_blank(),
    axis.ticks.y = element_blank(),
    axis.title.x = element_text(size=25)
  )

surv_plot$plot <- surv_plot$plot + 
  annotate("text",x=0, y=0.07,label=cox2,size = 8,hjust = 0)

cp <- surv_plot$plot/surv_plot$table + plot_layout(heights = c(3, 1))

ggsave(filename = "figures/survplot.pdf", plot = cp, device = "pdf", 
       dpi = 300, width = 14, height = 12, units = "in")



format_ci <- function(lower, upper) {return(paste0("(", lower, ", ", upper, ")"))}

rhc_unadjusted <- data.frame(
  Model = "Unadjusted",
  HR = round(cox_summary_unadjusted$coefficients["RHC", "exp(coef)"], 3),
  CI_95 = format_ci(
    round(cox_summary_unadjusted$conf.int["RHC", "lower .95"], 3),
    round(cox_summary_unadjusted$conf.int["RHC", "upper .95"], 3)
  ))

rhc_adjusted <- data.frame(
  Model = "Adjusted",
  HR = round(cox_summary_adjusted$coefficients["RHC", "exp(coef)"], 3),
  CI_95 = format_ci(
    round(cox_summary_adjusted$conf.int["RHC", "lower .95"], 3),
    round(cox_summary_adjusted$conf.int["RHC", "upper .95"], 3)
  ))

rhc_summary <- rbind(rhc_unadjusted, rhc_adjusted)
rhc_summary <- rhc_summary %>% rename(`95% C.I`= CI_95)


df <- ggtexttable(rhc_summary, rows=NULL,
                  theme = ttheme("blank", padding = unit(c(8, 6), "mm"),
                                 tbody.style = tbody_style(fill="white", 
                                                           fontface = "plain",
                                                           hjust=1, x=1,size = 12,),
                                 rownames.style = rownames_style(
                                   color = "black", face = "plain"),
                                 colnames.style = colnames_style(
                                   hjust=0, fill="white")))%>%
  tab_add_hline(at.row = 1:2, row.side = "top", linewidth = 1)%>%
  tab_add_hline(at.row = 3, row.side = "bottom", linewidth = 1)

ggsave(filename = "figures/HRestimates.pdf", plot = df, dpi = 300, 
       bg = "transparent", device = "pdf",width =3.4,height = 1.1)


