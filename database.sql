DROP DATABASE IF EXISTS yarning_collections;
CREATE DATABASE yarning_collections;
USE yarning_collections;

SET FOREIGN_KEY_CHECKS = 0;

DROP TABLE IF EXISTS decisions;
DROP TABLE IF EXISTS discussions;
DROP TABLE IF EXISTS assessments;
DROP TABLE IF EXISTS access_requests;
DROP TABLE IF EXISTS cultural_metadata;
DROP TABLE IF EXISTS items;
DROP TABLE IF EXISTS categories;
DROP TABLE IF EXISTS users;
DROP TABLE IF EXISTS roles;

SET FOREIGN_KEY_CHECKS = 1;

-- =====================================================
-- 1. Roles
-- =====================================================
CREATE TABLE roles (
    id INT AUTO_INCREMENT PRIMARY KEY,
    role_name VARCHAR(50) NOT NULL UNIQUE,
    description VARCHAR(255) NOT NULL
);

INSERT INTO roles (id, role_name, description) VALUES
(1, 'Admin', 'Full system access including user role assignment, item management, access request management and review decisions.'),
(2, 'Elder', 'Community Reviewer/Elder with permission to review items, add comments, update cultural metadata and approve or reject access.'),
(3, 'Staff', 'Library Staff with permission to create and edit collection items, upload metadata and view access requests.'),
(4, 'Public', 'Public User who can browse public items, view details and submit access requests for restricted materials.');

-- =====================================================
-- 2. Users
-- =====================================================
CREATE TABLE users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    email VARCHAR(255) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    role_id INT NOT NULL,
    is_active TINYINT(1) NOT NULL DEFAULT 1,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_users_role
        FOREIGN KEY (role_id) REFERENCES roles(id)
        ON UPDATE CASCADE ON DELETE RESTRICT
);

INSERT INTO users (id, first_name, last_name, email, password_hash, role_id, is_active) VALUES
(1, 'David', 'Patel', 'd.patel@nikl.edu.au', 'scrypt:32768:8:1$kbWvKuLkhk83R7Wd$60c255fc0b7b510f1329b32c112557d57eb23d1f2a0d8bc14cd7134bfe63ca486bcd3f1bdd4ee79d89261c567193a879e6acf01b367f35d2a48de95bd153524c', 1, 1),
(2, 'Uncle Jim', 'Mooney', 'j.mooney@community.org.au', 'scrypt:32768:8:1$KSOWDyn2ZnSBfCy5$35cab6f6c5716b4157b8e6fbc79f89ee5676343efcac34f185f49847e7a8aaef5b73158d5e5764e4d10303592c80d19a8ad49761c7263a5f45a2f91d49daf3e3', 2, 1),
(3, 'Aunty May', 'Williams', 'm.williams@community.org.au', 'scrypt:32768:8:1$KSOWDyn2ZnSBfCy5$35cab6f6c5716b4157b8e6fbc79f89ee5676343efcac34f185f49847e7a8aaef5b73158d5e5764e4d10303592c80d19a8ad49761c7263a5f45a2f91d49daf3e3', 2, 1),
(4, 'Sarah', 'Mitchell', 's.mitchell@nikl.edu.au', 'scrypt:32768:8:1$0cON1rsUagrcbRRN$4f29b66431033f06839d47e0b4fe8ed047ff228cb7117550b8c69090f5126ec9ab9c90280bdb32ddbbd6a6182119e0e9c9a0f273ac0da2973e520e0252f0ce57', 3, 1),
(5, 'Connor', 'Reid', 'c.reid@nikl.edu.au', 'scrypt:32768:8:1$0cON1rsUagrcbRRN$4f29b66431033f06839d47e0b4fe8ed047ff228cb7117550b8c69090f5126ec9ab9c90280bdb32ddbbd6a6182119e0e9c9a0f273ac0da2973e520e0252f0ce57', 3, 1),
(6, 'Emily', 'Chen', 'e.chen@research.edu.au', 'scrypt:32768:8:1$CT8VwWHuoVZVmKLu$288fc9aab4a672221fefb982384568a02fa976840b644f0729715c2660f40e95ad429b14dd27cf52cbf7ff4dcdf9aaa3b0d686dd60646165e70f6d0b76a6ab9d', 4, 1),
(7, 'James', 'Park', 'j.park@uni.edu.au', 'scrypt:32768:8:1$CT8VwWHuoVZVmKLu$288fc9aab4a672221fefb982384568a02fa976840b644f0729715c2660f40e95ad429b14dd27cf52cbf7ff4dcdf9aaa3b0d686dd60646165e70f6d0b76a6ab9d', 4, 1),
(8, 'Leah', 'Brown', 'leah.brown@student.edu.au', 'scrypt:32768:8:1$CT8VwWHuoVZVmKLu$288fc9aab4a672221fefb982384568a02fa976840b644f0729715c2660f40e95ad429b14dd27cf52cbf7ff4dcdf9aaa3b0d686dd60646165e70f6d0b76a6ab9d', 4, 1);

