USE sql_forda;

-- Since triggers are not visible (like procedures) in Workbench, here's how we get details of the triggers

SHOW TRIGGERS;

SELECT * FROM information_schema.TRIGGERS      -- details about triggers
WHERE TRIGGER_SCHEMA = 'your_database_name';


-- -------------------------------- Log the INSERT into an audit table ----------------------------------

-- Create an audit table

DROP TABLE IF EXISTS EMPLOYEE_ALERT_LOG;
CREATE TABLE EMPLOYEE_ALERT_LOG
(
	empid INT AUTO_INCREMENT PRIMARY KEY,
    fullname VARCHAR(50),
    hiredate DATE,
    insert_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Trigger that updates the EMPLOYEE_ALERT_LOG table when an INSERT happens

DROP TRIGGER IF EXISTS ALERT_ON_INSERT;
DELIMITER //
CREATE TRIGGER ALERT_ON_INSERT
AFTER INSERT ON employees
FOR EACH ROW
BEGIN
    INSERT INTO EMPLOYEE_ALERT_LOG VALUES (NEW.empid, NEW.fullname, NEW.hiredate, CURRENT_TIMESTAMP());
END //
DELIMITER ;

INSERT INTO employees VALUES(11, 'TOM HANKS', 6, 25000.00, '1990-05-10', 888);
SELECT * FROM EMPLOYEE_ALERT_LOG ;      -- check if the trigger fired after above INSERT
