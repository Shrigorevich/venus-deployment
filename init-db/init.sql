CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

CREATE TABLE IF NOT EXISTS challenge (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id VARCHAR(100) NOT NULL,
  status INTEGER default 1 NOT NULL,
  name VARCHAR (144) NOT NULL,
  description VARCHAR (255),
  start_date DATE NOT NULL,
  end_date DATE
);

CREATE TABLE IF NOT EXISTS challenge_day (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  challenge_id uuid references challenge (id) ON UPDATE CASCADE NOT NULL,
  status INTEGER NOT NULL,
  date DATE NOT NULL,
  UNIQUE (challenge_id, date)
);

CREATE TABLE IF NOT EXISTS purchase_tag (
  id INT PRIMARY KEY GENERATED BY DEFAULT AS IDENTITY,
  user_id VARCHAR(100) NOT NULL,
  name VARCHAR(100) NOT NULL
);

CREATE TABLE IF NOT EXISTS purchase (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id VARCHAR(100) NOT NULL,
  name VARCHAR(144) NOT NULL,
  description VARCHAR(250),
  tag_id INTEGER references purchase_tag (id) ON UPDATE CASCADE ON DELETE CASCADE,
  price DECIMAL NOT NULL,
  currency VARCHAR(3)
);
