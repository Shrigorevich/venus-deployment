CREATE TYPE ch_type AS (
	id uuid, 
	status int,
	name varchar(144),
	description varchar(255),
	startdate DATE,
	enddate DATE,
	days JSON
);

CREATE TYPE purch_tag_type AS (
  id INT,
  userid VARCHAR(100),
  name VARCHAR(100)
);

CREATE TYPE purchase_type AS (
  id uuid,
  userid VARCHAR (100),
  name VARCHAR (100),
  price DECIMAL, 
  currency VARCHAR(3),
  description VARCHAR (255),
  tag VARCHAR(100)
)

-- CREATE NEW CHALLENGE FOR USER
CREATE OR REPLACE FUNCTION create_challenge(
	user_id VARCHAR(100),
  name VARCHAR(144),
  description VARCHAR (255),
  start_date DATE,
  end_date DATE default null
) returns uuid AS $$

declare
	res_id uuid;
begin
	INSERT into challenge (user_id, name, description, start_date, end_date) values($1, $2, $3, $4, $5) returning id INTO res_id;
	return res_id;
end; 

$$ LANGUAGE 'plpgsql';

-- GET ALL USER`S CHALLENGES
CREATE OR REPLACE FUNCTION get_challenges(
	user_id VARCHAR(100)
) returns setof ch_type AS $$

declare
	res ch_type;
begin
	for res in
    SELECT c.id, c.status, c.name, c.description, c.start_date, c.end_date,
    json_agg(json_build_object(
      'status', cd.status, 
      'date', cd.date)
    ) AS days
    FROM challenge c JOIN challenge_day cd ON c.id = cd.challenge_id
    GROUP BY c.id
    loop
        return next res;
    end loop;

end; 
$$ LANGUAGE 'plpgsql';

-- ADD NEW PURCHASE_TAG FOR USER
CREATE OR REPLACE FUNCTION create_purchase_tag(
  user_id VARCHAR(100),
  name VARCHAR (100)
) returns purch_tag_type AS $$

declare
  res purch_tag_type;
begin
  INSERT INTO purchase_tag (user_id, name) VALUES ($1, $2) returning * into res;
  return res;
end;
$$ LANGUAGE 'plpgsql';

-- ADD NEW PURCHASE
CREATE OR REPLACE FUNCTION create_purchase(
  	user_id VARCHAR(100),
 	name VARCHAR (100),
	price DECIMAL,
	currency VARCHAR (3),
	description VARCHAR (255) default null,
	tag_id INTEGER default null
) returns purchase_type AS $$

declare
  res purchase_type;
begin
	WITH rows AS (
		INSERT INTO purchase AS p (user_id, name, price, currency, description, tag_id) VALUES ($1, $2, $3, $4, $5, $6) 
		returning *
	)
	SELECT r.id, r.user_id as userid, r.name, r.price, r.currency, r.description, pt.name as tag FROM rows r JOIN purchase_tag pt ON pt.id = r.tag_id INTO res;
  	return res;
end;
$$ LANGUAGE 'plpgsql';

-- GET PURCHASES BY user_id
CREATE OR REPLACE FUNCTION get_purchases(
  	user_id VARCHAR(100)
) returns setof purchase_type AS $$

declare
  res purchase_type;
begin
	for res in
		SELECT p.id, p.user_id as userid, p.name, p.price, p.currency, p.description, pt.name as tag 
		FROM purchase p JOIN purchase_tag pt ON pt.id = p.tag_id 
		WHERE p.user_id = $1
    loop
        return next res;
    end loop;

end;
$$ LANGUAGE 'plpgsql';