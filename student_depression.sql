SET SQL_SAFE_UPDATES = 1;

CREATE TABLE Users (
user_id INT AUTO_INCREMENT PRIMARY KEY,
fullname VARCHAR(100) NOT NULL,
age INT,
gender ENUM('Male','Female','Other'),
created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

ALTER TABLE Users
ADD first_name VARCHAR(50),
ADD last_name VARCHAR(50);

ALTER TABLE Users
MODIFY COLUMN last_name VARCHAR(50)
AFTER first_name;

UPDATE Users
SET
    first_name = SUBSTRING_INDEX(fullname, ' ', 1),
    last_name = SUBSTRING_INDEX(fullname, ' ', -1);
    
ALTER TABLE Users
DROP COLUMN fullname;

CREATE TABLE Questions (
question_id INT PRIMARY KEY,
question_text VARCHAR(255) NOT NULL
);

INSERT INTO Questions VALUES
(1,'เบื่อ ทำอะไรๆ ก็ไม่เพลิดเพลิน'),
(2,'ไม่สบายใจ ซึมเศร้า หรือท้อแท้'),
(3,'หลับยาก หรือหลับๆ ตื่นๆ หรือหลับมากไป'),
(4,'เหนื่อยง่าย หรือไม่ค่อยมีแรง'),
(5,'เบื่ออาหาร หรือกินมากเกินไป'),
(6,'รู้สึกไม่ดีกับตัวเอง คิดว่าตัวเองล้มเหลว'),
(7,'สมาธิไม่ดีเวลาทำอะไร'),
(8,'พูดช้าลงหรือกระสับกระส่ายมากกว่าปกติ'),
(9,'คิดทำร้ายตนเอง หรือคิดว่าถ้าตายไปคงจะดี');


CREATE TABLE Assessments (
assessment_id INT AUTO_INCREMENT PRIMARY KEY,
user_id INT NOT NULL,
assessment_date DATETIME DEFAULT CURRENT_TIMESTAMP,
total_score INT DEFAULT 0,
result_level VARCHAR(50),

FOREIGN KEY (user_id)
REFERENCES Users(user_id)
);

ALTER TABLE Assessments
MODIFY COLUMN academic_year INT NOT NULL
AFTER semester;

ALTER TABLE Assessments
ADD academic_year INT NOT NULL,
ADD semester TINYINT NOT NULL CHECK (semester IN (1,2));


CREATE TABLE Answers (
answer_id INT AUTO_INCREMENT PRIMARY KEY,
assessment_id INT NOT NULL,
question_id INT NOT NULL,
score TINYINT NOT NULL CHECK(score BETWEEN 0 AND 3),

FOREIGN KEY (assessment_id)
REFERENCES Assessments(assessment_id),

FOREIGN KEY (question_id)
REFERENCES Questions(question_id)
);

DELIMITER $$

CREATE FUNCTION sum_score(
t_assessment_id INT
)
RETURNS INT
DETERMINISTIC
BEGIN
DECLARE total INT;

SELECT SUM(score)
INTO total
FROM Answers
WHERE assessment_id = t_assessment_id;

RETURN IFNULL(total,0);

END$$

DELIMITER ;

DELIMITER $$

CREATE PROCEDURE evaluate_depression(
IN t_assessment_id INT
)
BEGIN

DECLARE total INT;
DECLARE level_text VARCHAR(50);

SET total = sum_score(t_assessment_id);

IF total BETWEEN 0 AND 4 THEN
    SET level_text = 'ปกติ';
ELSEIF total BETWEEN 5 AND 9 THEN
    SET level_text = 'ซึมเศร้าระดับเล็กน้อย';
ELSEIF total BETWEEN 10 AND 14 THEN
    SET level_text = 'ซึมเศร้าระดับปานกลาง';
ELSEIF total BETWEEN 15 AND 19 THEN
    SET level_text = 'ซึมเศร้าระดับค่อนข้างรุนแรง';
ELSE
    SET level_text = 'ซึมเศร้าระดับรุนแรง';
END IF;

UPDATE Assessments
SET total_score = total,
    result_level = level_text
WHERE assessment_id = t_assessment_id;

END$$

DELIMITER ;

-- TEST DATA
INSERT INTO Users(fullname,age,gender)
VALUES ('Ryuuuuuuuu',21,'Male');

INSERT INTO Assessments(user_id)
VALUES (6);

INSERT INTO Answers(assessment_id,question_id,score)
VALUES
(8,1,1),
(8,2,2),
(8,3,1),
(8,4,0),
(8,5,1),
(8,6,0),
(8,7,1),
(8,8,0),
(8,9,0);


CALL evaluate_depression(8);

SELECT * FROM Assessments;

create view assignment_result as 
select u.user_id, u.fullname, a.assessment_id, a.total_score, a.result_level, a.assessment_date from users u join assessments a
where u.user_id = a.user_id;

SELECT * FROM assignment_result 
where user_id = 1;

select * from users
order by convert(fullname using tis620);

UPDATE Assessments
SET academic_year = '2568',
    semester = 1;
    
DELIMITER $$

CREATE TRIGGER check_duplicate_assessment
BEFORE INSERT ON Assessments
FOR EACH ROW
BEGIN

    IF EXISTS (
        SELECT 1
        FROM Assessments
        WHERE user_id = NEW.user_id
          AND academic_year = NEW.academic_year
          AND semester = NEW.semester
    ) THEN

        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'ผู้ใช้คนนี้ได้ทำแบบประเมินในปีการศึกษาและเทอมนี้แล้ว';

    END IF;

END$$

DELIMITER ;