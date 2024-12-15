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