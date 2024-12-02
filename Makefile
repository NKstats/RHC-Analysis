.PHONY: clean

clean:
	rm -rf figures
	rm -rf data
	rm -rf .created-dirs
	rm -f Summary.pdf
	rm -f Report.pdf

.created-dirs:
	echo "Creating directories..."
	mkdir -p figures
	mkdir -p data
	touch .created-dirs

data/RHCsubset.csv: .created-dirs preprocess.R
	Rscript preprocess.R

figures/descriptive.pdf: data/RHCsubset.csv descriptive.R
	Rscript descriptive.R

figures/psplot.pdf figures/balplot.pdf data/weighted_data.csv: \
data/RHCsubset.csv \
IPW.R
	Rscript IPW.R

figures/roc_curve.pdf figures/shap1.pdf figures/shap2.pdf: \
data/RHCsubset.csv \
SHAP_analysis.ipynb
	python3 -m jupyter nbconvert --to notebook \
	--execute SHAP_analysis.ipynb --output figures/shap.pdf

figures/survplot.pdf figures/HRestimates.pdf: \
data/weighted_data.csv \
SurvivalAnalysis.R
	Rscript SurvivalAnalysis.R

figures/estimates.pdf: \
data/weighted_data.csv \
Effect_Estimations.R
	Rscript Effect_Estimations.R

Summary.pdf: \
figures/psplot.pdf \
figures/balplot.pdf \
figures/survplot.pdf \
figures/roc_curve.pdf figures/shap1.pdf figures/shap2.pdf \
Summary.Rmd
	Rscript -e \
	"rmarkdown::render('Summary.Rmd', output_format='pdf_document', quiet = T)"

Report.pdf: \
figures/descriptive.pdf \
figures/psplot.pdf \
figures/balplot.pdf \
figures/estimates.pdf \
figures/survplot.pdf \
figures/HRestimates.pdf \
figures/roc_curve.pdf figures/shap1.pdf figures/shap2.pdf \
Report.Rmd
	Rscript -e \
	"rmarkdown::render('Report.Rmd', output_format='pdf_document', quiet = T)"