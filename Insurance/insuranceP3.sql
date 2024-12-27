--project 3 
--find the totoal sum of the reserve changes separated by the  5 reserve type buckets
SELECT PivotTable.*
FROM (
SELECT 
    C.ClaimNumber,
    O.OfficeCode,
    O.OfficeDesc,
    U.FirstName,
    U.Title,
    U.Supervisor,
    Users3.UserName AS Manager,
    CS.ClaimStatusDesc,
    CONCAT(P.FirstName, ' ', P.LastName) AS Full_Name,
    CL.ReopenedDate,
    CT.ClaimantTypeDesc,
    U.ReserveLimit,
    R.ReserveAmount,
    CASE 
        WHEN RT.ParentID IN (1, 2, 3, 4, 5) THEN RT.ParentID
        ELSE RT.reserveTypeID
    END AS ReserveCostID
FROM
    Claimant CL
INNER JOIN
    Claim C 
    ON C.ClaimID = CL.ClaimID
INNER JOIN
    Users U 
    ON U.UserName = C.ExaminerCode
INNER JOIN
    Users Users2 
    ON U.Supervisor = Users2.UserName
INNER JOIN
    Users Users3 
    ON Users2.Supervisor = Users3.UserName
INNER JOIN
    Office O 
    ON U.OfficeID = O.OfficeID
INNER JOIN
    ClaimantType CT 
    ON CT.ClaimantTypeID = CL.ClaimantTypeID
INNER JOIN
    Reserve R 
    ON R.ClaimantID = CL.ClaimantID
LEFT JOIN
    ClaimStatus CS 
    ON CS.ClaimStatusID = CL.ClaimStatusID
LEFT JOIN
    ReserveType RT 
    ON RT.ReserveTypeID = R.ReserveTypeID
LEFT JOIN
    Patient P 
    ON P.PatientID = CL.PatientID
WHERE
    O.OfficeDesc IN ('Sacramento', 'San Francisco', 'San Diego')
    AND (RT.ParentID IN (1, 2, 3, 4, 5) OR RT.ReserveTypeID IN (1, 2, 3, 4, 5))
    AND (CS.ClaimStatusID = 1 OR (CS.ClaimStatusID = 2 AND CL.ReopenedReasonID <> 3))
	)BaseDate
PIVOT 
(
SUM(BaseDate.ReserveAmount)
	FOR BaseDate.ReserveCostID in ([1],[2],[3],[4],[5])
)PivotTable

--Project 3 II 
-- The claimant type is medical-only or First aid 
--Examiner in San Diego and total reserve amouunt > examiner reserve limit 
--examiner in Sacramento or sa francisco and at least on of 
		-- total medical reserves(bucket 1) > 800
		-- total expense reserves(bucket 5) > 100
		--There are positive reserves in any of the remaining reserve buckets (TD,PD,Rehab)

SELECT PivotTable.*
FROM (
SELECT 
    C.ClaimNumber,
    O.OfficeCode,
    O.OfficeDesc,
    U.FirstName,
    U.Title,
    U.Supervisor,
    Users3.UserName AS Manager,
    CS.ClaimStatusDesc,
    CONCAT(P.FirstName, ' ', P.LastName) AS Full_Name,
    CL.ReopenedDate,
    CT.ClaimantTypeDesc,
    U.ReserveLimit,
    R.ReserveAmount,
    CASE 
        WHEN RT.ParentID IN (1, 2, 3, 4, 5) THEN RT.ParentID
        ELSE RT.reserveTypeID
    END AS ReserveCostID
FROM
    Claimant CL
INNER JOIN
    Claim C 
    ON C.ClaimID = CL.ClaimID
INNER JOIN
    Users U 
    ON U.UserName = C.ExaminerCode
INNER JOIN
    Users Users2 
    ON U.Supervisor = Users2.UserName
INNER JOIN
    Users Users3 
    ON Users2.Supervisor = Users3.UserName
INNER JOIN
    Office O 
    ON U.OfficeID = O.OfficeID
INNER JOIN
    ClaimantType CT 
    ON CT.ClaimantTypeID = CL.ClaimantTypeID
INNER JOIN
    Reserve R 
    ON R.ClaimantID = CL.ClaimantID
LEFT JOIN
    ClaimStatus CS 
    ON CS.ClaimStatusID = CL.ClaimStatusID
LEFT JOIN
    ReserveType RT 
    ON RT.ReserveTypeID = R.ReserveTypeID
LEFT JOIN
    Patient P 
    ON P.PatientID = CL.PatientID
WHERE
    O.OfficeDesc IN ('Sacramento', 'San Francisco', 'San Diego')
    AND (RT.ParentID IN (1, 2, 3, 4, 5) OR RT.ReserveTypeID IN (1, 2, 3, 4, 5))
    AND (CS.ClaimStatusID = 1 OR (CS.ClaimStatusID = 2 AND CL.ReopenedReasonID <> 3))
	)BaseDate
PIVOT 
(
SUM(BaseDate.ReserveAmount)
	FOR BaseDate.ReserveCostID in ([1],[2],[3],[4],[5])
)PivotTable
WHERE PivotTable.ClaimantTypeDesc in ('First Aid','Medical-Only')
	OR 
	(PivotTable.OfficeDesc = 'San Diego'
	AND  ISNULL([1],0) +   ISNULL([2],0) +   ISNULL([3],0) +   ISNULL([4],0) +   ISNULL([5],0) >= PivotTable.ReserveLimit
	)
	OR
	(PivotTable.OfficeDesc IN ('Sacramento','San Francisco') 
	  AND (ISNULL([1],0) > 800  
		OR ISNULL([5],0) > 100 
		OR ISNULL([2],0) > 0 
		OR ISNULL([4],0)  > 0 
		OR  ISNULL([4],0) > 0 )
	)
