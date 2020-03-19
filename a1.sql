-- Q1 
create or replace view Q1(pid, firstname, lastname) as

SELECT p.pid, p.firstname, p.lastname 
FROM person p, Client c, Staff s
WHERE p.pid = c.pid AND p.pid = s.pid
ORDER BY p.pid ASC;


-- Q2

CREATE OR REPLACE VIEW tmp(pno, id, brand, premium) AS
select po.pno, i.id, i.brand, SUM(r.rate)
FROM insured_item i 
JOIN policy po ON (po.id = i.id)
JOIN coverage c ON (po.pno = c.pno)
JOIN rating_record r ON (r.coid = c.coid)
GROUP BY po.pno, i.brand, i.id
ORDER BY po.pno ASC;

CREATE or REPLACE VIEW tmp2 (brand, id, pno, premium) AS
select DISTINCT ON (t.brand)t.brand, t.id, t.pno, t.premium
FROM tmp t 
ORDER BY t.brand, t.premium DESC;

CREATE OR REPLACE VIEW Q2 (brand, id, pno, premium) AS
select * from tmp2 t
ORDER BY t.brand, t.id, t.pno ASC;

-- Q3

create or replace view Q3(pid, firstname, lastname) as

SELECT p.pid, p.firstname, p.lastname, u.wdate
FROM person p 
    JOIN staff s ON (p.pid = s.pid)
    LEFT JOIN underwritten_by u ON (u.sid = s.sid)
    LEFT JOIN underwriting_record ur ON (ur.urid = u.urid)
    LEFT JOIN policy po ON (po.pno = ur.pno)
    WHERE CURRENT_DATE - u.wdate > 365 OR  u.wdate IS NULL
    ORDER BY p.pid ASC;
;

create or replace view tmp3 (pid, firstname, lastname, wdate, urid) AS 
SELECT p.pid, p.firstname, p.lastname, ub.wdate, ub.urid
FROM person p
RIGHT JOIN staff s ON (p.pid = s.pid)
LEFT JOIN policy po ON (po.sid = s.sid)
LEFT JOIN underwriting_record ur ON (ur.pno = po.pno)
LEFT JOIN underwritten_by ub ON (ub.urid = ur.urid)
WHERE (ub.wdate - CURRENT_DATE) > 365 OR ub.wdate IS NULL
ORDER BY p.pid ASC;

select t.pid, t.firstname, t.lastname 
FROM tmp3 t 
JOIN (select t2.pid, t2.urid FROM tmp3 t2 
WHERE (t2.wdate - CURRENT_DATE) > 365 OR t2.wdate IS NULL)
t3 
ON t3.pid = t.pid
ORDER BY t.pid ASC;

-- Q4

-- TODO : what if we have multiple people living 
-- in the same suburb

select UPPER(p.suburb), COUNT(po.pno)        
FROM person p                      
JOIN client c ON (p.pid = c.pid AND p.state = 'NSW')   
JOIN insured_by i ON (i.cid = c.cid)  
JOIN policy po ON(po.pno = i.pno)
GROUP BY p.suburb
ORDER BY COUNT(po.pno), p.suburb;

-- Q5

create or replace view Q5(pno, pname, pid, firstname, lastname) as

select DISTINCT(p.pno), p.pname, pe.pid, pe.firstname, pe.lastname
FROM person pe
    JOIN staff s ON (pe.pid = s.pid)
    JOIN policy p ON (p.sid = s.sid)                --sold by
    JOIN rated_by rb ON (rb.sid = s.sid)            -- rated by
    JOIN underwriting_record ur ON (ur.pno = p.pno) -- underwritten by
ORDER BY p.pno ASC;

-- JOIN underwritten_by u ON (u.sid = s.sid)   -- underw by

-- select DISTINCT(p.pno), p.pname, pe.pid, pe.firstname, pe.lastname
-- FROM person pe, staff s, policy p, rated_by rb, underwritten_by u
-- WHERE pe.pid = s.pid AND p.sid = s.sid AND p.sid = rb.sid AND p.sid = u.sid AND rb.sid = s.sid AND rb.sid = s.sid
-- ORDER BY p.pno ASC;


-- Q6

create or replace view tmp6(pid, name, brand) as

SELECT p.pid , p.firstname ||' '|| p.lastname as name, i.brand
FROM policy po 
JOIN insured_item i ON (i.id = po.id)
JOIN staff s ON (s.sid = po.sid)
JOIN person p ON (p.pid = s.pid)
GROUP BY p.pid, i.brand
;

select t.pid, t.name, t.brand
FROM tmp6 t 
JOIN (select t2.pid FROM tmp6 t2 GROUP BY t2.pid 
HAVING COUNT(t2.brand) = 1)
t3
ON t.pid = t3.pid
ORDER BY t.pid ASC
;

-- Q7

create or replace view total(total) as
select COUNT (DISTINCT brand) FROM insured_item;

create or replace view tmp7(pid, name, cnt) as
SELECT p.pid, p.firstname ||' '|| p.lastname as name, COUNT (DISTINCT ii.brand)
FROM person p 
JOIN client c ON (p.pid = c.pid)
JOIN insured_by ib ON (ib.cid = c.cid)
JOIN policy po ON (po.pno = ib.pno)
JOIN insured_item ii ON (ii.id = po.id)
GROUP BY p.pid
ORDER BY p.pid ASC;

CREATE OR REPLACE VIEW Q7 (pid, name) AS
select t.pid, t.name
FROM tmp7 t, total tot
WHERE t.cnt = tot.total
ORDER BY t.pid ASC;

-- Q8


-- Q9

DISTINCT ON(p.pno)

create or replace view Q9 (pno, status, rid, rate) AS
select  p.pno, p.STATUS, rr.rid, rr.rate
FROM rating_record rr 
JOIN coverage c ON (rr.coid = c.coid)
JOIN policy p ON (p.pno = c.pno)
WHERE p.status = 'E' AND p.expirydate > CURRENT_DATE
;

create or replace function ratechange(Adj integer) returns integer
AS $$
declare ret_val integer;
BEGIN
    select COUNT(*) INTO ret_val
    FROM policy 
    WHERE status = 'E' AND expirydate > CURRENT_DATE AND effectivedate <= CURRENT_DATE;

    UPDATE rating_record, 
        (SELECT rid FROM rating_record
         WHERE rid IN 
            (SELECT rid FROM rating_record rr
            JOIN coverage c ON (c.coid = rr.coid)
            JOIN policy p ON (p.pno = c.pno)
            WHERE p.status = 'E' AND p.expirydate > CURRENT_DATE AND p.effectivedate <= CURRENT_DATE))
        AS change
    SET rating_record.rate = rating_record.rate + rating_record.rate*($1)/100.0
    WHERE rating_record.rid = change.rid;

    return ret_val;
END;
$$ LANGUAGE plpgsql; 


UPDATE rating_record
    SET rate = rating_record.rate + rating_record.rate*($1)/100.0
    select rr.rid, rr.coid, p.pno, p.status, p.expirydate, rr.rate
    FROM rating_record rr
    JOIN coverage c ON (c.coid = rr.coid)
    JOIN policy p ON (p.pno = c.pno)
    WHERE p.status = 'E' AND p.expirydate > CURRENT_DATE AND effectivedate <= CURRENT_DATE;


-- Q10

CREATE FUNCTION q10 () RETURNS trigger AS $trig_func$
    BEGIN 
    IF (TG_PO = 'UPDATE') THEN 