-- =====================================================
-- 3. Categories
-- =====================================================
CREATE TABLE categories (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE,
    description VARCHAR(255) NOT NULL
);

INSERT INTO categories (id, name, description) VALUES
(1, 'Historical Photograph', 'Digitised photographs documenting people, places and events.'),
(2, 'Oral History Audio', 'Audio recordings of interviews, oral histories and ceremonial content.'),
(3, 'Archival Document', 'Letters, manuscripts, field notes and historical written records.'),
(4, 'Artwork', 'Paintings, prints and visual artworks created by Indigenous artists.'),
(5, 'Cultural Artefact Record', 'Catalogue records describing physical artefacts held by the library.'),
(6, 'Language Preservation Material', 'Dictionaries, lesson cards, recordings and language resources.');

-- =====================================================
-- 4. Items
-- =====================================================
CREATE TABLE items (
    id INT AUTO_INCREMENT PRIMARY KEY,
    category_id INT NOT NULL,
    title VARCHAR(255) NOT NULL,
    description TEXT NOT NULL,
    image VARCHAR(255) NULL,
    format VARCHAR(150) NOT NULL,
    dimensions VARCHAR(150) NOT NULL,
    physical_location VARCHAR(255) NOT NULL,
    date_added DATE NOT NULL,
    access_status ENUM('Public', 'Restricted', 'Under Review') NOT NULL DEFAULT 'Under Review',
    created_by INT NOT NULL,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_items_category
        FOREIGN KEY (category_id) REFERENCES categories(id)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_items_created_by
        FOREIGN KEY (created_by) REFERENCES users(id)
        ON UPDATE CASCADE ON DELETE RESTRICT
);

