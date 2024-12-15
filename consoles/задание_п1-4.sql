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
