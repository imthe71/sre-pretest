-- 題目三：找出分數排名第二名學生所在的班級。
-- MySQL 寫法；`class` 使用反引號避免與關鍵字或工具名稱混淆。
SELECT c.class
FROM score AS s
JOIN `class` AS c
  ON c.name = s.name
ORDER BY s.score DESC
LIMIT 1 OFFSET 1;
