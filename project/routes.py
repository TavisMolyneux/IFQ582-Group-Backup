from flask import render_template, session, redirect, url_for, request
from werkzeug.security import check_password_hash, generate_password_hash
from functools import wraps
from enum import Enum
from project import app, users






class AccessStatus(Enum):
    PUBLIC = "public"
    RESTRICTED = "restricted"
    PENDING = "pending"


# These are hardcoded item details, not for final submission. need integration to the item DB
_items = {
    1: {"title": "Bush Tucker Guide", "content": "...", "accessStatus": AccessStatus.PUBLIC},
    2: {"title": "Sacred Site Photographs", "content": "...", "accessStatus": AccessStatus.RESTRICTED},
}

def get_item(item_id):
    return _items.get(item_id)

def get_all_items():
    return _items.values()

def login_required(route_function):
    
    @wraps(route_function)
    def wrapper(*args, **kwargs):

        if "user" not in session:
            session["next"] = request.path
            return redirect("/login")
        
        return route_function(*args, **kwargs)
    
    return wrapper

def role_required(*roles):

    def decorator(route_function):

        @wraps(route_function)
        def wrapper(*args, **kwargs):

            if session.get("role") not in roles:
                return render_template("error.html", error_code = 403, message = "Access denied"), 403
           
            
            return route_function(*args, **kwargs)
    
        return wrapper
    
    return decorator


            

@app.route("/")
def home():
    user = session.get("user")
    return render_template("index.html", user=user)


@app.route("/item/<int:item_id>")
def item(item_id):
    item_data = _items.get(item_id)

    if item_data is None:
        return render_template("error.html", error_code=404, message="Item not found"), 404

    # accessStatus here will need to be updated to whatever we call it in our DB
    if item_data["accessStatus"] == AccessStatus.RESTRICTED:
        if session.get("role") not in ("admin", "community_elder"):
            return render_template("error.html", error_code=403, message="Access denied"), 403

    return render_template("item.html", item=item_data)

@app.route("/assessment")
@login_required
@role_required("admin","community_elder","library_staff")
def assessment():
 
    return render_template("assessment.html")

@app.route("/login", methods=["GET", "POST"])
def login():
    if request.method == "POST":
        username = request.form.get("username","").lower().strip()
        password = request.form.get("password", "").strip()

        user = users.get(username)

        if user and check_password_hash(user["password"], password):
            session["user"] = username
            session["role"] = user["role"]

            next_page = session.pop("next", None)
            if next_page:
                return redirect(next_page)

            return redirect(url_for("home"))

        return render_template("login.html", error="Invalid login details")

    return render_template("login.html")

@app.route("/register", methods=["GET", "POST"])
def register():
    if request.method == "POST":
        username = request.form.get("username", "").strip().lower()
        password = request.form.get("password", "").strip()
        confirm_password = request.form.get("confirm_password", "").strip()

        if not username or  not password:
            return render_template("register.html", error="Username or password empty, please fill all fields")

        
        if len(username) < 5 or len(username) >15:
            return render_template("register.html", error="Username must be between 5 and 15 characters")
        
        if username in users:
            return render_template("register.html", error="Username already exists")

        if password != confirm_password:
            return render_template("register.html", error="Passwords do not match")

        users[username] = {
            "password": generate_password_hash(password),
            "role": "public"
        }

        return redirect(url_for("login"))

    return render_template("register.html")



@app.route("/logout")
def logout():
    session.clear()
    return redirect(url_for("home"))

@app.errorhandler(404)
def page_not_found(error):

    return render_template(
        "error.html",
        error_code=404,
        message="Page not found"
    ), 404

@app.errorhandler(500)
def internal_error(error):

    return render_template(
        "error.html",
        error_code=500,
        message="Something went wrong"
    ), 500

# This test page is just used to confirm that error_code 500
#  is handled correctly by deliberately causing an error
@app.route("/test500")
def test500():
    raise Exception("This is a test error")



