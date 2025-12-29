USE grade_management;
-- 과목(학년 별, 담당 선생님), 선생님
-- 시험(중간/기말)
-- 학생(반 별 고유번호, 남녀공학), 학년, 반(담임 선생님)
-- 석차

-- ->
-- 과목, 강의(학년 별, 담당쌤), 선생님
-- 성적(중간/기말)
-- 학생(반 별 고유번호, 남녀공학), 학년, 반(담임 선생님)

CREATE TABLE school_year (
    school_year_id TINYINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    school_year_name VARCHAR(50)
);

CREATE TABLE teacher (
    teacher_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    teacher_name VARCHAR(50)
);

CREATE TABLE class (
    class_id TINYINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    school_year_id TINYINT UNSIGNED NOT NULL,
    teacher_id INT UNSIGNED NOT NULL,
    teacher_assigned_at DATE NOT NULL,
    class_name VARCHAR(50) NULL,
    use_flag BOOLEAN NOT NULL DEFAULT TRUE,
    CONSTRAINT u_school_year_and_class_id UNIQUE (school_year_id, class_id),
    CONSTRAINT fk_class_school_year_id FOREIGN KEY (school_year_id) REFERENCES school_year(school_year_id),
    CONSTRAINT fk_class_teacher_id FOREIGN KEY (teacher_id) REFERENCES teacher(teacher_id)
);

CREATE TABLE student (
    student_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    class_id TINYINT UNSIGNED NULL,
    student_number TINYINT UNSIGNED NULL,
    gender ENUM('M', 'F') NULL,
    entrance_date DATE NOT NULL,
    graduate_date DATE NULL,
    CONSTRAINT fk_student_class_id FOREIGN KEY (class_id) REFERENCES class(class_id)
);

CREATE TABLE subject (
    subject_id TINYINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    subject_name VARCHAR(50)
);

CREATE TABLE lecture (
    lecture_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    subject_id TINYINT UNSIGNED NOT NULL,
    lecture_begin_at DATE NOT NULL,
    teacher_id INT UNSIGNED NOT NULL,
    school_year_id TINYINT UNSIGNED NOT NULL,
    CONSTRAINT u_lecture_1 UNIQUE (subject_id, lecture_begin_at, teacher_id, school_year_id),
    CONSTRAINT fk_lecture_subject_id FOREIGN KEY (subject_id) REFERENCES subject(subject_id),
    CONSTRAINT fk_lecture_teacher_id FOREIGN KEY (teacher_id) REFERENCES teacher(teacher_id),
    CONSTRAINT fk_lecture_school_year_id FOREIGN KEY (school_year_id) REFERENCES school_year(school_year_id)
);

CREATE TABLE grade (
    lecture_id INT UNSIGNED,
    student_id INT UNSIGNED,
    grade TINYINT NOT NULL DEFAULT 0,
    PRIMARY KEY (lecture_id, student_id),
    CONSTRAINT fk_grade_student_id FOREIGN KEY (student_id) REFERENCES student(student_id),
    CONSTRAINT fk_grade_lecture_id FOREIGN KEY (lecture_id) REFERENCES lecture(lecture_id)
);

SHOW INDEX FROM grade;

SELECT
    table_name,
    SUM(data_length + index_length) AS total_size_mb,
    SUM(index_length) AS index_size_mb,
    SUM(data_length) AS data_size_mb
FROM information_schema.TABLES
WHERE table_schema LIKE 'grade_management'
GROUP BY table_name;

INSERT INTO school_year (school_year_name)
VALUES ('1학년'), ('2학년'), ('3학년');

-- deprecated

# DELIMITER $$
# CREATE PROCEDURE SP_Insert_class_number(IN school_year_id TINYINT UNSIGNED, IN cn_id TINYINT UNSIGNED, IN cn_name VARCHAR(50))
# BEGIN
#     INSERT INTO class (school_year_id, class_id, class_name)
#         VALUE (school_year_id, cn_id, cn_name);
# END
# $$
# DELIMITER ;
#
# CALL SP_Insert_class_number(1, 1, '1반');
# CALL SP_Insert_class_number(1, 2, '1반');
# CALL SP_Insert_class_number(1, 3, '1반');
# CALL SP_Insert_class_number(2, 1, '1반');
# CALL SP_Insert_class_number(2, 2, '1반');
# CALL SP_Insert_class_number(2, 3, '1반');
# CALL SP_Insert_class_number(3, 1, '1반');
# CALL SP_Insert_class_number(3, 2, '1반');
# CALL SP_Insert_class_number(3, 3, '1반');
#
# UPDATE class
# SET class_name = CONCAT(CAST(class_id AS CHAR(1)), '반');
#
# SELECT * FROM class;