-- For each ticket, display all the included flight segments, together with connection time. Limit the result to the tickets booked a week ago?
SELECT tf.ticket_no, f.departure_airport, f.arrival_airport, f.scheduled_arrival,
lead(f.scheduled_departure) OVER w AS next_departure,
lead(f.scheduled_departure) OVER w - f.scheduled_arrival AS gap
FROM bookings b
JOIN tickets t
ON t.book_ref = b.book_ref
JOIN ticket_flights tf
ON tf.ticket_no = t.ticket_no
JOIN flights f
ON tf.flight_id = f.flight_id
WHERE b.book_date = public.now()::date - INTERVAL '7 day'
WINDOW w AS (PARTITION BY tf.ticket_no
             ORDER BY f.scheduled_departure);

-- Find the most disciplined passengers who checked in first for all their flights. Take into account only those passengers who took at least two flights?
SELECT t.passenger_name, t.ticket_no
FROM tickets t
JOIN boarding_passes bp
ON bp.ticket_no = t.ticket_no
GROUP BY t.passenger_name,t.ticket_no
HAVING max(bp.boarding_no) = 1 AND count(*) > 1;

-- Which flights had the longest delays?
SELECT f.flight_no,  f.scheduled_departure, f.actual_departure,
(f.actual_departure - f.scheduled_departure) AS delay
FROM  flights f
WHERE f.actual_departure IS NOT NULL
ORDER BY f.actual_departure - f.scheduled_departure ;

-- How many seats remained free on flight PG0404 in the day before the last in the airlines database?
SELECT count(*)
FROM (SELECT s.seat_no FROM  seats s 
WHERE s.aircraft_code = (SELECT aircraft_code 
FROM  flights 
WHERE flight_no = 'PG0404'
AND scheduled_departure::date = public.now()::date - INTERVAL '1 day')
EXCEPT
SELECT bp.seat_no
FROM boarding_passes bp
WHERE bp.flight_id = (SELECT flight_id 
FROM  flights                                     
WHERE flight_no = 'PG0404'                                     
AND scheduled_departure::date = public.now()::date - INTERVAL '1 day')) t; 

-- How many seats remained free on flight PG0404 in the day before the last in the airlines database?
SELECT count(*)
FROM flights f
JOIN seats s
ON s.aircraft_code = f.aircraft_code
WHERE f.flight_no = 'PG0404'
AND f.scheduled_departure::date = public.now()::date - INTERVAL '1 day'
AND NOT EXISTS (SELECT NULL FROM boarding_passes bp
WHERE bp.flight_id = f.flight_id
AND bp.seat_no = s.seat_no);

-- what is the different between the tables created using VIEWS and the tables created using SELECT INTO ?
