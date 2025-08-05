1. create a folder first as if you are creating a schema in the db project of the ssdt
2. execute the following code
-- 1. Create partition function
CREATE PARTITION FUNCTION pf_EventDateRange (DATE)
AS RANGE RIGHT FOR VALUES
('2024-01-01', '2024-02-01', '2024-03-01', '2024-04-01');

-- 2. Create partition scheme
CREATE PARTITION SCHEME ps_EventDateScheme
AS PARTITION pf_EventDateRange
ALL TO ([PRIMARY]);  -- Can use multiple filegroups

-- 3. Rebuild clustered index to align with partition
CREATE CLUSTERED INDEX IX_YourTable_Clustered
ON YourTable (EventDate, PersonKey)  -- Partition column must be part of index key
ON ps_EventDateScheme (EventDate);


-- for non-clustered index
-- You can still have nonclustered indexes on other columns like DoctorId, ClinicId, etc.

-- But:

-- They won’t be partitioned unless explicitly created on the partition scheme.

-- If you need them to be aligned (partitioned), you must create them using:

CREATE NONCLUSTERED INDEX IX_DoctorId
ON YourTable (DoctorId)
ON ps_EventDateScheme (EventDate); -- align with partition