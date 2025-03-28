/*Many claims require regular publishes on the Reserving Tool, so we need to develop a
procedure that will:
1. Identify which claims require regular publishes on the Reserving Tool
2. Calculate how many days left the current examiner has to complete a publish, or if the
publish is late, how many days a publish is overdue
3. Display key information related to these claims including the calculated fields in step 2
4. Accept parameters allowing users to see results for specific situations
The final query should filter out the claims that don’t require a publish, and should display the
required fields that will give us the information requested for this project.*/
--1 
SELECT * FROM 
	(
	SELECT pivotTable.*
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
	FROM Claimant Cl
	JOIN Claim C 
		ON cl.ClaimID = Cl.ClaimID
	JOIN ClaimStatus CS 
		On Cl.claimStatusID = CS.ClaimStatusID
	JOIN Users U 
		ON C.ExaminerCode = U.UserName
	JOIN Users users2 
		ON U.Supervisor = users2.UserName
	JOIN Users users3 
		ON users2.Supervisor = users3.UserName
	JOIN Office O
		ON U.OfficeID = O.OfficeID
	JOIN ClaimantType CT ON Cl.ClaimantTypeID = CT.ClaimantTypeID
	INNER JOIN
		Reserve R 
		ON R.ClaimantID = CL.ClaimantID
	LEFT JOIN
		ReserveType RT 
		ON RT.ReserveTypeID = R.ReserveTypeID
	LEFT JOIN
		Patient P 
		ON P.PatientID = CL.PatientID
	WHERE 
		(CS.ClaimStatusDesc = 'Open' OR (CS.ClaimStatusDesc = 'Re-Open' AND Cl.ReopenedReasonID != 3)
		AND O.OfficeDesc in ('San Francisco','San Diego','Sacramento'))
		
		)baseData
	Pivot 
	(
	 SUM(baseData.ReserveAmount)
		FOR baseData.ReserveCostID in([1],[2],[3],[4],[5])
	)pivotTable
)preTable 
WHERE 
	(ClaimantTypeDesc IN ('First Aid','Medical Only')) OR 
	(OfficeDesc = 'San Diego' AND Title like lower('%analyst%') AND ISNULL(1,0) + ISNULL(2,0) + ISNULL(3,0) + ISNULL(4,0) + ISNULL(5,0) > ReserveLimit) OR 
	(OfficeDesc IN ('Sacramento', 'San Francisco') AND 
	ISNULL(1,0) > 1000 OR 
	ISNULL(5,0) > 100 OR 
	ISNULL(2,0) + ISNULL(3,0) + ISNULL(4,0) > 0
	)


		
		                                                                                                                                                          