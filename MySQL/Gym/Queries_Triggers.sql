USE sql_forda;

-- -------------------------------- Log the INSERT into an audit table ----------------------------------

-- Create an audit table

CREATE TABLE EMPLOYEE_ALERT_LOG
(
	log_id INT AUTO_INCREMENT PRIMARY KEY,
    empid INT,
    salary DECIMAL(10,2),
    insert_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create the trigger that updates the EMPLOYEE_ALERT_LOG table when an INSERT happens

DELIMITER //
CREATE TRIGGER ALERT_ON_INSERT
AFTER INSERT ON employees
FOR EACH ROW
BEGIN
	INSERT INTO EMPLOYEE_ALERT_LOG VALUES (NEW.empid, NEW.salary);
END //
DELIMITER ;

SELECT * FROM EMPLOYEE_ALERT_LOG ;

SELECT * FROM employees;
INSERT INTO employees VALUES(11, 'TOM FELTON', 5, 200000.00, '1996-05-10', 9999);