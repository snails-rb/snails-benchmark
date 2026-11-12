-- The single table both benchmark apps read. The schema dump in
-- db/schema.sql is generated from this file; edit here first, then run
-- `snails migrate dump`.
CREATE TABLE IF NOT EXISTS items (
  id INTEGER PRIMARY KEY,
  name TEXT NOT NULL,
  description TEXT NOT NULL,
  price INTEGER NOT NULL,
  status TEXT NOT NULL
);
