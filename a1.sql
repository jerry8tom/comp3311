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

CREATE OR REPLACE VIEW Q2 (brand, car_id, pno, premium) AS
select * from tmp2 t
ORDER BY t.brand, t.id, t.pno ASC;


-- Q3

CREATE OR REPLACE VIEW tmp3 (sid, wdate, pid) AS
select DISTINCT ON(s.sid) s.sid, ub.wdate, p.pid-- po.pno, ur.urid
FROM person p 
RIGHT JOIN staff s ON (p.pid = s.pid)
LEFT JOIN policy po ON (po.sid = s.sid)
LEFT JOIN underwriting_record ur ON (ur.pno = po.pno)
LEFT JOIN underwritten_by ub ON (ub.urid = ur.urid);

CREATE OR REPLACE VIEW Q3 (pid, firstname, lastname) AS
select p.pid, p.firstname, p.lastname 
FROM person p
JOIN tmp3 s ON (s.pid = p.pid)
WHERE s.wdate - CURRENT_DATE > 365 OR s.wdate IS NULL
ORDER BY p.pid ASC;


-- Q4


CREATE OR REPLACE VIEW Q4 (suburb, npolicies) AS
select UPPER(p.suburb), SUM(COUNT(po.pno)) OVER (PARTITION BY p.suburb) AS npol
FROM person p
JOIN client c ON (p.pid = c.pid AND p.state = 'NSW')
JOIN insured_by i ON (i.cid = c.cid)  
JOIN policy po ON(po.pno = i.pno)
GROUP BY p.suburb
ORDER BY npol, p.suburb;


-- Q5


CREATE OR REPLACE VIEW Q5(pno, pname, pid, firstname, lastname) AS

SELECT DISTINCT(p.pno), p.pname, pe.pid, pe.firstname, pe.lastname
FROM person pe
    JOIN staff s ON (pe.pid = s.pid)
    JOIN policy p ON (p.sid = s.sid)                --sold by
    JOIN rated_by rb ON (rb.sid = s.sid)            -- rated by
    JOIN underwriting_record ur ON (ur.pno = p.pno) -- underwritten by
ORDER BY p.pno ASC;


-- Q6


CREATE OR REPLACE VIEW tmp6(pid, name, brand) AS

SELECT p.pid , p.firstname ||' '|| p.lastname as name, i.brand
FROM policy po 
JOIN insured_item i ON (i.id = po.id)
JOIN staff s ON (s.sid = po.sid)
JOIN person p ON (p.pid = s.pid)
GROUP BY p.pid, i.brand;

CREATE OR REPLACE VIEW Q6 (pid, name, brand) AS

SELECT t.pid, t.name, t.brand
FROM tmp6 t 
JOIN (select t2.pid FROM tmp6 t2 GROUP BY t2.pid 
HAVING COUNT(t2.brand) = 1)
t3
ON t.pid = t3.pid
ORDER BY t.pid ASC;


-- Q7


CREATE OR REPLACE VIEW total(total) AS
SELECT COUNT (DISTINCT brand) FROM insured_item;

CREATE OR REPLACE VIEW tmp7(pid, name, cnt) AS
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


CREATE OR REPLACE VIEW Q9 (rid, coid, pno, status, expirydate, rate) AS
SELECT rr.rid, rr.coid, p.pno, p.status, p.expirydate, rr.rate
FROM rating_record rr
JOIN coverage c ON (c.coid = rr.coid)
JOIN policy p ON (p.pno = c.pno)
WHERE p.status = 'E' AND p.expirydate > CURRENT_DATE AND effectivedate <= CURRENT_DATE; 

CREATE OR REPLACE FUNCTION ratechange(Adj integer) RETURNS INTEGER
AS $$
declare ret_val integer;
BEGIN
    select COUNT(*) INTO ret_val
    FROM policy 
    WHERE status = 'E' AND expirydate > CURRENT_DATE AND effectivedate <= CURRENT_DATE;

    UPDATE rating_record
    SET rate = rating_record.rate*(1.0 + (Adj/100.0))
    WHERE rating_record.coid IN (select coid FROM q9);

    return ret_val;
END;
$$ LANGUAGE plpgsql;


-- Q10


-- all the staff that own a policy
CREATE OR REPLACE VIEW imposs (pno) AS
select po.pno
FROM policy po
JOIN insured_by i ON (i.pno = po.pno)
JOIN client c ON (c.cid = i.cid)
JOIN person p ON (p.pid = c.pid)
JOIN staff s ON (s.pid = p.pid);

-- policies which are not owned by staff
CREATE OR REPLACE VIEW poss (pno) AS
select p.pno
FROM policy p
WHERE p.pno NOT IN (select * from imposs);


CREATE FUNCTION q10 () RETURNS trigger AS $$
BEGIN
    IF EXISTS (SELECT * FROM poss WHERE poss.pno = OLD.pno) THEN
    UPDATE expirydate
    SET expirydate = expirydate + 30
    WHERE NEW.status = 'E' AND OLD.pno != NEW.pno;
    END IF;
return NEW;
END;
$$ language plpgsql;


CREATE TRIGGER trig 
AFTER UPDATE ON policy 
FOR EACH ROW EXECUTE PROCEDURE q10();


