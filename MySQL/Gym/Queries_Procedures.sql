USE sql_forda;

-- -------------------------- FACTORIAL ------------------------
DROP PROCEDURE IF EXISTS fact;
Delimiter //
CREATE PROCEDURE fact(IN num INT)
	BEGIN
		DECLARE result DECIMAL(65, 2); 
        DECLARE i INT;
		SET result = 1;
		SET i = 1;
		WHILE i <= num DO
			SET result = result * i;
			SET i = i + 1;
		END WHILE;
	SELECT num AS nmbr, result as num_factorial;
	END//
DELIMITER ;
CALL fact(49); -- Can't calculate for 50 and above 

-- ------------------------------- EXPONENTIATION --------------------------

DROP PROCEDURE IF EXISTS exponentiation;
DELIMITER //
CREATE PROCEDURE exponentiation(IN m BIGINT, IN n BIGINT)
	BEGIN
		DECLARE result DECIMAL(65, 2);
        DECLARE i INT;
        SET result = 1, i = 1;
        WHILE i <= n DO
			SET result = result * m;
            SET i = i + 1;
		END WHILE;
        SELECT m AS nmbr, n AS exponent, result AS powered;
	END //
DELIMITER ;
CALL exponentiation(25, 25);


-- ------------------------------- N-th HIGHEST SALARY (Stop as soon as N-th salary is found) --------------------------

DROP PROCEDURE IF EXISTS Get_Nth_HighestSalary;
DELIMITER $$
CREATE PROCEDURE Get_Nth_HighestSalary(IN input_N INT)
BEGIN
    DECLARE temp_rank INT DEFAULT 0;
    DECLARE prev_salary INT DEFAULT NULL; 
    DECLARE current_salary INT;
    DECLARE result_salary INT DEFAULT NULL;
    DECLARE done INT DEFAULT FALSE;
    -- DECLARE cur CURSOR FOR SELECT DISTINCT salary FROM EMPLOYEES ORDER BY salary DESC;
    -- Above line is not a good practice; cursor on temp tbl/view is good practice (done ahead)
    DECLARE cur CURSOR FOR SELECT salary FROM temp_salaries;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;  -- line necessary when cursor is done with the last record; saves from query crash
	
    DROP TEMPORARY TABLE IF EXISTS temp_salaries;
	CREATE TEMPORARY TABLE temp_salaries AS
		SELECT DISTINCT salary FROM employees ORDER BY salary DESC;
        
    OPEN cur;
    read_loop: LOOP
        FETCH cur INTO current_salary;
        IF done THEN                                         -- runs when last record is done with by cursor
            LEAVE read_loop;
        END IF;
        IF current_salary <> prev_salary THEN
            SET temp_rank := temp_rank + 1;
            SET prev_salary := current_salary;
        END IF;
        IF temp_rank = input_N THEN
            SET result_salary := current_salary;
            LEAVE read_loop;
        END IF;        
    END LOOP;
    CLOSE cur;
    IF result_salary IS NOT NULL THEN
        SELECT result_salary AS NthHighestSalary;
    ELSE
        SELECT CONCAT('There are fewer than ', input_N, ' distinct salaries.') AS Message;
    END IF;
END$$
DELIMITER ;

CALL Get_Nth_HighestSalary(2);


-- Create a procedure using SALARY as a parameter that selects all EMPID from the EMPLOYEES table where SALARY is less than say 20k.

DROP PROCEDURE IF EXISTS GetEmpSalary_LT_20K;
DELIMITER //
CREATE PROCEDURE GetEmpSalary_LT_20K(IN max_salary DECIMAL(10,2))
BEGIN
SELECT empid, salary
FROM employees
WHERE salary < max_salary;
END //
DELIMITER ;

CALL GetEmpSalary_LT_20K(20000);












