/* ======================= ENABLING LOCAL FILE ACCESS ======================== */
SET GLOBAL local_infile = 1;

/* ======================= CREATING DATABASE ======================== */
CREATE DATABASE IF NOT EXISTS wcic;
USE wcic;

/* ======================= CREATING TABLES ======================== */

-- Table: inv_users
DROP TABLE IF EXISTS inv_users;
CREATE TABLE IF NOT EXISTS inv_users (
    user_id INT PRIMARY KEY,
    user_name VARCHAR(20)
);

-- Table: user_creation_log
DROP TABLE IF EXISTS user_creation_log;
CREATE TABLE IF NOT EXISTS user_creation_log (
    log_id INT NOT NULL AUTO_INCREMENT,
    user_id INT REFERENCES inv_users(user_id),
    table_id VARCHAR(100),
    entry_id INT,
    dep_date TIMESTAMP,
    PRIMARY KEY (log_id)
);

-- Table: glycerol_stocks
DROP TABLE IF EXISTS glycerol_stocks;
CREATE TABLE IF NOT EXISTS glycerol_stocks (
    box VARCHAR(4),
    stock_no INT NOT NULL AUTO_INCREMENT,
    user_id INT REFERENCES inv_users(user_id),
    dep_date TIMESTAMP,
    cell_line VARCHAR(100),
    vector VARCHAR(40),
    vector_insert VARCHAR(300),
    resistance VARCHAR(20),
    notes VARCHAR(300),
    validation_binary VARCHAR(500),
    validation_desc VARCHAR(500),
    PRIMARY KEY (stock_no)
);

-- View: progress_view
DROP VIEW IF EXISTS progress_view;
CREATE OR REPLACE VIEW progress_view AS
SELECT vector, vector_insert, validation_binary, validation_desc
FROM glycerol_stocks;

-- Table: plasmid_val
DROP TABLE IF EXISTS plasmid_val;
CREATE TABLE IF NOT EXISTS plasmid_val (
    stock_no INT REFERENCES glycerol_stocks(stock_no),
    dep_date TIMESTAMP,
    vector VARCHAR(40),
    vector_insert VARCHAR(300),
    validation_binary VARCHAR(500),
    validation_desc VARCHAR(500)
);

-- Table: primers
DROP TABLE IF EXISTS primers;
CREATE TABLE IF NOT EXISTS primers (
    primer_no INT NOT NULL AUTO_INCREMENT,
    user_id INT REFERENCES inv_users(user_id),
    dep_date TIMESTAMP,
    primer_name VARCHAR(200),
    sequence VARCHAR(60),
    no_bases INT,
    GC_content FLOAT,
    Tm FLOAT,
    notes VARCHAR(200),
    PRIMARY KEY (primer_no)
);

/* ======================= POPULATING TABLES WITH EXISTING DATA ======================== */

-- Load data from files
LOAD DATA LOCAL INFILE 'C:/Users/bryce/Downloads/glycerol_stocks.txt' INTO TABLE glycerol_stocks;
LOAD DATA LOCAL INFILE 'C:/Users/bryce/Downloads/primers.txt' INTO TABLE primers;

/* ======================= INSERTING INITIAL OR TEST VALUES ======================== */

-- Table: inv_users
INSERT INTO inv_users (user_id, user_name) VALUES (1, 'BGA');

/* ======================= FORMATTING EXISTING DATA ======================== */

-- Temporary Table: sequences
DROP TABLE IF EXISTS sequences;
CREATE TEMPORARY TABLE sequences AS
    SELECT primer_no, UPPER(sequence) AS upper_seq
    FROM primers;

-- Disable SQL_SAFE_UPDATES temporarily
SET SQL_SAFE_UPDATES = 0;

-- Update primers with uppercase sequences
UPDATE primers
SET sequence = (SELECT upper_seq FROM sequences WHERE primers.primer_no = sequences.primer_no);

-- Set initial values in glycerol_stocks and primers for user_id and dep_date for read-in data
UPDATE glycerol_stocks
SET user_id = 1, dep_date = CURRENT_TIMESTAMP;

UPDATE primers
SET user_id = 1, dep_date = CURRENT_TIMESTAMP;

-- Modify dep_date columns with default values and update behavior
ALTER TABLE glycerol_stocks
MODIFY dep_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP;

ALTER TABLE primers
MODIFY dep_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP;

/* ======================= DEFINING TRIGGERS ======================== */

CREATE TRIGGER log_user_data
AFTER INSERT ON glycerol_stocks
FOR EACH ROW
INSERT INTO user_creation_log (table_id, user_id, entry_id, dep_date)
VALUES ('glycerol_stocks', NEW.user_id, NEW.stock_no, NEW.dep_date);

CREATE TRIGGER after_glycerol_stocks_insert
AFTER INSERT ON glycerol_stocks
FOR EACH ROW
INSERT INTO plasmid_val (stock_no, dep_date, vector, vector_insert)
VALUES (NEW.stock_no, NEW.dep_date, NEW.vector, NEW.vector_insert);
