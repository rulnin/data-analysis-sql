-- 1. List the cities in which there is no flights from Moscow ?
select distinct a.city ->> 'en' as city
from airports a
where a.city ->> 'en' <> 'Moscow'
order by city;

-- 2. Select airports in a time zone is in Asia / Novokuznetsk and Asia / Krasnoyarsk ?
select * from airports
where timezone in ('Asia/Novokuznetsk','Asia/Krasnoyarsk');

-- 3. Which planes have a flight range in the range from 3,000 km to 6,000 km ?
select * from aircrafts
where range between 3000 and 6000;

-- 4. Get the model , range,  and miles of every air craft exist in the Airlines database, notice that miles = range / 1.609  and round the result to 2 numbers after the float point?
select model,range,round(range/1/609.2)
as miles
from aircrafts;

-- 5. Return all infromation about air craft that has aircraft_code = 'SU9' and its range in miles ?
select *,round(range/1.69,2) as range_in_miles
from aircrafts
where aircraft_code='SU9';

-- 6. Calculate the Average tickets Sales?
select AVG(total_amount) as sales
from bookings;

-- 7. Return the number of seats in the air craft that has aircraft code = 'CN1' ?
select count (*)
from seats
where aircraft_code='CN1';

-- 8. Return the number of seats in the air craft that has aircraft code = 'SU9'  ?
select count (*)
from seats
where aircraft_code='SU9';

-- 9. Write a query to return the aircraft_code and the number of seats of each air craft ordered ascending?
select aircraft_code, count(*)
from seats
group by aircraft_code
ordey by count;

-- 10. calculate the number of seats in the salons for all aircraft models, but now taking into account the class of service Business class and Economic class.
select aircraft_code,fare_conditions,count(*)
from seats
group by aircraft_code,fare_conditions
order by aircraft_code, fare_conditions;

-- 11. What was the least day in tickets sales?
select book_date book_date, Sum(total_amount) as sales
from bookings
group by 1
order by 2
limit 1;
Another solution :
select min (total_amount)
from bookings;

-- 12. Determine how many flights from each city to other cities, return the the name of city and count of flights more than 50 order the data from the largest no of flights to the least?
SELECT (SELECT city ->> 'en' FROM airports WHERE airport_code =departure_airport) AS departure_city, COUNT(*)
FROM flights
GROUP BY (SELECT city ->> 'en' FROM airports WHERE airport_code =departure_airport)
HAVING count (*)>= 50
ORDER BY Count DESC;

-- 13. Return all flight details in the indicated day 2017-08-28 include flight count ascending order and departures count and when departures happen in arrivals count and when arrivals happen?
SELECT f.flight_no,f.scheduled_departure :: time AS dep_time,
f.departure_airport AS departures,f.arrival_airport AS arrivals,
count (flight_id)AS flight_count
FROM flights f
WHERE f.departure_airport = 'KZN'
AND f.scheduled_departure >= '2017-08-28' :: date
AND f.scheduled_departure <'2017-08-29' :: date
GROUP BY 1,2,3,4,f.scheduled_departure
ORDER BY flight_count DESC,f.arrival_airport,f.scheduled_departure;

-- 14. write a query to arrange the range of model of air crafts so  Short range is less than 2000, Middle range is more than 2000 and less than 5000 & any range above 5000 is long range?
SELECT model, range, 
CASE WHEN range <2000 THEN 'Short' 
WHEN range <5000 THEN 'Middle' 
ELSE 'Long '
END AS range
FROM aircrafts
ORDER BY model;

-- 15. What is the shortest flight duration for each possible flight from Moscow to St. Petersburg, and how many times was the flight delayed for more than an hour?
SELECT f.flight_no, (f.Scheduled_arrival - f.Scheduled_departure) AS scheduled_duration,
min(f.Scheduled_arrival - f.Scheduled_departure), max(f.Scheduled_arrival - f.Scheduled_departure),
sum(CASE WHEN f.actual_departure > f.scheduled_departure + INTERVAL '1 hour'THEN 1 ELSE 0 END) delays
FROM flights f
WHERE (SELECT city ->> 'en' FROM airports WHERE airport_code = departure_airport) = 'Moscow'
AND (SELECT city ->> 'en' FROM airports WHERE airport_code = arrival_airport) = 'St. Petersburg'
AND f.status = 'Arrived'
GROUP BY f.flight_no, (f.Scheduled_arrival - f.Scheduled_departure);

