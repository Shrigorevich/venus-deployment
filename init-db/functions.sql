
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

CREATE TYPE ch_type AS (
	id uuid, 
	status int,
	name varchar(144),
	description varchar(255),
	startdate DATE,
	enddate DATE,
	days JSON
);

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