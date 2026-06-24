from flask import render_template, session, redirect, url_for, request
from werkzeug.security import check_password_hash, generate_password_hash
from functools import wraps
from project import app
from project.models import (
    get_user_by_email,
    create_user,
    get_all_items,
    get_item_with_metadata,
    get_all_assessments,
    get_assessment_details,
    get_discussion_comments,
    get_assessment_decision,
)

# =====================================================
# AUTH DECORATORS
# =====================================================

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
                return render_template(
                    "error.html",
                    error_code=403,
                    message="Access denied"
                ), 403
            return route_function(*args, **kwargs)
        return wrapper
    return decorator


# =====================================================
# HOME PAGE
# =====================================================

@app.route("/")
def home():
    items = get_all_items()
    return render_template("index.html", items=items, user=session.get("user"))


# =====================================================
# ITEM DETAILS
# =====================================================

@app.route("/item/<int:item_id>")
def item(item_id):
    item_data = get_item_with_metadata(item_id)

    if item_data is None:
        return render_template(
            "error.html",
            error_code=404,
            message="Item not found"
        ), 404

    # Restricted access check
    if item_data["access_status"] == "Restricted":
        if session.get("role") not in ("Admin", "Elder", "Staff"):
            return render_template(
                "error.html",
                error_code=403,
                message="Access denied"
            ), 403

    return render_template("item.html", item=item_data)


# =====================================================
# ASSESSMENT LIST
# =====================================================

@app.route("/assessment")
@login_required
@role_required("Admin", "Elder", "Staff")
def assessment():
    assessments = get_all_assessments()
    return render_template("assessment_list.html", assessments=assessments)


# =====================================================
# ASSESSMENT DETAILS
# =====================================================

@app.route("/assessment/<int:assessment_id>", methods=["GET", "POST"])
@login_required
@role_required("Admin", "Elder", "Staff")
def assessment_details(assessment_id):
    assessment = get_assessment_details(assessment_id)

    if assessment is None:
        return render_template(
            "error.html",
            error_code=404,
            message="Assessment not found"
        ), 404

    comments = get_discussion_comments(assessment_id)
    decision = get_assessment_decision(assessment_id)

    return render_template(
        "assessment_detail.html",
        assessment=assessment,
        comments=comments,
        decision=decision,
        role=session.get("role")
    )


# =====================================================
# LOGIN
# =====================================================

@app.route("/login", methods=["GET", "POST"])
def login():
    if request.method == "POST":
        email = request.form.get("email", "").lower().strip()
        password = request.form.get("password", "").strip()

        user = get_user_by_email(email)

        if user and check_password_hash(user["password_hash"], password):
            session["user_id"] = user["id"]
            session["user"] = user["first_name"]
            session["role"] = user["role_name"]

            next_page = session.pop("next", None)
            return redirect(next_page or url_for("home"))

        return render_template("login.html", error="Invalid login details")

    return render_template("login.html")


# =====================================================
# REGISTER
# =====================================================

@app.route("/register", methods=["GET", "POST"])
def register():
    if request.method == "POST":
        first_name = request.form.get("first_name", "").strip()
        last_name = request.form.get("last_name", "").strip()
        email = request.form.get("email", "").strip().lower()
        password = request.form.get("password", "").strip()
        confirm_password = request.form.get("confirm_password", "").strip()

        if not all([first_name, last_name, email, password]):
            return render_template("register.html", error="Please fill all fields")

        if password != confirm_password:
            return render_template("register.html", error="Passwords do not match")

        # Check if user exists
        existing = get_user_by_email(email)
        if existing:
            return render_template("register.html", error="Email already registered")

        create_user(first_name, last_name, email, generate_password_hash(password))
        return redirect(url_for("login"))

    return render_template("register.html")


# =====================================================
# LOGOUT
# =====================================================

@app.route("/logout")
def logout():
    session.clear()
    return redirect(url_for("home"))


# =====================================================
# ERROR HANDLERS
# =====================================================

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


@app.route("/test500")
def test500():
    raise Exception("This is a test error")