-- 16. Who traveled from Moscow (SVO) to Novosibirsk (OVB) on seat 1A yesterday, and when was the ticket booked?
-- The day before yesterday” is counted from the public.now value, not from the current date.
SELECT t.passenger_name, b.book_date
FROM bookings b
JOIN tickets t
ON t.book_ref = b.book_ref
JOIN boarding_passes bp
ON bp.ticket_no = t.ticket_no
JOIN flights f
ON f.flight_id = bp.flight_id
WHERE f.departure_airport = 'SVO' AND f.arrival_airport = 'OVB'
AND f.scheduled_departure::date = public.now()::date - INTERVAL '2 day'
AND bp.seat_no = '1A';

-- 17. Find the most disciplined passengers who checked in first for all their flights. Take into account only those passengers who took at least two flights ?
SELECT t.passenger_name, t.ticket_no
FROM tickets t
JOIN boarding_passes bp
ON bp.ticket_no = t.ticket_no
GROUP BY t.passenger_name, t.ticket_no
HAVING max(bp.boarding_no) = 1 AND count(*) > 1;

-- 18. Calculate the number of passengers and number of flights departing from one airport (SVO) during each hour on the indicated day 2017-08-02 ?
SELECT date_part ('hour', f.scheduled_departure) "hour",count (ticket_no) passengers_cnt,
count (DISTINCT f.flight_id) flights_cnt
FROM flights f
JOIN ticket_flights t ON f.flight_id = t.flight_id
WHERE f.departure_airport = 'SVO'
AND f.scheduled_departure >= '2017-08-02' :: date
AND f.scheduled_departure <'2017-08-03' :: date
GROUP BY date_part ('hour', f.scheduled_departure);

-- 19. Use SQL  joins to  return unique city name, flight_no, airport and timezone?
select distinct a.city, f.flight_no, airport_name as airport, a.timezone
from flights f
join airports a
on a.airport_code=f.departure_airport;

-- 20. How many people can be included into a single booking according to the available data?
SELECT tt.bookings_no,count(*)passengers_no
FROM (SELECT t.book_ref, count(*) bookings_no FROM tickets t GROUP BY t.book_ref) tt
GROUP BY tt.bookings_no
ORDER BY tt.bookings_no;

-- 21. Which combinations of first and last names occur most often? What is the ratio of the passengers with such names to the total number of passengers?
SELECT passenger_name, round( 100.0 * cnt / sum(cnt) OVER (), 2) AS percent
FROM (SELECT passenger_name, count(*) cnt  FROM tickets GROUP BY passenger_name) sub
ORDER BY percent DESC;

-- 22. What are the maximum and minimum ticket prices in all directions?
SELECT (SELECT city ->> 'en' FROM airports WHERE airport_code = f.departure_airport) AS departure_city, (SELECT city ->> 'en' FROM airports WHERE airport_code = f.arrival_airport) AS arrival_city, max (tf.amount), min (tf.amount)
FROM flights f
JOIN ticket_flights tf
ON f.flight_id = tf.flight_id
GROUP BY 1, 2
ORDER BY 1, 2;

-- 23. Get a list of airports in cities with more than one airport ?
SELECT aa.city ->> 'en'AS city, aa.airport_code, aa.airport_name ->> 'en' AS airport
FROM (SELECT city, count (*)FROM airports GROUP BY city HAVING count (*)> 1) AS a
JOIN airports AS aa
ON a.city = aa.city
ORDER BY aa.city, aa.airport_name;

-- 24. What will be the total number of different routes that are theoretically can be laid between all cities?
SELECT count (*)
FROM (SELECT DISTINCT city FROM airports) AS a1
JOIN (SELECT DISTINCT city FROM airports) AS a2
ON a1.city <> a2.city;

-- 25. Count the number of routes laid from the airports?
-- Firstly we will create View called cities as the following:
CREATE VIEW cities AS SELECT (SELECT city ->> 'en' FROM airports WHERE airport_code =departure_airport) AS departure_city, (SELECT city ->> 'en' FROM airports WHERE airport_code =arrival_airport) AS arrival_city
FROM flights
-- then add the following code:
SELECT departure_city, count (*)
FROM cities
GROUP BY departure_city
HAVING departure_city IN (SELECT city->> 'en' FROM airports )
ORDER BY count DESC;

-- 26. Suppose our airline marketers want to know how often there are different names among the passengers?
SELECT LEFT(passenger_name, STRPOS(passenger_name, ' ') - 1) AS firstname, COUNT (*)
FROM tickets
GROUP BY 1
ORDER BY 2 DESC;

-- 27. Which combinations of first names and last names separately occur most often? What is the ratio of the passengers with such names to the total number of passengers?
WITH p AS (SELECT left(passenger_name, position(' ' IN passenger_name)) AS passenger_name FROM tickets)
SELECT passenger_name, round( 100.0 * cnt / sum(cnt) OVER (), 2) AS percent
FROM (SELECT passenger_name,count(*) cnt FROM p GROUP BY passenger_name) t
ORDER BY percent DESC;