from project import get_db

# =====================================================
# USERS
# =====================================================

def get_user_by_email(email):
    db = get_db()
    cursor = db.cursor()
    cursor.execute("""
        SELECT u.*, r.role_name
        FROM users u
        JOIN roles r ON u.role_id = r.id
        WHERE u.email = %s AND u.is_active = 1
    """, (email,))
    return cursor.fetchone()


def create_user(first_name, last_name, email, password_hash):
    db = get_db()
    cursor = db.cursor()
    cursor.execute("""
        INSERT INTO users (first_name, last_name, email, password_hash, role_id)
        VALUES (%s, %s, %s, %s, 4)
    """, (first_name, last_name, email, password_hash))
    db.commit()


# =====================================================
# ITEMS + CATEGORIES + CULTURAL METADATA
# =====================================================

def get_all_items():
    db = get_db()
    cursor = db.cursor()
    cursor.execute("""
        SELECT i.id, i.title, i.description, i.access_status, i.image,
               c.name AS category_name,
               cm.cultural_group, cm.sensitivity_level
        FROM items i
        JOIN categories c ON i.category_id = c.id
        JOIN cultural_metadata cm ON cm.item_id = i.id
        ORDER BY i.title ASC
    """)
    return cursor.fetchall()


def get_item_with_metadata(item_id):
    db = get_db()
    cursor = db.cursor()
    cursor.execute("""
        SELECT i.*, 
               c.name AS category_name,
               cm.cultural_group, cm.sensitivity_level,
               cm.cultural_notes, cm.access_conditions,
               cm.review_status, cm.last_reviewed_at, cm.last_reviewed_by
        FROM items i
        JOIN categories c ON i.category_id = c.id
        JOIN cultural_metadata cm ON cm.item_id = i.id
        WHERE i.id = %s
    """, (item_id,))
    return cursor.fetchone()


# =====================================================
# ASSESSMENTS
# =====================================================

def get_all_assessments():
    db = get_db()
    cursor = db.cursor()
    cursor.execute("""
        SELECT a.id, a.status, a.date_initiated,
               i.title AS item_title, i.access_status,
               u.first_name, u.last_name
        FROM assessments a
        JOIN items i ON a.item_id = i.id
        JOIN users u ON a.initiated_by = u.id
        ORDER BY FIELD(a.status, 'In Progress', 'Completed'),
                 a.date_initiated DESC
    """)
    return cursor.fetchall()


def get_assessment_details(assessment_id):
    db = get_db()
    cursor = db.cursor()
    cursor.execute("""
        SELECT a.*, 
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
    return cursor.fetchone()


# =====================================================
# DISCUSSIONS
# =====================================================

def get_discussion_comments(assessment_id):
    db = get_db()
    cursor = db.cursor()
    cursor.execute("""
        SELECT d.comment, d.date_posted,
               u.first_name, u.last_name,
               r.role_name
        FROM discussions d
        JOIN users u ON d.user_id = u.id
        JOIN roles r ON u.role_id = r.id
        WHERE d.assessment_id = %s
        ORDER BY d.date_posted ASC
    """, (assessment_id,))
    return cursor.fetchall()


def add_discussion_comment(assessment_id, user_id, comment):
    db = get_db()
    cursor = db.cursor()
    cursor.execute("""
        INSERT INTO discussions (assessment_id, user_id, comment)
        VALUES (%s, %s, %s)
    """, (assessment_id, user_id, comment))
    db.commit()


# =====================================================
# DECISIONS
# =====================================================

def get_assessment_decision(assessment_id):
    db = get_db()
    cursor = db.cursor()
    cursor.execute("""
        SELECT dec.*, u.first_name, u.last_name
        FROM decisions dec
        JOIN users u ON dec.user_id = u.id
        WHERE dec.assessment_id = %s
    """, (assessment_id,))
    return cursor.fetchone()


def add_assessment_decision(assessment_id, user_id, outcome, rationale):
    db = get_db()
    cursor = db.cursor()
    cursor.execute("""
        INSERT INTO decisions (assessment_id, user_id, outcome, rationale)
        VALUES (%s, %s, %s, %s)
    """, (assessment_id, user_id, outcome, rationale))
    db.commit()


# =====================================================
# ACCESS REQUESTS
# =====================================================

def create_access_request(item_id, requester_user_id, name, email, reason):
    db = get_db()
    cursor = db.cursor()
    cursor.execute("""
        INSERT INTO access_requests 
            (item_id, requester_user_id, requester_name, requester_email, reason)
        VALUES (%s, %s, %s, %s, %s)
    """, (item_id, requester_user_id, name, email, reason))
    db.commit()


def get_access_requests_for_item(item_id):
    db = get_db()
    cursor = db.cursor()
    cursor.execute("""
        SELECT *
        FROM access_requests
        WHERE item_id = %s
        ORDER BY date_requested DESC
    """, (item_id,))
    return cursor.fetchall()


def review_access_request(request_id, reviewer_id, status, note):
    db = get_db()
    cursor = db.cursor()
    cursor.execute("""
        UPDATE access_requests
        SET status = %s,
            reviewed_by = %s,
            reviewed_at = NOW(),
            review_note = %s
        WHERE id = %s
    """, (status, reviewer_id, note, request_id))
    db.commit()
