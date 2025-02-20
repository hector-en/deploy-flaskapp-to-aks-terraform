# Step 1 - Use an official Python runtime as a parent image. You can use `python:3.8-slim`.
FROM python:3.8-slim-buster
# Step 2 - Set the working directory in the container
WORKDIR /app
# Step 3 Copy the application files in the container
COPY . /app
# Install system dependencies and ODBC driver 
RUN if grep -q 'VERSION_ID="22.04"' /etc/os-release; then \
    apt-get update && apt-get install -y \
    unixodbc unixodbc-dev odbcinst odbcinst1debian2 libpq-dev gcc && \
    curl -sS https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor | tee /etc/apt/trusted.gpg.d/mssql.gpg > /dev/null && \
    curl https://packages.microsoft.com/config/ubuntu/22.04/prod.list > /etc/apt/sources.list.d/mssql-release.list && \
    sudo apt-get update && \
    ACCEPT_EULA=Y sudo apt-get install -y msodbcsql18; \
else \
    apt-get update && apt-get install -y \
    unixodbc unixodbc-dev odbcinst odbcinst1debian2 libpq-dev gcc && \
    apt-get install -y gnupg && \
    apt-get install -y wget && \
    wget -qO- https://packages.microsoft.com/keys/microsoft.asc | apt-key add - && \
    wget -qO- https://packages.microsoft.com/config/debian/10/prod.list > /etc/apt/sources.list.d/mssql-release.list && \
    apt-get update && \
    ACCEPT_EULA=Y apt-get install -y msodbcsql18 && \
    apt-get purge -y --auto-remove wget && \  
    apt-get clean; \
fi

# Install pip and setuptools
RUN pip install --upgrade pip setuptools

# Step 4 - Install Python packages specified in requirements.txt
RUN pip install --trusted-host pypi.python.org -r requirements.txt

# Step 5 - Expose port 
EXPOSE 5000

# Step 6 - Define Startup Command
CMD ["python", "app.py", "--host=0.0.0.0", "--port=5000"]