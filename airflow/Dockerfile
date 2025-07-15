FROM apache/airflow:2.10.3

# Install additional Python packages
COPY requirements.txt /
RUN pip install --no-cache-dir -r /requirements.txt

# Install system dependencies for data processing
USER root
RUN apt-get update \
  && apt-get install -y --no-install-recommends \
         wget \
         curl \
         unzip \
  && apt-get autoremove -yqq --purge \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

USER airflow

# Copy custom plugins and scripts
COPY plugins/ /opt/airflow/plugins/
COPY scripts/ /opt/airflow/scripts/
