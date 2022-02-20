DROP SCHEMA IF EXISTS dwh CASCADE;
CREATE SCHEMA dwh;

DROP TABLE IF EXISTS dwh.dim_calendar CASCADE;
CREATE TABLE dwh.dim_calendar (
    id int PRIMARY KEY,
    "date" date NOT NULL,
    epoch bigint NOT NULL,
    day_suffix varchar(4) NOT NULL,
    day_name varchar(15) NOT NULL,
    day_of_week int NOT NULL,
    day_of_month int NOT NULL,
    day_of_qurter int NOT NULL,
    day_of_year int NOT NULL,
    week_of_month int NOT NULL,
    week_of_year int NOT NULL,
    month_actual int NOT NULL,
    month_name varchar(9) NOT NULL,
    month_name_short char(3) NOT NULL,
    quarter_actual int NOT NULL,
    quarter_name varchar(9) NOT NULL,
    year_actual int NOT NULL,
    first_day_of_week date NOT NULL,
    last_day_of_week date NOT NULL,
    first_day_of_month date NOT NULL,
    last_day_of_month date NOT NULL,
    first_day_of_quarter date NOT NULL,
    last_day_of_quarter date NOT NULL,
    first_day_of_year date NOT NULL,
    last_day_of_year date NOT NULL,
    mmyyyy char(6) NOT NULL,
    mmddyyyy char(10) NOT NULL,
    weekend bool NOT NULL
);

INSERT INTO dwh.dim_calendar
SELECT TO_CHAR(ts, 'yyyymmdd')::INT AS id,
       ts AS date_actual,
       EXTRACT(EPOCH FROM ts) AS epoch,
       TO_CHAR(ts, 'fmDDth') AS day_suffix,
       TO_CHAR(ts, 'TMDay') AS day_name,
       EXTRACT(ISODOW FROM ts) AS day_of_week,
       EXTRACT(DAY FROM ts) AS day_of_month,
       ts - DATE_TRUNC('quarter', ts)::DATE + 1 AS day_of_quarter,
       EXTRACT(DOY FROM ts) AS day_of_year,
       TO_CHAR(ts, 'W')::INT AS week_of_month,
       EXTRACT(WEEK FROM ts) AS week_of_year,
       EXTRACT(MONTH FROM ts) AS month_actual,
       TO_CHAR(ts, 'TMMonth') AS month_name,
       TO_CHAR(ts, 'Mon') AS month_name_short,
       EXTRACT(QUARTER FROM ts) AS quarter_actual,
       CASE
           WHEN EXTRACT(QUARTER FROM ts) = 1 THEN 'First'
           WHEN EXTRACT(QUARTER FROM ts) = 2 THEN 'Second'
           WHEN EXTRACT(QUARTER FROM ts) = 3 THEN 'Third'
           WHEN EXTRACT(QUARTER FROM ts) = 4 THEN 'Fourth'
           END AS quarter_name,
       EXTRACT(YEAR FROM ts) AS year_actual,
       ts + (1 - EXTRACT(ISODOW FROM ts))::INT AS first_day_of_week,
       ts + (7 - EXTRACT(ISODOW FROM ts))::INT AS last_day_of_week,
       ts + (1 - EXTRACT(DAY FROM ts))::INT AS first_day_of_month,
       (DATE_TRUNC('MONTH', ts) + INTERVAL '1 MONTH - 1 day')::DATE AS last_day_of_month,
       DATE_TRUNC('quarter', ts)::DATE AS first_day_of_quarter,
       (DATE_TRUNC('quarter', ts) + INTERVAL '3 MONTH - 1 day')::DATE AS last_day_of_quarter,
       TO_DATE(EXTRACT(YEAR FROM ts) || '-01-01', 'YYYY-MM-DD') AS first_day_of_year,
       TO_DATE(EXTRACT(YEAR FROM ts) || '-12-31', 'YYYY-MM-DD') AS last_day_of_year,
       TO_CHAR(ts, 'mmyyyy') AS mmyyyy,
       TO_CHAR(ts, 'mmddyyyy') AS mmddyyyy,
       CASE
           WHEN EXTRACT(ISODOW FROM ts) IN (6, 7) THEN TRUE
           ELSE FALSE
           END AS weekend
