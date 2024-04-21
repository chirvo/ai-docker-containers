# Define a base image argument
FROM selenium/standalone-chrome:latest

RUN apt-get update && \
  apt-get install -y curl software-properties-common && \
  curl -sL https://deb.nodesource.com/setup_20.x | sudo -E bash - && \
  apt-get install -y nodejs && \
  apt-get install -y python3 python3-pip python3-venv && \
  rm -rf /var/lib/apt/lists/*

WORKDIR /home/seluser
RUN python3 -m venv venv
ENV PATH="/home/seluser/venv/bin:$PATH"
RUN pip install --upgrade pip
RUN pip install selenium webdriver-manager selenium_stealth
WORKDIR /

EXPOSE 4444