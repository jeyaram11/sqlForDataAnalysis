--create stored procedure to return 
 --all reserve type IDs, even if they have no negative reserve amounts,
 --reserve bucket(medical, TD, PD,Expense, VR, Fatality)
 --number of reserve changes that have a negative amount 
 -- Average amount for negative amounts
CREATE PROCEDURE SPGetNegativeReserveType
AS
BEGIN 
	SELECT 
	  x.*, 
	  CASE WHEN RT.ParentID = 0 THEN RT.ReserveTypeCode ELSE RT2.ReserveTypeCode END AS reserveBucket
	FROM (
	SELECT 
		ReserveTypeID,
		SUM(CASE WHEN ReserveAmount < 0 THEN 1 ELSE 0 END) negativeReserveCount,
		AVG(CASE WHEN ReserveAmount < 0 THEN ReserveAmount ELSE NULL END) negativeReserveAverage
	FROM Reserve
	GROUP BY ReserveTypeID
	)x
	INNER JOIN ReserveType RT ON RT.reserveTypeID = x.ReserveTypeID 
	LEFT JOIN ReserveType RT2 ON RT2.reserveTypeID = RT.ParentID
END;

--add three paramenters to stored procedures 
	--count of negative reserve changes
	--reserve bucket 
	--maximum average negative amount

ALTER PROCEDURE SPGetNegativeReserveType
 @varNegativeReserveCount INT,
 @varReserveBucket VARCHAR(20) = NULL,
 @varMaximumAverageAmount FLOAT = NULL

AS
BEGIN 
	SELECT pre.ReserveTypeID,  pre.reserveBucket, pre.negativeReserveCount, pre.negativeReserveAverage
	FROM(
		SELECT 
		  x.*, 
		  CASE WHEN RT.ParentID = 0 THEN RT.ReserveTypeCode ELSE RT2.ReserveTypeCode END AS reserveBucket
		FROM (
		SELECT 
			ReserveTypeID,
			SUM(CASE WHEN ReserveAmount < 0 THEN 1 ELSE 0 END) negativeReserveCount,
			AVG(CASE WHEN ReserveAmount < 0 THEN ReserveAmount ELSE NULL END) negativeReserveAverage
		FROM Reserve
		GROUP BY ReserveTypeID
		)x
		INNER JOIN ReserveType RT ON RT.reserveTypeID = x.ReserveTypeID 
		LEFT JOIN ReserveType RT2 ON RT2.reserveTypeID = RT.ParentID
	)pre
	WHERE pre.negativeReserveCount = @varNegativeReserveCount
		AND (@varReserveBucket IS NULL OR pre.reserveBucket = @varReserveBucket)
		AND (@varMaximumAverageAmount IS NULL OR pre.negativeReserveAverage <= @varMaximumAverageAmount)
END 


EXEC SPGetNegativeReserveType 2, 'Medical', -100