INSERT INTO items (id, category_id, title, description, image, format, dimensions, physical_location, date_added, access_status, created_by) VALUES
(1, 4, 'Dreaming Story Scroll', 'A hand-painted scroll depicting a creation narrative from the Wiradjuri people and used in community education programs.', 'dreaming_scroll.jpg', 'Hand-painted scroll (digitised photograph)', '120cm x 45cm', 'Special Collections — Room 3, Cabinet B', '2026-01-15', 'Public', 4),
(2, 2, 'Ceremony Song Recording', 'Audio recording of a ceremonial song from the Yolŋu community containing sacred cultural content.', 'ceremony_song.mp3', 'Audio recording (digital WAV file)', 'N/A', 'Digital Archive — Server DA-02', '2026-02-20', 'Restricted', 4),
(3, 4, 'Bark Painting Collection', 'Series of bark paintings from Arnhem Land artists depicting seasonal knowledge and land management practices.', 'bark_painting.jpg', 'Bark painting (digitised photograph)', '85cm x 60cm (each)', 'Special Collections — Room 5, Cabinet A', '2026-03-10', 'Under Review', 5),
(4, 1, 'Riverbank Gathering Photograph', 'Digitised photograph showing a community gathering on Country near the riverbank during the 1950s.', 'riverbank_photo.jpg', 'Historical photograph (digitised scan)', '18cm x 24cm (original print)', 'Photograph Archive — Drawer 12', '2026-01-28', 'Public', 4),
(5, 3, 'Field Notebook of Language Terms', 'Notebook containing handwritten vocabulary and community language terms collected during language revitalisation work.', 'language_notebook.jpg', 'Archival notebook (digitised scan)', 'A5 notebook', 'Manuscript Archive — Shelf 2B', '2026-02-02', 'Restricted', 5),
(6, 6, 'Beginner Language Flashcards', 'Set of illustrated language cards designed for community-based language learning sessions.', 'flashcards.jpg', 'Learning cards (digitised PDF)', 'A6 cards', 'Digital Archive — Language Resources', '2026-02-14', 'Public', 4),
(7, 5, 'Stone Tool Record', 'Catalogue record documenting provenance, material, handling notes and community guidance for a stone tool artefact.', 'stone_tool.jpg', 'Artefact record (catalogue entry)', 'N/A', 'Artefact Store — Bay 4', '2026-02-18', 'Restricted', 5),
(8, 1, 'Mission School Group Portrait', 'Class portrait from a mission school with contextual notes about names, place and consent status.', 'school_portrait.jpg', 'Historical photograph (digitised scan)', '20cm x 25cm (original print)', 'Photograph Archive — Drawer 14', '2026-02-26', 'Public', 4),
(9, 2, 'Oral History Interview with Aunty Elsie', 'Recorded oral history interview discussing family history, work, movement and memory across Country.', 'elsie_interview.mp3', 'Audio recording (MP3)', 'N/A', 'Digital Archive — Oral Histories', '2026-03-02', 'Public', 5),
(10, 3, 'Community Council Letter 1978', 'Formal letter between a community council and the university regarding custody and access to archival materials.', 'council_letter.pdf', 'Digitised document (PDF)', 'A4 letter', 'Document Archive — Box 9', '2026-03-08', 'Restricted', 4),
(11, 4, 'Ochre Landscape Painting', 'Painting representing seasonal change, water sites and kinship responsibilities in landscape form.', 'ochre_landscape.jpg', 'Painting (digitised photograph)', '90cm x 70cm', 'Art Store — Rack 7', '2026-03-18', 'Public', 5),
(12, 5, 'Ceremonial Object Record', 'Detailed catalogue record for a ceremonial object with handling restrictions and community access notes.', 'ceremonial_object.jpg', 'Artefact record (catalogue entry)', 'N/A', 'Restricted Artefact Store — Bay 1', '2026-03-22', 'Restricted', 4),
(13, 6, 'Children''s Language Songbook', 'Illustrated songbook used in local language lessons for children and early learners.', 'songbook.jpg', 'Songbook (digitised PDF)', 'A4 booklet', 'Digital Archive — Language Resources', '2026-03-28', 'Public', 5),
(14, 1, 'Early Station Homestead Photograph', 'Photograph of an early station homestead including annotations about occupants and place names.', 'homestead_photo.jpg', 'Historical photograph (digitised scan)', '21cm x 29cm (original print)', 'Photograph Archive — Drawer 18', '2026-04-05', 'Under Review', 4),
(15, 3, 'Research Notes on Seasonal Calendar', 'Typed and handwritten notes documenting observations and community input on seasonal indicators.', 'seasonal_notes.pdf', 'Archival document (PDF)', 'A4 document set', 'Document Archive — Box 11', '2026-04-10', 'Under Review', 5),
(16, 2, 'Women''s Gathering Audio Excerpt', 'Audio excerpt from a women''s gathering event with restricted cultural context and community protocols.', 'womens_gathering.wav', 'Audio recording (WAV)', 'N/A', 'Digital Archive — Restricted Audio', '2026-04-14', 'Restricted', 4);

