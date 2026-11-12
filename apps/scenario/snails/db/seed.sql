-- Ten thousand deterministic rows. The PK lookup keeps the working set small
-- enough to stay in page cache, so the scenario measures the app path rather
-- than disk latency. No timestamps or booleans: both apps must return exactly
-- the same JSON values without type-conversion differences.
DELETE FROM items;

WITH RECURSIVE seq(n) AS (
  SELECT 1
  UNION ALL
  SELECT n + 1 FROM seq WHERE n < 10000
)
INSERT INTO items (id, name, description, price, status)
SELECT
  n,
  'item-' || n,
  'description-' || n,
  100 + (n % 900),
  CASE WHEN n % 2 = 0 THEN 'active' ELSE 'inactive' END
FROM seq;
