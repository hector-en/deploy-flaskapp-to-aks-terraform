import pyodbc
import urllib.parse

server = "aicore-devops-project-server.database.windows.net"
database = "orders-db"
username = "maya"
password = "AiCore1237"

# URL-encode password
encoded_password = urllib.parse.quote_plus(password)

# Construct connection string
connection_string = (
    f"mssql+pyodbc://{username}:{encoded_password}@{server}/{database}"
    "?driver=ODBC+Driver+18+for+SQL+Server&Encrypt=yes&TrustServerCertificate=yes"
)

# Direct pyodbc test
pyodbc_conn_str = f"""
    DRIVER={{ODBC Driver 18 for SQL Server}};
    SERVER={server};
    DATABASE={database};
    UID={username};
    PWD={password};
    Encrypt=yes;
    TrustServerCertificate=yes;
    Connection Timeout=30;
"""

print("🔍 Connecting to database...")

try:
    conn = pyodbc.connect(pyodbc_conn_str)
    cursor = conn.cursor()
    cursor.execute("SELECT @@VERSION")
    version = cursor.fetchone()
    print("✅ Connection successful! SQL Server version:", version)
    conn.close()
except Exception as e:
    print(f"❌ Failed to connect: {e}")
