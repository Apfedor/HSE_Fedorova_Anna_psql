 /* 1. Определите таблицы и их атрибуты.
2. Проведите логичную нормализацию данных: корректно организуйте данные в
БД, а именно:
○ создайте таблицы;
○ установите отношения между ними: определите первичные и внешние
ключи, убедитесь, что отношения между таблицами отражают реальные
зависимости в учебном процессе.
3. Создайте ограничения на атрибуты: например, оценки должны быть в диапазоне
от 1 до 5.
4. Предусмотрите механизмы для предотвращения дублирования записей или
ввода некорректных данных.   */

CREATE TABLE students (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100),
    date_of_birth DATE,
    contact_info VARCHAR(255)
);

CREATE TABLE teachers (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100),
    date_of_birth DATE,
    contact_info VARCHAR(255)
);

CREATE TABLE subjects (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100),
    teacher_id INT REFERENCES teachers(id)
);
ALTER TABLE subjects
ADD COLUMN created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP;

CREATE TABLE grades (
    id SERIAL PRIMARY KEY,
    student_id INT REFERENCES students(id),
    subject_id INT REFERENCES subjects(id),
    teacher_id INT REFERENCES teachers(id),
    date DATE,
    grade INT CHECK (grade BETWEEN 1 AND 5)
);

-- Добавление ограничения на оценки
ALTER TABLE grades
ADD CONSTRAINT grade_check CHECK (grade BETWEEN 1 AND 5);

ALTER TABLE students
ADD CONSTRAINT unique_student_name UNIQUE (name);

ALTER TABLE teachers
ADD CONSTRAINT unique_teacher_name UNIQUE (name);

ALTER TABLE students
ALTER COLUMN name SET NOT NULL;

ALTER TABLE teachers
ALTER COLUMN name SET NOT NULL;

ALTER TABLE subjects
ADD CONSTRAINT fk_teacher
FOREIGN KEY (teacher_id) REFERENCES teachers(id);

ALTER TABLE grades
ADD CONSTRAINT fk_student
FOREIGN KEY (student_id) REFERENCES students(id),
ADD CONSTRAINT fk_subject
FOREIGN KEY (subject_id) REFERENCES subjects(id),
ADD CONSTRAINT fk_teacher
FOREIGN KEY (teacher_id) REFERENCES teachers(id);

CREATE OR REPLACE FUNCTION prevent_duplicate_students()
RETURNS TRIGGER AS $$
BEGIN
    IF EXISTS (SELECT 1 FROM students WHERE name = NEW.name) THEN
        RAISE EXCEPTION 'Студент с таким ФИО уже существует';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER check_duplicate_student
BEFORE INSERT ON students
FOR EACH ROW EXECUTE FUNCTION prevent_duplicate_students();

/*5. Задайте возможность: */
-- 1. Вывод списка студентов по определённому предмету
SELECT s.name
FROM students s
JOIN grades g ON s.id = g.student_id
JOIN subjects sub ON g.subject_id = sub.id
WHERE sub.name = 'Биология';

-- 2. Вывод списка предметов, которые преподаёт конкретный преподаватель
SELECT sub.name
FROM subjects sub
JOIN teachers t ON sub.teacher_id = t.id
WHERE t.name = 'Петров Петр';

-- 3. Вывод среднего балла студента по всем предметам
SELECT AVG(g.grade) AS average_grade
FROM grades g
WHERE g.student_id = 41;

-- 4. Вывод рейтинга преподавателей по средней оценке студентов
SELECT t.name, AVG(g.grade) AS average_grade
FROM teachers t
JOIN subjects sub ON t.id = sub.teacher_id
JOIN grades g ON sub.id = g.subject_id
GROUP BY t.name
ORDER BY average_grade DESC;

-- 5. Вывод списка преподавателей, которые преподавали более 3 предметов за последний год
SELECT t.name
FROM teachers t
JOIN subjects sub ON t.id = sub.teacher_id
WHERE sub.created_at > CURRENT_DATE - INTERVAL '1 year'
GROUP BY t.name
HAVING COUNT(sub.id) >= 3;

-- 6. Вывод списка студентов, которые имеют средний балл выше 4 по математическим предметам,
-- но ниже 3 по гуманитарным

    SELECT s.name
FROM students s
JOIN grades g ON s.id = g.student_id
JOIN subjects sub ON g.subject_id = sub.id
WHERE sub.name IN ('Математика', 'Физика', 'Химия', 'Информатика', 'Астрономия')
GROUP BY s.id
HAVING AVG(g.grade) > 4
AND (
    SELECT AVG(g2.grade)
    FROM grades g2
    JOIN subjects sub2 ON g2.subject_id = sub2.id
    WHERE g2.student_id = s.id AND sub2.name IN ('История', 'Литература', 'География', 'Экономика')
) < 3;

-- 7. Определение предметов, по которым больше всего двоек в текущем семестре
SELECT sub.name, COUNT(g.grade) AS count_of_twos
FROM subjects sub
JOIN grades g ON sub.id = g.subject_id
WHERE g.grade = 2
  AND g.date >= (CASE
                     WHEN EXTRACT(MONTH FROM CURRENT_DATE) <= 6 THEN DATE_TRUNC('year', CURRENT_DATE)  -- Первый семестр
                     ELSE DATE_TRUNC('year', CURRENT_DATE) + INTERVAL '6 months'  -- Второй семестр
                  END)
GROUP BY sub.name
ORDER BY count_of_twos DESC;

