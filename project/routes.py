from flask import render_template, session, redirect, url_for, request
from werkzeug.security import check_password_hash, generate_password_hash
from functools import wraps
from project import app, get_db






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
    conn = get_db()
    cursor = conn.cursor()
    cursor.execute("""
        SELECT i.id, i.title, i.description, i.access_status, i.image,
            c.name AS category_name,
            cm.cultural_group, cm.sensitivity_level
        FROM items i
        JOIN categories c ON i.category_id = c.id
        JOIN cultural_metadata cm ON cm.item_id = i.id
    """)
    items = cursor.fetchall()
    conn.close()
    
    return render_template("index.html", items=items, user=session.get("user"))


@app.route("/item/<int:item_id>")
def item(item_id):
    conn = get_db()
    cursor = conn.cursor()
    cursor.execute("""
        SELECT i.*, c.name as category_name,
            cm.cultural_group, cm.sensitivity_level,
            cm.cultural_notes, cm.access_conditions
        FROM items i
        JOIN categories c ON i.category_id = c.id
        JOIN cultural_metadata cm ON cm.item_id = i.id
        WHERE i.id = %s
    """, (item_id,))
    item_data = cursor.fetchone()
    conn.close()

    if item_data is None:
        return render_template("error.html", error_code = 404, message="Item not found"), 404

    if item_data["access_status"] == "Restricted":
        if session.get("role") not in ("Admin", "Elder", "Staff"):
            return render_template("error.html", error_code = 403, message="Access denied"), 403

    return render_template("item.html", item=item_data)

@app.route("/assessment")
@login_required
@role_required("Admin","Elder","Staff")
def assessment():
    conn = get_db()
    cursor = conn.cursor()
    try:
        cursor.execute("""
            SELECT
                a.id,
                a.status,
                a.date_initiated,
                i.title AS item_title,
                i.access_status,
                u.first_name,
                u.last_name
            FROM assessments a
            JOIN items i ON a.item_id = i.id
            JOIN users u ON a.initiated_by = u.id
            ORDER BY FIELD(a.status, 'In Progress', 'Completed'), a.date_initiated DESC
        """)
        assessments = cursor.fetchall()
        return render_template("assessment_list", assessments=assessments)
   
    finally:
        conn.close()

@app.route("/assessment/<int:assessment_id>", methods=["GET", "POST"])
@login_required
@role_required("Admin","Elder","Staff")
def assessment_details(assessment_id):
    conn = get_db()
    cursor = conn.cursor()
    try:
        cursor.execute("""
            SELECT
                a.id, a.status, a.date_initiated,
                i.id AS item_id, i.title, i.description,
                i.access_status, i.format, i.image,
                cm.cultural_group, cm.sensitivity_level, cm.cultural_notes,
                u.first_name, u.last_name
            FROM assessments a
            JOIN items i ON a.item_id = i.id
            JOIN cultural_metadata cm ON cm.item_id = i.id
            JOIN users u ON a.initiated_by = u.id
            WHERE a.id = %s
        """, (assessment_id,))
        assessment = cursor.fetchone()     

        if assessment is None:
            return render_template("error.html", error_code=404, message = "Assessment not found"), 404

        cursor.execute("""
            SELECT
                d.comment, d.date_posted,
                u.first_name, u.last_name,
                r.role_name
            FROM discussions d
            JOIN users u ON d.user_id = u.id
            JOIN roles r ON u.role_id = r.id
            WHERE d.assessment_id = %s
            ORDER BY d.date_posted ASC
        """, (assessment_id,))
        comments = cursor.fetchall()

        cursor.execute("""
            SELECT
                dec.outcome, dec.rationale, dec.date_decided,
                u.first_name, u.last_name
            FROM decisions dec
            JOIN users u ON dec.user_id = u.id
            WHERE dec.assessments_id = %s
        """, (assessment_id,))
        decision = cursor.fetchone()

        return render_template("assessment_detail.html",
                               assessment = assessment,
                               comments = comments,
                               decision = decision,
                               role=session.get("role"))

    finally:
        conn.close()



@app.route("/login", methods=["GET", "POST"])
def login():
    if request.method == "POST":
        email = request.form.get("email","").lower().strip()
        password = request.form.get("password", "").strip()


        conn = get_db()
        cursor = conn.cursor()
        cursor.execute("""
            SELECT u.id, u.first_name, u.email, u.password_hash, r.role_name
            FROM users u
            JOIN roles r ON u.role_id = r.id
            WHERE u.email = %s AND u.is_active = 1
        """, (email,))
        user = cursor.fetchone()
        conn.close()

        if user and check_password_hash(user["password_hash"], password):
            session["user_id"] = user["id"]
            session["user"] = user["first_name"]
            session["role"] = user["role_name"]

            next_page = session.pop("next", None)
            if next_page:
                return redirect(next_page)

            return redirect(url_for("home"))

        return render_template("login.html", error="Invalid login details")

    return render_template("login.html")

@app.route("/register", methods=["GET", "POST"])
def register():
    if request.method == "POST":
        first_name = request.form.get("first_name","").strip()
        last_name = request.form.get("last_name","").strip()
        email = request.form.get("email", "").strip().lower()
        password = request.form.get("password", "").strip()
        confirm_password = request.form.get("confirm_password", "").strip()

        if not email or not password or not first_name or not last_name:
            return render_template("register.html", error="Username or password empty, please fill all fields")

        if password != confirm_password:
            return render_template("register.html", error="Passwords do not match")
        

        
        conn = get_db()
        cursor = conn.cursor()

        cursor.execute("SELECT id FROM users WHERE email = %s", (email,))
        if cursor.fetchone():
            conn.close()
            return render_template("register.html", error="An account with that email already exists")
        

        # registration defaults users to role_id= 4 
        # new users are always public 
        cursor.execute("""
            INSERT INTO users (first_name, last_name, email, password_hash, role_id)
            VALUES (%s, %s, %s, %s, 4)  
        """, (first_name, last_name, email, generate_password_hash(password)))

        conn.commit()
        conn.close()


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



