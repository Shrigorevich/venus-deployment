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
  INSERT into challenge_day(challenge_id, status, date) VALUES (res_id, 4, start_date);

  if end_date IS NOT NULL then
    INSERT into challenge_day(challenge_id, status, date) VALUES (res_id, 4, end_date);
  end if;
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
      'date', cd.date,
      'id', cd.id) ORDER BY cd.date DESC
    ) AS days
    FROM challenge c JOIN challenge_day cd ON c.id = cd.challenge_id
    GROUP BY c.id
    loop
        return next res;
    end loop;

end; 
$$ LANGUAGE 'plpgsql';

-- ADD CHALLENGE_DAY 
CREATE OR REPLACE FUNCTION add_challenge_day(
	challenge_id varchar(50), 
	status INT, 
	date DATE
) returns ch_day_type AS $$

declare
	res ch_day_type;
begin
  INSERT into challenge_day as chd(challenge_id, status, date) VALUES (uuid($1), $2, $3) 
  returning id, chd.status, chd.date into res;
	return res;
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
  INSERT INTO purchase_tag as pt (user_id, name) VALUES ($1, $2) returning pt.id, pt.name into res;
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