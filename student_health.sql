CREATE TABLE Students (
	student_id int auto_increment primary key,
    student_code varchar(20) unique not null,
    first_name varchar(100) not null,
	last_name varchar(100) not null,
    gender enum('Male', 'Female'),
    birth_date date,
    class varchar(20),
    student_phone varchar(20),
    parent_name varchar(100),
    parent_phone varchar(20),
	created_at datetime default current_timestamp
);

SET FOREIGN_KEY_CHECKS = 1;
drop table disease;

CREATE TABLE disease (
	disease_id int auto_increment primary key,
    disease_name varchar(100) not null
);

drop table medical_condition;

CREATE TABLE medical_condition (
	condition_id int auto_increment primary key,
    student_id int not null,
    disease_id int not null,
    
    foreign key (student_id) references students(student_id) on delete cascade,
    foreign key (disease_id) references disease(disease_id) on delete cascade
);

CREATE TABLE treatment_history (
    treatment_id int auto_increment primary key,
    student_id int not null,
    hospital_name varchar(100),
    diagnosis varchar(100),
    treatment_date date,

    foreign key (student_id) references students(student_id) on delete cascade
);

CREATE TABLE allergies (
    allergy_id int auto_increment primary key,
    student_id int not null,
    allergy_type varchar(100),
    descriptions varchar(255),

    foreign key (student_id) references Students(student_id) on delete cascade
);

CREATE TABLE health_behavior (
	behavior_id int auto_increment primary key,
    student_id int not null,
    smoking_status enum('Never', 'Former', 'Current') default 'Never',
    cigarettes_per_day int default 0,
    drinking_status enum('Never', 'Former', 'Current') default 'Never',
    drinking_frequency varchar(50),
    foreign key(student_id) references students(student_id) on delete cascade
);

drop PROCEDURE AddStudentDisease;
DELIMITER $$

CREATE PROCEDURE AddStudentDisease(
	in t_student_id int,
    in t_disease_name varchar(100)
)
BEGIN 
	declare u_disease_id int default null;
    
    select disease_id into u_disease_id from disease
    where disease_name = t_disease_name
    limit 1;
    
    if u_disease_id is null then
		insert into disease(disease_name) value (t_disease_name);
        set u_disease_id = LAST_INSERT_ID();
	end if;
    
    insert ignore into medical_condition(student_id, disease_id) values (t_student_id, u_disease_id);
    
end$$

DELIMITER ;

CREATE VIEW vw_student_full_history AS
SELECT
    s.student_id,
    s.student_code,
    CONCAT(s.first_name,' ',s.last_name) AS full_name,
    s.gender,
    s.birth_date,
    s.class,
    s.student_phone,

    GROUP_CONCAT(DISTINCT d.disease_name
                 ORDER BY d.disease_name
                 SEPARATOR ', ') AS diseases,

    GROUP_CONCAT(
        DISTINCT CONCAT(
            th.diagnosis,
            ' (',
            th.hospital_name,
            ', ',
            DATE_FORMAT(th.treatment_date,'%d/%m/%Y'),
            ')'
        )
        SEPARATOR ' | '
    ) AS treatment_history,

    GROUP_CONCAT(
        DISTINCT CONCAT(
            a.allergy_type,
            ': ',
            a.descriptions
        )
        SEPARATOR ' | '
    ) AS allergies,

    hb.smoking_status,
    hb.cigarettes_per_day,
    hb.drinking_status,
    hb.drinking_frequency

FROM Students s

LEFT JOIN medical_condition mc
    ON s.student_id = mc.student_id

LEFT JOIN disease d
    ON mc.disease_id = d.disease_id

LEFT JOIN treatment_history th
    ON s.student_id = th.student_id

LEFT JOIN allergies a
    ON s.student_id = a.student_id

LEFT JOIN health_behavior hb
    ON s.student_id = hb.student_id

GROUP BY
    s.student_id;


INSERT INTO Students
(student_code, first_name, last_name, gender, birth_date,
 class, student_phone, parent_name, parent_phone)
VALUES
('65001','สมชาย','ใจดี','Male','2008-05-10','ม.6/1','0891111111','สุดา ใจดี','0811111111'),
('65002','สมหญิง','รักเรียน','Female','2008-08-15','ม.6/1','0892222222','วิชัย รักเรียน','0822222222'),
('65003','อนันต์','สุขสบาย','Male','2008-11-20','ม.6/2','0893333333','สมพร สุขสบาย','0833333333');

INSERT INTO Disease(disease_name)
VALUES
('หอบหืด'),
('ภูมิแพ้'),
('เบาหวาน'),
('โรคหัวใจ'),
('ไมเกรน');

INSERT INTO Treatment_History
(student_id, hospital_name, diagnosis, treatment_date)
VALUES
(1,'รพ.มหาราชนครราชสีมา','หอบหืดกำเริบ','2026-01-15'),
(1,'รพ.มหาราชนครราชสีมา','ภูมิแพ้','2026-03-20'),
(2,'รพ.กรุงเทพราชสีมา','ไมเกรน','2026-02-10'),
(3,'รพ.มหาราชนครราชสีมา','เบาหวาน','2026-04-05');

INSERT INTO Allergies
(student_id, allergy_type, descriptions)
VALUES
(1,'Drug','Penicillin'),
(1,'Food','อาหารทะเล'),
(2,'Dust','แพ้ฝุ่น'),
(3,'Food','กุ้ง');

CALL AddStudentDisease(1,'หอบหืด');
CALL AddStudentDisease(3,'ภูมิแพ้');

INSERT INTO Health_Behavior
(student_id, smoking_status, cigarettes_per_day,
 drinking_status, drinking_frequency)
VALUES
(1,'Never',0,'Never','ไม่ดื่ม'),
(2,'Former',0,'Former','เลิกแล้ว'),
(3,'Current',5,'Current','1-2 ครั้ง/สัปดาห์');

select * from vw_student_full_history;