-- Seed script for a class student score table in PostgreSQL
-- Includes 10 sample rows with Chinese, Math, English, Physics, Chemistry

DROP TABLE IF EXISTS class_scores;

CREATE TABLE class_scores (
    id SERIAL PRIMARY KEY,
    student_name TEXT NOT NULL,
    chinese INT CHECK (chinese BETWEEN 0 AND 100),
    math INT CHECK (math BETWEEN 0 AND 100),
    english INT CHECK (english BETWEEN 0 AND 100),
    physics INT CHECK (physics BETWEEN 0 AND 100),
    chemistry INT CHECK (chemistry BETWEEN 0 AND 100),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

INSERT INTO class_scores (student_name, chinese, math, english, physics, chemistry) VALUES
('梨花', 92, 88, 90, 85, 87),
('王伟', 78, 83, 75, 80, 76),
('张三', 85, 91, 88, 90, 89),
('李四', 69, 74, 72, 70, 68),
('王二麻子', 95, 89, 94, 92, 90),
('小老弟', 81, 77, 79, 75, 80),
('高林', 73, 69, 71, 72, 74),
('何静', 88, 90, 86, 84, 85),
('徐冉', 66, 70, 68, 65, 67),
('邓伟', 90, 85, 92, 88, 91);

-- To run:
--   psql -h <host> -U <user> -d <db> -f class_scores.sql

