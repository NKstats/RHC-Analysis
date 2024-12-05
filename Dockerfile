FROM rocker/rstudio:4.4.2
ARG linux_user_pwd
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    software-properties-common dirmngr gnupg curl && \
    curl -fsSL https://cloud.r-project.org/bin/linux/ubuntu/marutter_pubkey.asc | \
    gpg --dearmor -o /etc/apt/trusted.gpg.d/cran.gpg && \
    add-apt-repository "deb https://cloud.r-project.org/bin/linux/ubuntu $(lsb_release -cs)-cran40/" && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
    r-base r-base-dev \
    python3 python3-pip python3-dev libzmq3-dev libhdf5-dev libblas-dev liblapack-dev libstdc++6 && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    echo "rstudio:${linux_user_pwd}" | chpasswd

RUN pip3 install --break-system-packages \
    numpy pandas matplotlib seaborn scikit-learn jupyter jupyterlab shap xgboost

RUN R -e "install.packages(c('IRkernel'), repos='https://cloud.r-project.org')"
RUN R -e "IRkernel::installspec(user = FALSE)"
RUN R -e "install.packages(c('tinytex', 'Hmisc', 'tidyverse', 'haven', 'cobalt', 'marginaleffects', \
    'pacman', 'rmarkdown', 'patchwork', 'survey', 'tableone', 'survival', 'survminer', 'ggsurvfit'))"

RUN R -e "tinytex::install_tinytex()"

EXPOSE 8787 8888
WORKDIR /home/rstudio

CMD ["/bin/bash", "-c", "rstudio-server start && jupyter lab --ip=0.0.0.0 --port=8888 --no-browser --allow-root --NotebookApp.token=''"]