--Project 2 
--Get the following information for each table 
-- Project 2 
-- Get the following information for each table 
-- Project 2 
-- Get the following information for each table 

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
        ELSE R.ReserveID 
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
    AND (CS.ClaimStatusID = 1 OR (CS.ClaimStatusID = 2 AND CL.ReopenedReasonID <> 3));
