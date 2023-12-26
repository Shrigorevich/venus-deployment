CREATE TYPE ch_type AS (
	id uuid, 
	status int,
	name varchar(144),
	description varchar(255),
	startdate DATE,
	enddate DATE,
	days JSON
);

CREATE TYPE ch_day_type AS (
  id uuid, 
  status int,
  date DATE
);

CREATE TYPE user_tag_type AS (
  id INT,
  name VARCHAR(100)
);

CREATE TYPE purchase_type AS (
  id uuid,
  name VARCHAR (100),
  price DECIMAL, 
  discount DECIMAL,
  currency VARCHAR(3),
  unit VARCHAR(20),
  quantity DECIMAL,
  description VARCHAR (255),
  tags JSON
);

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
CREATE OR REPLACE FUNCTION create_user_tag(
  user_id VARCHAR(100),
  name VARCHAR (100)
) returns user_tag_type AS $$

declare
  res user_tag_type;
begin
  INSERT INTO user_tag as ut (user_id, name) VALUES ($1, $2) returning ut.id, ut.name into res;
  return res;
end;
$$ LANGUAGE 'plpgsql';

-- ADD NEW PURCHASE
CREATE OR REPLACE FUNCTION create_purchase(
	user_id VARCHAR(100),
 	name VARCHAR (100),
	price DECIMAL,
	currency VARCHAR (3),
	tag_ids INTEGER ARRAY,
	discount DECIMAL default null,
	unit varchar(20) default null,
	quantity DECIMAL default null,
	description VARCHAR (255) default null
) returns purchase_type AS $$

declare
  p_id uuid;
  res purchase_type;
  t_id integer;
begin
	INSERT INTO purchase AS p 
		(user_id, name, price, currency, discount, unit, quantity, description)
		VALUES ($1, $2, $3, $4, $6, $7, $8, $9) 
		returning id into p_id;
	
	FOREACH t_id IN ARRAY $5
	LOOP
		INSERT INTO purchase_tag(tag_id, purchase_id) values (t_id, p_id);
	END LOOP;
	
  SELECT p.id, p.name, p.price, p.discount, p.currency, p.unit, p.quantity, p.description, 
    COALESCE(
      json_agg(json_build_object(
      'id', ut.id,
      'name', ut.name)
      ) FILTER (WHERE ut.id IS NOT NULL), '[]'::JSON
    ) as tags
  INTO res
	FROM purchase p 
	LEFT JOIN purchase_tag pt ON pt.purchase_id = p.id
	LEFT JOIN user_tag ut ON pt.tag_id = ut.id
	WHERE p.user_id = $1 and p.id = p_id
	GROUP BY p.id;
	
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
		SELECT p.id, p.name, p.price, p.discount, p.currency, p.unit, p.quantity, p.description, 
      COALESCE(
        json_agg(json_build_object(
        'id', ut.id,
        'name', ut.name)
        ) FILTER (WHERE ut.id IS NOT NULL), '[]'::JSON
      ) as tags
    FROM purchase p 
    LEFT JOIN purchase_tag pt ON pt.purchase_id = p.id
    LEFT JOIN user_tag ut ON pt.tag_id = ut.id
    WHERE p.user_id = $1
    GROUP BY p.id
    loop
        return next res;
    end loop;
end;
$$ LANGUAGE 'plpgsql';