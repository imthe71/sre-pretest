# 第三題：SQL 查詢

## 題目

資料庫 `student` 有兩張表：

- `score(name, score)`：學生分數。
- `class(name, class)`：學生班級。

請找出分數排名第二名學生所在的班級。

## 解法

```sql
SELECT c.class
FROM score AS s
JOIN `class` AS c
  ON c.name = s.name
ORDER BY s.score DESC
LIMIT 1 OFFSET 1;
```

先用 `name` 把分數和班級資料接起來，再以分數由大到小排序。`OFFSET 1` 跳過第一名，`LIMIT 1` 取下一筆資料。

題目資料排序後是 Mary（100）、John（97）、Sara（89）、David（83），所以查詢結果為：

```text
A
```

## 補充：分數同分時

題目範例沒有同分。若需求是「不同分數的第二名」，可使用 `DENSE_RANK()`：

```sql
WITH ranked_scores AS (
  SELECT
    name,
    score,
    DENSE_RANK() OVER (ORDER BY score DESC) AS score_rank
  FROM score
)
SELECT c.class
FROM ranked_scores AS r
JOIN `class` AS c
  ON c.name = r.name
WHERE r.score_rank = 2;
```

此版本在第二名有多人同分時，會回傳所有符合的班級。