FROM (SELECT '2000-01-01'::DATE + SEQUENCE.DAY AS ts
      FROM GENERATE_SERIES(0, 18262) AS SEQUENCE (DAY)
      GROUP BY SEQUENCE.DAY) DQ
ORDER BY 1;

DROP TABLE IF EXISTS dwh.dim_passengers CASCADE;
CREATE TABLE dwh.dim_passengers (
    id serial PRIMARY KEY,
    passenger_id varchar(11) UNIQUE,
    first_name TEXT,
    last_name TEXT,
    phone varchar(15) UNIQUE,
    email varchar(100),
    start_ts date,
    end_ts date,
    is_current bool,
    "version" int4 NOT NULL
);

DROP TABLE IF EXISTS dwh.dim_aircrafts CASCADE;
CREATE TABLE dwh.dim_aircrafts (
    id serial PRIMARY KEY,
    code varchar(3) UNIQUE,
    name varchar(50),
    "range" int,
    start_ts date,
    end_ts date,
    is_current bool,
    "version" int4 NOT NULL
);

DROP TABLE IF EXISTS dwh.dim_airports CASCADE;
CREATE TABLE dwh.dim_airports(
    id serial PRIMARY KEY,
    code varchar(3),
    "name" text,
    city varchar(30),
    longitude decimal,
    latitude decimal,
    timezone varchar(30),
    start_ts date,
    end_ts date,
    is_current bool,
    "version" int4 NOT NULL
);

DROP TABLE IF EXISTS dwh.dim_tariff CASCADE;
CREATE TABLE dwh.dim_tariff (
    id serial PRIMARY KEY,
    name varchar(20),
    start_ts date,
    end_ts date,
    is_current bool,
    "version" int4 NOT NULL
);

DROP TABLE IF EXISTS dwh.fact_flights CASCADE;
CREATE TABLE dwh.fact_flights (
    id serial PRIMARY KEY,
    passenger_id int NOT NULL REFERENCES dwh.dim_passengers(id),
    departure timestamptz NOT NULL,
    arrival timestamptz NOT NULL,
    arrival_calendar int NOT NULL REFERENCES dwh.dim_calendar(id),
    departure_calendar int NOT NULL REFERENCES dwh.dim_calendar(id),
    departure_delay int DEFAULT 0,
    arrival_delay int DEFAULT 0,
    aircraft int NOT NULL REFERENCES dwh.dim_aircrafts(id),
    arrival_airport int NOT NULL REFERENCES dwh.dim_airports(id),
    departure_airport int NOT NULL REFERENCES dwh.dim_airports(id),
    tariff int NOT NULL REFERENCES dwh.dim_tariff(id),
    amount decimal
);

DROP TABLE IF EXISTS dwh.validations CASCADE;
CREATE TABLE dwh.validations (
    id serial PRIMARY KEY,
    validation varchar(20)
);

INSERT INTO dwh.validations (validation)
VALUES
    ('passenger_id'),
    ('passenger_phone'),
    ('passenger_email'),
    ('passenger_name'),
    ('airport_code'),
    ('airport_name'),
    ('airport_city'),
    ('airport_longitude'),
    ('airport_latitude'),
    ('airport_timezone'),
    ('aircraft_code'),
    ('aircraft_name'),
    ('aircraft_range'),
    ('ticket_tariff'),
    ('ticket_amount');

DROP TABLE IF EXISTS dwh.inventory CASCADE;
CREATE TABLE dwh.inventory (
    id serial PRIMARY KEY,
    "table" varchar(30)
);

INSERT INTO dwh.inventory ("table")
VALUES 
    ('bookings.aircrafts'),
    ('bookings.airports'),
    ('bookings.boarding_passes'),
    ('bookings.bookings'),
    ('bookings.flights'),
    ('bookings.seats'),
    ('bookings.ticket_flights'),
    ('bookings.tickets');

DROP TABLE IF EXISTS dwh.log_rejects CASCADE;
CREATE TABLE dwh.log_rejects (
    id serial PRIMARY KEY,
    book_ref char(6),
    validation_id int NOT NULL REFERENCES dwh.validations(id),
    table_id int NOT NULL REFERENCES dwh.inventory(id),
    log_date timestamp DEFAULT now(),
    fields json
);
