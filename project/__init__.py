from flask import Flask
from werkzeug.security import generate_password_hash, check_password_hash
import pymysql
import os
from dotenv import load_dotenv

load_dotenv()

app = Flask(__name__)
app.secret_key = "Library-super-secret-key"

def get_db():
    return pymysql.connect(
        host=os.getenv("DB_HOST", "localhost"),
        user=os.getenv("DB_USER", "root"),
        password=os.getenv("DB_PASSWORD", ""),
        database=os.getenv("DB_NAME", "yarning_collections"),
        cursorclass=pymysql.cursors.DictCursor
    )

# # These are hard coded passwords for the moment kept in place of the actual database
# # that we will be taking hashed passwords and roles from eventually.
# users = {
#     "admin": {"password": generate_password_hash("123"), "role": "admin"},
#     "elder1": {"password": generate_password_hash("123"), "role": "community_elder"},
#     "staff1": {"password": generate_password_hash("123"), "role": "library_staff"},
#     "public1": {"password": generate_password_hash("123"), "role": "public"}
    
# }

#This must stay at the bottom to avoid circular import errors
from project import routes