-- =====================================================
-- 5. Cultural Metadata (1:1 with items)
-- =====================================================
CREATE TABLE cultural_metadata (
    id INT AUTO_INCREMENT PRIMARY KEY,
    item_id INT NOT NULL UNIQUE,
    cultural_group VARCHAR(150) NOT NULL,
    sensitivity_level ENUM('Low', 'Medium', 'High') NOT NULL,
    cultural_notes TEXT NOT NULL,
    access_conditions TEXT NOT NULL,
    review_status ENUM('Not Reviewed', 'Under Review', 'Reviewed') NOT NULL DEFAULT 'Not Reviewed',
    last_reviewed_at DATETIME NULL,
    last_reviewed_by INT NULL,
    CONSTRAINT fk_metadata_item
        FOREIGN KEY (item_id) REFERENCES items(id)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_metadata_reviewer
        FOREIGN KEY (last_reviewed_by) REFERENCES users(id)
        ON UPDATE CASCADE ON DELETE SET NULL
);

INSERT INTO cultural_metadata (id, item_id, cultural_group, sensitivity_level, cultural_notes, access_conditions, review_status, last_reviewed_at, last_reviewed_by) VALUES
(1, 1, 'Wiradjuri', 'Low', 'Shared with permission from Wiradjuri elders for educational use.', 'Public viewing permitted.', 'Reviewed', '2026-01-25 10:30:00', 2),
(2, 2, 'Yolŋu', 'High', 'Sacred ceremonial content; not suitable for general distribution.', 'Restricted to approved researchers with community consent.', 'Reviewed', '2026-03-01 15:45:00', 3),
(3, 3, 'Kunwinjku', 'Medium', 'Awaiting elder assessment before access level is determined.', 'Pending assessment.', 'Under Review', NULL, NULL),
(4, 4, 'Ngunnawal', 'Low', 'Photograph cleared for public educational use with contextual information.', 'Public viewing permitted.', 'Reviewed', '2026-02-01 09:00:00', 2),
(5, 5, 'Kaurna', 'High', 'Contains language content requiring community-controlled access.', 'Restricted to approved language revitalisation projects.', 'Reviewed', '2026-02-20 14:00:00', 2),
(6, 6, 'Noongar', 'Low', 'Created for educational language learning sessions.', 'Public viewing permitted.', 'Reviewed', '2026-02-21 11:00:00', 3),
(7, 7, 'Arrernte', 'High', 'Artefact record includes culturally sensitive handling details.', 'Restricted to staff and approved researchers.', 'Reviewed', '2026-03-05 16:20:00', 2),
(8, 8, 'Yorta Yorta', 'Low', 'Community has approved use for family and educational research.', 'Public viewing permitted.', 'Reviewed', '2026-03-07 10:10:00', 3),
(9, 9, 'Gamilaraay', 'Low', 'Interview cleared for public listening with attribution notes.', 'Public listening and study permitted.', 'Reviewed', '2026-03-12 09:35:00', 2),
(10, 10, 'Meriam', 'Medium', 'Correspondence contains governance details; public summary only recommended.', 'Restricted to authenticated users with staff approval.', 'Reviewed', '2026-03-20 13:25:00', 3),
(11, 11, 'Pitjantjatjara', 'Low', 'Artist and community approved public exhibition and educational display.', 'Public viewing permitted.', 'Reviewed', '2026-03-30 12:00:00', 2),
(12, 12, 'Tiwi', 'High', 'Ceremonial object details must not be broadly distributed.', 'Restricted to approved cultural authorities and staff.', 'Reviewed', '2026-04-01 09:15:00', 3),
(13, 13, 'Bundjalung', 'Low', 'Songbook developed for teaching and approved for wide educational access.', 'Public viewing permitted.', 'Reviewed', '2026-04-05 11:45:00', 2),
(14, 14, 'Warlpiri', 'Medium', 'Further consultation required on naming and place detail before release.', 'Under review; no public access yet.', 'Under Review', '2026-04-12 14:30:00', 2),
(15, 15, 'Miriwoong', 'Medium', 'Seasonal notes require contextual review before publication.', 'Under review; no public access yet.', 'Under Review', '2026-04-16 15:00:00', 3),
(16, 16, 'Yolŋu', 'High', 'Women''s gathering content is culturally restricted and requires strict control.', 'Restricted to approved women researchers with community consent.', 'Reviewed', '2026-04-20 10:40:00', 2);

