TRUNCATE TABLE teachers CASCADE;

INSERT INTO teachers (id, name, date_of_birth, contact_info) VALUES
(1, 'Иванов Иван', DATE '1975-05-15', '+7-555-0101'),
(2, 'Петров Петр', DATE '1980-03-22', '+7-555-0202'),
(3, 'Сидорова Анна', DATE '1985-08-30', '+7-555-0303'),
(4, 'Кузнецова Мария', DATE '1990-11-05', '+7-555-0404'),
(5, 'Смирнов Алексей', DATE '1978-01-12', '+7-555-0505'),
(6, 'Васильев Виктор', DATE '1982-02-18', '+7-555-0606'),
(7, 'Козлов Сергей', DATE '1979-07-25', '+7-555-0707'),
(8, 'Морозова Ольга', DATE '1983-09-14', '+7-555-0808'),
(9, 'Новикова Елена', DATE '1987-12-19', '+7-555-0909'),
(10, 'Федоров Дмитрий', DATE '1992-06-10', '+7-555-1010')
ON CONFLICT (id) DO UPDATE SET
    date_of_birth = EXCLUDED.date_of_birth,
    contact_info = EXCLUDED.contact_info;

TRUNCATE TABLE subjects CASCADE;

INSERT INTO subjects (id, name, teacher_id)
SELECT
    ROW_NUMBER() OVER () AS id,  -- Генерация последовательного id начиная с 1
    subj_name,
    teacher_id
FROM (
    SELECT
        subj_name,
        ROW_NUMBER() OVER () AS rn
    FROM (VALUES
        ('Математика'),
        ('Физика'),
        ('Химия'),
        ('История'),
        ('Литература'),
        ('Биология'),
        ('География'),
        ('Информатика'),
        ('Астрономия'),
        ('Экономика')
    ) AS subjects(subj_name)
) AS numbered_subjects
JOIN (
    SELECT
        id AS teacher_id,
        ROW_NUMBER() OVER () AS rn
    FROM teachers
) AS numbered_teachers
ON numbered_subjects.rn = numbered_teachers.rn;

TRUNCATE TABLE students CASCADE;
INSERT INTO students (name, date_of_birth, contact_info, group_id)
SELECT
    CONCAT('Student ', s.id),  -- Имя студента
    (DATE '1999-01-01' + (RANDOM() * (DATE '2006-12-31' - DATE '1999-01-01'))::int) AS date_of_birth,
    CONCAT('+7-555-', LPAD((FLOOR(RANDOM() * 10000)::int)::text, 4, '0')) AS contact_info,
    FLOOR(RANDOM() * 3 + 1)::int AS group_id  -- Случайное значение от 1 до 3
FROM generate_series(1, 20) AS s(id);

TRUNCATE TABLE grades CASCADE;
INSERT INTO grades (student_id, subject_id, grade, date)
SELECT
    s.id AS student_id,
    sub.id AS subject_id,
    FLOOR(RANDOM() * 3 + 3)::int AS grade,  -- Случайная оценка от 3 до 5
    CURRENT_DATE AS date
FROM
    students s,
    subjects sub;

TRUNCATE TABLE subjects CASCADE;
INSERT INTO subjects (id, name, teacher_id)
VALUES
    (1, 'Математика', 1),
    (2, 'Физика', 1),
    (3, 'Химия', 1),
    (4, 'История', 2),
    (5, 'Литература', 3),
    (6, 'Биология', 4),
    (7, 'География', 5),
    (8, 'Информатика', 6),
    (9, 'Астрономия', 7),
    (10, 'Экономика', 8);

UPDATE grades
SET grade = 2
WHERE student_id = 41
AND subject_id IN (
    SELECT id FROM subjects WHERE name IN ('История', 'Литература', 'География', 'Экономика')
);

UPDATE grades
SET grade = 5
WHERE student_id = 41
AND subject_id IN (
    SELECT id FROM subjects WHERE name IN ('Математика', 'Физика', 'Химия', 'Информатика', 'Астрономия')
);

SELECT s.name AS student_name, sub.name AS subject_name, g.grade
FROM grades g
JOIN students s ON g.student_id = s.id
JOIN subjects sub ON g.subject_id = sub.id
WHERE g.student_id = 41;


SELECT
    s.name AS student_name,
    s.group_id AS group,
    AVG(CASE WHEN sub.name IN ('Математика', 'Физика', 'Химия', 'Информатика', 'Астрономия') THEN g.grade END) AS avg_math_grade,
    AVG(CASE WHEN sub.name IN ('История', 'Литература', 'География', 'Экономика') THEN g.grade END) AS avg_human_grade
FROM
    students s
JOIN
    grades g ON s.id = g.student_id
JOIN
    subjects sub ON g.subject_id = sub.id
GROUP BY
    s.id, s.name, s.group_id
ORDER BY
    s.group_id;

UPDATE grades
SET teacher_id = (
    SELECT teacher_id
    FROM subjects
    WHERE subjects.id = grades.subject_id
);