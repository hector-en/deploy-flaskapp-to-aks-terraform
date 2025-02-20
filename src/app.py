from flask import Flask, render_template, request, redirect, url_for
from sqlalchemy import create_engine, Column, Integer, String, DateTime
from sqlalchemy.orm import sessionmaker
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy import create_engine
import os # to read Secrets from Kubernetes
import urllib.parse

# Initialise Flask App
app = Flask(__name__)

# Function to read Kubernetes-mounted secrets
def get_k8s_secret(secret_name, default_value=None):
    """Retrieve secrets from Kubernetes (or fallback to env variables)."""
    secret_path = f"/mnt/secrets/{secret_name}"
    try:
        with open(secret_path, "r") as secret_file:
            return secret_file.read().strip()
    except FileNotFoundError:
        return os.getenv(secret_name, default_value)

# Read database credentials securely
DB_SERVER = get_k8s_secret("DB_SERVER")
DB_DATABASE = get_k8s_secret("DB_DATABASE")
DB_USERNAME = get_k8s_secret("DB_USERNAME")
DB_PASSWORD = get_k8s_secret("DB_PASSWORD")

# URL-encode password for security
encoded_password = urllib.parse.quote_plus(DB_PASSWORD)

# Create SQLAlchemy connection string
connection_string = (
    f"mssql+pyodbc://{DB_USERNAME}:{encoded_password}@{DB_SERVER}/{DB_DATABASE}"
    "?driver=ODBC+Driver+18+for+SQL+Server&Encrypt=yes&TrustServerCertificate=yes"
)

# Create the engine to connect to the database
engine = create_engine(connection_string)

# Test the database connection
try:
    with engine.connect() as conn:
        print("✅ Database connection successful!")
except Exception as e:
    print(f"❌ Database connection failed: {e}")

# Create a session factory
Session = sessionmaker(bind=engine)

# Define the Order data model
Base = declarative_base()

class Order(Base):
    __tablename__ = 'orders'
    date_uuid = Column('date_uuid', String, primary_key=True)
    user_id = Column('User ID', String, primary_key=True)
    card_number = Column('Card Number', String)
    store_code = Column('Store Code', String)
    product_code = Column('product_code', String)
    product_quantity = Column('Product Quantity', Integer)
    order_date = Column('Order Date', DateTime)
    shipping_date = Column('Shipping Date', DateTime)

# define routes
# route to display orders
@app.route('/')
def display_orders():

    page = int(request.args.get('page', 1))
    rows_per_page = 25

    # Calculate the start and end indices for the current page
    start_index = (page - 1) * rows_per_page
    end_index = start_index + rows_per_page

    # Create a session to interact with the database
    session = Session()

    # Fetch a subset of data for the current page
    current_page_orders = session.query(Order).order_by(Order.user_id, Order.date_uuid).slice(start_index, end_index).all()

    # Calculate the total number of pages
    total_rows = session.query(Order).count()
    total_pages = (total_rows + rows_per_page - 1) // rows_per_page

    # Close the session
    session.close()

    return render_template('orders.html', orders=current_page_orders, page=page, total_pages=total_pages)

# route to add orders
@app.route('/add_order', methods=['POST'])
def add_order():
    date_uuid = request.form.get('date_uuid')
    user_id = request.form.get('user_id')
    card_number = request.form.get('card_number')
    store_code = request.form.get('store_code')
    product_code = request.form.get('product_code')
    product_quantity = request.form.get('product_quantity')
    order_date = request.form.get('order_date')
    shipping_date = request.form.get('shipping_date')
    
    # Create a session to interact with the database
    session = Session()

    # Create a new order object using the form data
    new_order = Order(
        date_uuid=date_uuid,
        user_id=user_id,
        card_number=card_number,
        store_code=store_code,
        product_code=product_code,
        product_quantity=product_quantity,
        order_date=order_date,
        shipping_date=shipping_date
    )

    # Add the new order to the session and commit to the database
    session.add(new_order)
    session.commit()

    return redirect(url_for('display_orders'))

# run the app
if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)