-- =====================================================
-- 6. Assessments
-- =====================================================
CREATE TABLE assessments (
    id INT AUTO_INCREMENT PRIMARY KEY,
    item_id INT NOT NULL,
    initiated_by INT NOT NULL,
    date_initiated DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    status ENUM('In Progress', 'Completed') NOT NULL DEFAULT 'In Progress',
    CONSTRAINT fk_assessment_item
        FOREIGN KEY (item_id) REFERENCES items(id)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_assessment_initiator
        FOREIGN KEY (initiated_by) REFERENCES users(id)
        ON UPDATE CASCADE ON DELETE RESTRICT
);

INSERT INTO assessments (id, item_id, initiated_by, date_initiated, status) VALUES
(1, 1, 4, '2026-01-20 09:00:00', 'Completed'),
(2, 2, 4, '2026-02-25 13:15:00', 'Completed'),
(3, 3, 5, '2026-03-15 10:00:00', 'In Progress'),
(4, 5, 4, '2026-02-18 14:00:00', 'Completed'),
(5, 7, 5, '2026-03-03 09:30:00', 'Completed'),
(6, 14, 4, '2026-04-10 11:20:00', 'In Progress'),
(7, 15, 5, '2026-04-15 08:50:00', 'In Progress'),
(8, 16, 4, '2026-04-18 14:10:00', 'Completed');

-- =====================================================
-- 7. Discussions
-- =====================================================
CREATE TABLE discussions (
    id INT AUTO_INCREMENT PRIMARY KEY,
    assessment_id INT NOT NULL,
    user_id INT NOT NULL,
    comment TEXT NOT NULL,
    date_posted DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_discussion_assessment
        FOREIGN KEY (assessment_id) REFERENCES assessments(id)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_discussion_user
        FOREIGN KEY (user_id) REFERENCES users(id)
        ON UPDATE CASCADE ON DELETE RESTRICT
);

INSERT INTO discussions (id, assessment_id, user_id, comment, date_posted) VALUES
(1, 1, 2, 'This story has been shared publicly at community events. Suitable for public access.', '2026-01-22 09:30:00'),
(2, 1, 3, 'Agreed. The Wiradjuri community has given permission for educational use.', '2026-01-23 10:15:00'),
(3, 2, 3, 'This recording contains sacred content. Access should be restricted to approved researchers only.', '2026-02-27 14:10:00'),
(4, 3, 2, 'I need to consult with the Kunwinjku community before making a determination.', '2026-03-18 11:40:00'),
(5, 3, 3, 'The paintings may be suitable for a limited educational release, but not until naming and context are reviewed.', '2026-03-20 15:00:00'),
(6, 4, 2, 'Language notebook should stay restricted until the community review group approves usage conditions.', '2026-02-19 09:45:00'),
(7, 5, 3, 'Artefact handling details should remain restricted even if summary information is visible to staff.', '2026-03-04 13:25:00'),
(8, 6, 2, 'Photo captions need verification before we decide whether this can be made public.', '2026-04-12 14:45:00'),
(9, 7, 3, 'Seasonal indicators are valuable but require contextual notes from the community before release.', '2026-04-16 16:10:00'),
(10, 8, 2, 'This audio excerpt should remain restricted due to culturally specific women''s content.', '2026-04-19 09:20:00');

-- =====================================================
-- 8. Decisions
-- =====================================================
CREATE TABLE decisions (
    id INT AUTO_INCREMENT PRIMARY KEY,
    assessment_id INT NOT NULL UNIQUE,
    user_id INT NOT NULL,
    outcome ENUM('Approved', 'Rejected') NOT NULL,
    rationale TEXT NOT NULL,
    date_decided DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_decision_assessment
        FOREIGN KEY (assessment_id) REFERENCES assessments(id)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_decision_user
        FOREIGN KEY (user_id) REFERENCES users(id)
        ON UPDATE CASCADE ON DELETE RESTRICT
);

