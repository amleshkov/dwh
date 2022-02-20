# Проектная работа по курсу "DWH"

Ссылка на задание: https://docs.google.com/document/d/129RoD-SImtLBIUo0xn3S_GlKVJARHNWKHmfNslupLDc/edit


### Вводная часть
Описание файлов:
`DDL.sql` - скрипт создания необходимых объектов в БД;
`ERD.png` - ERD базы;
`ETL.ktr` - трансформация PDI для загрузки данных из базы bookings в DWH;
`ETL.png` - скриншот трансформации;
`README.md` - данный файл.

Для выполнения работы используется экземпляр БД PostgreSQL, запущенный в Docker-контейнере.
Порядок запуска и создания необходимых объектов в БД:
```bash
docker run -d -p 5432:5432 -e POSTGRES_PASSWORD=postgres --name postgres-new postgres:12
psql -f DDL.sql -h localhost -p 5432 -U postgres -W postgres
```
##### ERD
![ERD](https://github.com/amleshkov/dwh/blob/main/ERD.png?raw=true)
##### ETL
![ETL](https://github.com/amleshkov/dwh/blob/main/ETL.png?raw=true)


### Описание таблиц в БД
Все таблицы измерений, кроме dim_calendar имеют специальные атрибуты `start_ts`, `end_ts`, `is_current`, `version` и к ним применяется версионирование SCD второго типа.
##### dim_calendar
Сгенерированная таблица календаря
| атрибут | описание |
| ---------|----------|
|id       |Натуральный ключ в формате `yyyymmdd`|
|date|Дата в формате `yyyy-mm-dd`|
|epoch|UNIX timestamp|
|day_suffix|День месяца с суффиксом|
|day_of_week|Порядковй номер дня в неделе|
|day_of_month|Порядковй номер дня в месяце|
|day_of_quarter|Порядковй номер дня в квартале|
|day_of_year|Порядковй номер дня в году|
|week_of_month|Порядковй номер недели в месяце|
|week_of_year|Порядковй номер недели в году|
|month_actual|Номер месяца|
|month_name|Название месяца|
|month_name_short|Трехсимвольное сокращение названия месяца|
|quarter_actual|Номер квартала|
|quarter_name|Название квартала|
|year_actual|Год|
|first_day_of_week|Первый день недели|
|last_day_of_week|Последний день недели|
|first_day_of_month|Первый день месяца|
|last_day_of_month|Последний день месяца|
|first_day_of_quarter|Первый день квартала|
|last_day_of_quarter|Последний день квартала|
|first_day_of_year|Первый день года|
|last_day_of_year|Последний день года|
|mmyyyy|Часть даты в формате `mmyyyy`|
|mmddyyyy|Дата в формате `mmddyyyy`|
|weekend|Признак выходного дня (суббота и воскресенье)|

##### dim_passengers
Таблица-измерение по пассажирам
|атрибут|описание|
|-------|--------|
|id|Уникальный идентификатор записи|
|passenger_id|Идентификатор пассажира|
|first_name|Имя|
|last_name|Фамилия|
|phone|Номер телефона|
|email| E-mail|
|start_ts|Дата начала действия записи|
|end_ts|Дата окончания действия записи|
|is_current|Признак действительности записи|
|version|Версия записи|

##### dim_aircrafts
Таблица-измерение по самолетам
|атрибут|описание|
|-------|--------|
|id|Уникальный идентификатор записи|
|code|Трехсимвольный идентификатор самолета|
|name|Наименование модели|
|range|Предельная дальность полета|
|start_ts|Дата начала действия записи|
|end_ts|Дата окончания действия записи|
|is_current|Признак действительности записи|
|version|Версия записи|

##### dim_airports
Таблица-измерение по аэропортам
|атрибут|описание|
|-------|--------|
|id|Уникальный идентификатор записи|
|code|Трехсимвольный идентификатор аэропорта|
|name|Наименование аэропорта|
|city|Город расположения|
|longitude|Координата широты|
|latitude|Координата долготы|
|timezone|Зона поясного времени|
|start_ts|Дата начала действия записи|
|end_ts|Дата окончания действия записи|
|is_current|Признак действительности записи|
|version|Версия записи|

##### dim_tarrif
Таблица-измерение по типам тарифов
|атрибут|описание|
|-------|--------|
|id|Уникальный идентификатор записи|
|name|Наименование тарифа|
|start_ts|Дата начала действия записи|
|end_ts|Дата окончания действия записи|
|is_current|Признак действительности записи|
|version|Версия записи|

##### fact_flights
Таблица фактов по перелетам
|атрибут|описание|
|-------|--------|
|id|Уникальный идентификатор записи|
|passenger_id|Внешний ключ dim_passengers(id)|
|deaprture| Дата и время вылета|
|arrival| Дата и время прилета|
|departure_calendar|Внешний ключ dim_calendar(id), вылет|
|arrival_calendar|Внешний ключ dim_calendar(id), прилет|
|departure_delay|Задержка вылета в секундах|
|arrival_delay|Задержка прилета в секундах|
|aircraft|Внешний ключ dim_aircrafts(id)|
|departure_airport|Внешний ключ dim_arports(id), вылет|
|arrival_airport|Внешний ключ dim_arports(id), прилет|
|tariff|Внешний ключ dim_tariff(id)|
|amout|Стоимость|

##### validations
Справочник типов валидации данных
|атрибут|описание|
|-------|--------|
|id|Уникальный идентификатор записи|
|validation|Наименование проверки корректности данных|

##### inventory
Справочник таблиц схемы bookings
|атрибут|описание|
|-------|--------|
|id|Уникальный идентификатор записи|
|table|Наименование исходной таблицы в схеме bookings, откуда получена некорректная запись|

##### log_rejects
Таблица, содержащая данные, не прошешдшие валидацию
|атрибут|описание|
|-------|--------|
|id|Уникальный идентификатор записи|
|book_ref|Идентификатор бронирования|
|validation_id|Внешний ключ validations(id)|
|table_id|Внешний ключ inventory(id)|
|log_date|Дата и время создания записи|
|fields|json с исходными данными, не прошедшими проверку|

### Описание ETL
Все необходимые данные извлекаются из БД bookings с помощью запроса:
```sql
SELECT
    b.book_ref,
    f.actual_departure,
    f.actual_arrival,
    to_char(f.actual_departure, 'yyyymmdd')::int AS calendar_actual_departure,
    to_char(f.actual_arrival, 'yyyymmdd')::int AS calendar_actual_arrival,
    EXTRACT(epoch FROM (f.actual_departure - f.scheduled_departure))::int AS departure_delay,
    EXTRACT(epoch FROM (f.actual_arrival - f.scheduled_arrival))::int AS arrival_delay,
    b.total_amount,
    t.passenger_id,
    split_part(t.passenger_name, ' ', 1) as first_name,
    split_part(t.passenger_name, ' ', 2) as last_name,
    t.contact_data::json ->> 'phone' as phone,
    t.contact_data::json ->> 'email' as email,
    tf.fare_conditions,
    tf.amount,
    aa.airport_code AS a_airport_code,
    aa.airport_name AS a_airport_name,
    aa.city AS a_airport_city,
    aa.longitude AS a_airport_longitude,
    aa.latitude AS a_airport_latitude,
    aa.timezone AS a_airport_timezone,
    da.airport_code AS d_airport_code,
    da.airport_name AS d_airport_name,
    da.city AS d_airport_city,
    da.longitude AS d_airport_longitude,
    da.latitude AS d_airport_latitude,
    da.timezone AS d_airport_timezone,    
    a2.aircraft_code,
    a2.model,
    a2."range"
FROM bookings.bookings AS b
JOIN bookings.tickets AS t ON b.book_ref = t.book_ref
JOIN bookings.ticket_flights AS tf ON t.ticket_no = tf.ticket_no 
JOIN bookings.flights AS f ON f.flight_id = tf.flight_id
LEFT JOIN bookings.airports AS aa ON f.arrival_airport = aa.airport_code
LEFT JOIN bookings.airports AS da ON f.departure_airport = da.airport_code 
LEFT JOIN bookings.aircrafts AS a2 ON f.aircraft_code = a2.aircraft_code
WHERE f.status = 'Arrived'
```
Полученные данные проходят валидацию. Строки, не прошедшие валидацию помещаются в таблицу `dwh.log_rejects` в виде json, с обогащением информацией по идентификатору бронирования, идентификатору исходной таблицы схемы bookings и идентификатору типа проверки.
##### Описание проверок
|Проверка|Описание|
|-------|--------|
|passenger_id| Проверка на соответствие регулярному выражению `^\d{4}\s\d{6}$`|
|phone|Проверка на соответствие регулярному выражению `^\+\d+$`|
|email|Проверка валидность email (регулярное выражение)|
|passenger name| Проверка полей `first_name` и `last_name` регулярным выражением `^[A-Za-z]+$`|
|code|Проверка кода аэропорта регулярным выражением `^[A-Z]{3}$`|
|name|Проверка наименования аэропорта на `NOT NULL`|
|city|Проверка города аэропорта на `NOT NULL`|
|longitude, latitude| Проверка координат на `is numeric`|
|timezone|Проверка зоны поясного времени регулярным выражением `^[A-Za-z]+\/[A-Za-z]+$`|
|aircraft_code|Проверка кода самолета на `NOT NULL`|
|aircraft_name|Проверка наименования модели самолета на `NOT NULL`|
|range|Проверка дальности самолета на `is numeric`|
|tariff|Проверка класса обслуживания на `NOT NULL`|
|amount| Проверка стоимости на `is numeric` и `>1000`|

После успешного проходения проверок данные с помощью последовательных шагов Dimension Lookup/Update загружаются в таблицу `fact_flights` с одновременным заполнением таблиц измерений `dim_*`.