-- Test plumbing only; never install this in production migrations.
CREATE SCHEMA IF NOT EXISTS hinagata_bootstrap;
CREATE TABLE IF NOT EXISTS hinagata_bootstrap.marker (
  id integer PRIMARY KEY,
  value text NOT NULL
);
INSERT INTO hinagata_bootstrap.marker (id, value) VALUES (1, 'ready')
ON CONFLICT (id) DO UPDATE SET value = EXCLUDED.value;