INSERT INTO decisions (id, assessment_id, user_id, outcome, rationale, date_decided) VALUES
(1, 1, 2, 'Approved', 'Elders confirmed this story is appropriate for public sharing for educational purposes.', '2026-01-25 10:30:00'),
(2, 2, 3, 'Rejected', 'Sacred ceremonial content must remain restricted to approved researchers with community consent.', '2026-03-01 15:45:00'),
(3, 4, 2, 'Rejected', 'Notebook contains language content requiring community-controlled access.', '2026-02-20 14:00:00'),
(4, 5, 3, 'Rejected', 'Artefact record includes sensitive handling details and should remain restricted.', '2026-03-05 16:20:00'),
(5, 8, 2, 'Rejected', 'Women''s gathering content requires strict cultural restriction and cannot be publicly released.', '2026-04-20 10:40:00');

-- =====================================================
-- 9. Access Requests
-- =====================================================
CREATE TABLE access_requests (
    id INT AUTO_INCREMENT PRIMARY KEY,
    item_id INT NOT NULL,
    requester_user_id INT NOT NULL,
    requester_name VARCHAR(200) NOT NULL,
    requester_email VARCHAR(255) NOT NULL,
    reason TEXT NOT NULL,
    date_requested DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    status ENUM('Pending', 'Approved', 'Denied') NOT NULL DEFAULT 'Pending',
    reviewed_by INT NULL,
    reviewed_at DATETIME NULL,
    review_note TEXT NULL,
    CONSTRAINT fk_request_item
        FOREIGN KEY (item_id) REFERENCES items(id)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_request_requester
        FOREIGN KEY (requester_user_id) REFERENCES users(id)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_request_reviewer
        FOREIGN KEY (reviewed_by) REFERENCES users(id)
        ON UPDATE CASCADE ON DELETE SET NULL
);

INSERT INTO access_requests (id, item_id, requester_user_id, requester_name, requester_email, reason, date_requested, status, reviewed_by, reviewed_at, review_note) VALUES
(1, 2, 6, 'Emily Chen', 'e.chen@research.edu.au', 'Academic research on Yolŋu ceremonial practices for doctoral thesis.', '2026-03-05 09:15:00', 'Pending', NULL, NULL, NULL),
(2, 2, 7, 'James Park', 'j.park@uni.edu.au', 'Honours thesis on Indigenous music traditions in northern Australia.', '2026-03-12 14:50:00', 'Pending', NULL, NULL, NULL),
(3, 5, 8, 'Leah Brown', 'leah.brown@student.edu.au', 'Requesting access for a supervised project on historical language documentation.', '2026-04-02 11:05:00', 'Approved', 4, '2026-04-04 10:00:00', 'Approved for supervised academic access with staff oversight.'),
(4, 12, 6, 'Emily Chen', 'e.chen@research.edu.au', 'Seeking access to restricted ceremonial object record as part of comparative museum studies.', '2026-04-06 13:25:00', 'Denied', 1, '2026-04-08 16:40:00', 'Denied because access is restricted to cultural authorities and authorised staff.'),
(5, 16, 7, 'James Park', 'j.park@uni.edu.au', 'Research request regarding women''s gathering audio content for coursework.', '2026-04-21 08:30:00', 'Pending', NULL, NULL, NULL);

-- =====================================================
-- Helpful indexes for search and filters
-- =====================================================
CREATE INDEX idx_items_title ON items(title);
CREATE INDEX idx_items_access_status ON items(access_status);
CREATE INDEX idx_items_category ON items(category_id);
CREATE INDEX idx_metadata_group ON cultural_metadata(cultural_group);
CREATE INDEX idx_requests_status ON access_requests(status);
