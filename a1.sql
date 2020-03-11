-- Q1 
create or replace view Q1(pid, firstname, lastname) as
SELECT pid, firstname, lastname FROM person

ORDER BY pid ASC