-- 8. Вывод студентов, которые получили высший балл по всем своим экзаменам, и преподавателей, которые вели эти предметы
SELECT s.name AS student_name, t.name AS teacher_name
FROM students s
JOIN grades g ON s.id = g.student_id
JOIN subjects sub ON g.subject_id = sub.id
JOIN teachers t ON sub.teacher_id = t.id
WHERE g.grade = 5;

-- 9. Просмотр изменения среднего балла студента по годам обучения

SELECT
    s.name AS student_name,
    EXTRACT(YEAR FROM g.date) AS year,
    AVG(g.grade) AS avg_grade
FROM
    grades g
JOIN
    students s ON g.student_id = s.id
GROUP BY
    s.name, EXTRACT(YEAR FROM g.date)
ORDER BY
    s.name, year;

-- 10. Определение групп, в которых средний балл выше, чем в других, по аналогичным предметам

WITH average_grades AS (
    SELECT g.id AS group_id, AVG(gr.grade) AS average_grade
    FROM groups g
    JOIN students s ON g.id = s.group_id
    JOIN grades gr ON s.id = gr.student_id
    GROUP BY g.id
)
SELECT g.group_name, ag.average_grade
FROM groups g
JOIN average_grades ag ON g.id = ag.group_id
WHERE ag.average_grade > (SELECT AVG(average_grade) FROM average_grades WHERE group_id != ag.group_id);

-- 6. Вставьте записи о новом студенте с его личной информацией: ФИО, дата
-- рождения, контактные данные и др
INSERT INTO students (id, name, date_of_birth, contact_info, group_id)
VALUES (61, 'Иванов Иван Иванович', '2005-03-15', 'ivanov@example.com, +1234567890', 1);

--  7. Добавьте возможность:
-- ○ обновления контактной информации преподавателя, например,
-- электронной почты или номера телефона, на основе его
-- идентификационного номера или ФИО;
UPDATE teachers
SET contact_info = '+7-555-2233' -- Новый номер телефона
WHERE name = 'Смирнов Алексей';


-- ○ удаления записи о предмете, который больше не преподают в учебном
-- заведении. Учтите возможные зависимости, такие как оценки студентов
-- по этому предмету;

-- Предположим, `subject_id` - это идентификатор удаляемого предмета
BEGIN;

-- Удалите все оценки, связанные с конкретным предметом
DELETE FROM grades
WHERE subject_id = 1;

-- Удалите сам предмет
DELETE FROM subjects
WHERE id = 1;

COMMIT;

-- ○ вставки новой записи об оценке, выставленной студенту по
-- определённому предмету, с указанием даты, преподавателя и
-- полученной оценки

INSERT INTO grades (student_id, subject_id, date, grade, teacher_id)
VALUES (42, 4, '2024-12-15', 5, 10);

-- выводит таблицу с оценками студентов по предметам с указанием кто ее поставил
SELECT
    students.name AS student_name,
    subjects.name AS subject_name,
    grades.grade,
    teachers.name AS teacher_name
FROM
    grades
JOIN
    students ON grades.student_id = students.id
JOIN
    subjects ON grades.subject_id = subjects.id
LEFT JOIN
    teachers ON grades.teacher_id = teachers.id
ORDER BY
    students.name,
    subjects.name;

/*
8. Добавьте следующую документацию:

○ документация по структуре базы данных;
○ описание каждой таблицы, её атрибутов и отношений с другими
таблицами.
-----------------------------------------------------------------------------
Документация по структуре базы данных

1. Таблица `students`

- Описание: Хранит информацию о студентах.
- Атрибуты:
  - `id` (INT, PRIMARY KEY): Уникальный идентификатор студента.
  - `name` (VARCHAR): Имя студента.
- Связи:
  - Один ко многим с таблицей `grades` через `student_id`.

2. Таблица `subjects`

- Описание: Содержит список предметов.
- Атрибуты:
  - `id` (INT, PRIMARY KEY): Уникальный идентификатор предмета.
  - `name` (VARCHAR): Название предмета.
  - `teacher_id` (INT, FOREIGN KEY): Ссылается на таблицу `teachers`, указывая преподавателя, ответственного за предмет.
- Связи:
  - Один ко многим с таблицей `grades` через `subject_id`.

3. Таблица `teachers`

- Описание: Хранит информацию о преподавателях.
- Атрибуты:
  - `id` (INT, PRIMARY KEY): Уникальный идентификатор преподавателя.
  - `name` (VARCHAR): Имя преподавателя.
- Связи:
  - Один ко многим с таблицей `grades` через `teacher_id`.
  - Один ко многим с таблицей `subjects` через `teacher_id`.

4. Таблица `grades`

- Описание: Содержит информацию об оценках, выставленных студентам.
- Атрибуты:
  - `id` (SERIAL, PRIMARY KEY): Уникальный идентификатор записи об оценке.
  - `student_id` (INT, FOREIGN KEY): Ссылается на таблицу `students`.
  - `subject_id` (INT, FOREIGN KEY): Ссылается на таблицу `subjects`.
  - `date` (DATE): Дата, когда была выставлена оценка.
  - `grade` (INT): Оценка, полученная студентом (допустимый диапазон от 1 до 5).
  - `teacher_id` (INT, FOREIGN KEY): Ссылается на таблицу `teachers`.
- Связи:
  - Каждая запись связана с одним студентом из таблицы `students`.
  - Каждая запись связана с одним предметом из таблицы `subjects`.
  - Каждая запись связана с одним преподавателем из таблицы `teachers`.
*/

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

