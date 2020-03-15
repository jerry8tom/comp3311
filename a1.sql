-- Q1 
create or replace view Q1(pid, firstname, lastname) as

SELECT p.pid, p.firstname, p.lastname 
FROM person p, Client c, Staff s
WHERE p.pid = c.pid AND p.pid = s.pid
ORDER BY p.pid ASC;


-- Q2
create or replace view Q2(brand, car_id, pno, premium) as

SELECT i.brand, i.id, p.pno, rr.rate
-- FROM insured_item i, policy p, rating_record rr, rated_by rb
-- WHERE rr.rid = rb.rid AND rb.sid = p.sid
-- GROUP BY i.brand
-- ORDER BY i.brand, i.id, p.pno ASC;

FROM insured_item i 
    JOIN policy p ON (i.id = p.id)
    JOIN staff s ON (p.sid = s.sid)
    JOIN rated_by rb ON (rb.sid = s.sid)
    JOIN rating_record rr ON (rb.rid = rr.rid)
    LEFT JOIN rating_record rr2 ON rr.rid = rr2.rid AND rr.rate<rr2.rate
WHERE rr2.rid is NULL
ORDER BY i.brand, i.id, p.pno ASC;

-- Q3
-- staff member who did not sell any poicy in 365 days
-- (pid, firstname, lastname) Person
-- 
--

create or replace view Q3(pid, firstname, lastname) as

SELECT p.pid, p.firstname, p.lastname
FROM person p, 


-- Q4

select UPPER(p.suburb), COUNT(po.pno)        
FROM person p                       
JOIN client c ON (p.pid = c.pid AND p.state = 'NSW')   
JOIN insured_by i ON (i.cid = c.cid)  
JOIN policy po ON(po.pno = i.pno)
GROUP BY p.suburb   
ORDER BY COUNT(po.pno), p.suburb;

-- Q5

create or replace view Q5(pno, pname, pid, firstname, lastname) as

select p.pno, p.pname, per.pid, pe.firstname, pe.lastname
FROM person pe
    JOIN staff s ON (pe.pid = s.pid)
    JOIN policy p ON (p.sid = s.sid)            --sold by
    JOIN rated_by rb ON (rb.sid = s.sid)        -- rated by
    JOIN underwritten_by u ON (u.sid = s.sid)   -- underw by
ORDER BY p.pno ASC;

select p.pno, p.pname, pe.pid, pe.firstname, pe.lastname
FROM person pe, staff s, policy p, rated_by rb, underwritten_by u
WHERE pe.pid = s.pid AND p.sid = s.sid AND rb.sid = s.sid AND u.sid = s.sid
ORDER BY p.pno ASC; 
-- Q6








