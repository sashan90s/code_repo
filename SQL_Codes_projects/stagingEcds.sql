select * from cxsus.Ecds
where Departure_Date is not null


  SELECT 
*
FROM cxsus.Ecds
WHERE Organisation_Code_Provider in ('R0D','RBD') 
AND 
    Departure_Date > '2025-06-24'
AND 
    Department_Type = '01'