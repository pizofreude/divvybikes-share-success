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

# Install AWS CLI v2
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" \
  && unzip awscliv2.zip \
  && ./aws/install \
  && rm -rf awscliv2.zip aws/

USER airflow

# Copy custom plugins and scripts
COPY plugins/ /opt/airflow/plugins/
COPY scripts/ /opt/airflow/scripts/
