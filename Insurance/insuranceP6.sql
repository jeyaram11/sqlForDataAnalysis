--added stored procedure 
CREATE PROCEDURE SPGetOutStandingRTPublish 
@varDaysToComplete INT = NULL,
@varDaysOverdue INT = NULL,
@varOffice varchar(20) = NULL, 
@varManagerCode varchar(20) = NULL,
@varSupervisorCode varchar(20) = NULL,
@varExaminerCode varchar(20) = NULL,
@varTeam varchar(200) = NULL,
@varClaimsWithoutReservePublish BIT = 0
AS 
BEGIN 
	DECLARE @asOf Date
	set @asOf = '01/01/2019'

	DECLARE @reservingToolTbl TABLE 
	(
	   claimNumber VARCHAR(30),
	   lastPublishedDate DATETIME 
	);

	DECLARE @assignedDateTbl TABLE 
	(
		PK int,
		assignedDate DATETIME 
	);

	INSERT INTO @reservingToolTbl
	SELECT ClaimNumber,
		max(EnteredOn) AS lastPublishedOn
		FROM Insurance.dbo.ReservingTool
	WHERE IsPublished = 1
	GROUP BY ClaimNumber;


	INSERT INTO @assignedDateTbl
	SELECT PK, EntryDate FROM (
		SELECT *, 
			ROW_NUMBER() OVER(Partition by PK Order BY EntryDate DESC) AS _order_ FROM Insurance.dbo.ClaimLog
	WHERE FieldName = 'ExaminerCode'
				)_orderedlist_
	WHERE _order_ = 1
SELECT 
			pre.*
		FROM 
		(
	SELECT  
		claimNumber,
		managerCode,
		managerTitle,
		manager,
		supervisorCode,
		supervisorTitle
		supervisor,
		examinerCode,
		examinerTitle,
		examinerName
		office,
		claimStatus,
		claimantType,
		examinerAssignedDate,
		claimReopenedDate,
		adjustedAssignedDate,
		lastPublishedDate,
		DaysSinceAdjustedAssigned,
		DaysSinceLastPublished,
		--days overdue/complete using case statement
		CASE WHEN DaysSinceAdjustedAssigned > 14 AND (DaysSinceLastPublished > 90 OR DaysSinceLastPublished IS NULL) THEN 0 
			WHEN 91 - DaysSinceLastPublished >= 15 -DaysSinceAdjustedAssigned AND DaysSinceLastPublished IS NOT NULL
			 THEN 91 - DaysSinceLastPublished 
			 ELSE 15- DaysSinceAdjustedAssigned
			 END AS daysToComplete,
		CASE WHEN DaysSinceAdjustedAssigned <= 14 OR (DaysSinceLastPublished <= 90 AND DaysSinceLastPublished IS NOT NULL) THEN 0
			WHEN DaysSinceLastPublished - 90 <= DaysSinceAdjustedAssigned - 14  AND DaysSinceLastPublished IS NOT NULL THEN DaysSinceLastPublished - 90
			ELSE DaysSinceAdjustedAssigned - 14 
			END AS daysOverDue,
		--days overdue/complete using table 
		(SELECT MAX(daysleft)
		FROM( values(91-DaysSinceLastPublished),(15-DaysSinceAdjustedAssigned),(0)) as daysTable(daysLeft)
		) daysToCompleteAlt,
		(SELECT min(daysOverdue)
		FROM( values(DaysSinceLastPublished - 90),(DaysSinceAdjustedAssigned - 14),(CASE WHEN DaysSinceAdjustedAssigned <= 14 OR (DaysSinceLastPublished <= 90 AND DaysSinceLastPublished IS NOT NULL) THEN 0 end)) as daysTable(daysOverdue) where daysOverdue > 0 or daysOverdue = 0
	) daysOverdueAlt 
	FROM (
	SELECT 
		C.ClaimNumber claimNumber,
		O.OfficeCode,
		O.OfficeDesc office,
		U.UserName examinerCode,
		U.FirstName examinerName,
		U.Title examinerTitle,
		U.Supervisor supervisor,
		users2.UserName supervisorCode,
		Users2.Title supervisorTitle,
		Users3.UserName AS manager,
		Users3.Title AS managerTitle,
		Users3.UserName managerCode,
		CS.ClaimStatusDesc claimStatus,
		CONCAT(P.FirstName, ' ', P.LastName) AS Full_Name,
		CL.ReopenedDate,
		CT.ClaimantTypeDesc claimantType,
		U.ReserveLimit,
		R.ReserveAmount,
		CASE 
			WHEN RT.ParentID IN (1, 2, 3, 4, 5) THEN RT.ParentID
			ELSE RT.reserveTypeID
		END AS ReserveCostID,
		aDT.assignedDate examinerAssignedDate,
		CL.ReopenedDate claimReopenedDate,
			CASE 
		 WHEN CS.ClaimStatusDesc = 'Re-Open' AND CL.ReopenedDate IS NULL THEN aDT.assignedDate
		 WHEN CS.ClaimStatusDesc = 'Re-Open' AND CL.ReopenedDate > aDT.assignedDate THEN CL.ReopenedDate
		 ELSE  aDT.assignedDate
		 END AS  adjustedAssignedDate,
		 lastPublishedDate lastPublishedDate,
		CASE 
		 WHEN CS.ClaimStatusDesc = 'Re-Open' AND CL.ReopenedDate IS NULL THEN DATEDIFF(DAY, aDT.assignedDate, @asOf)
		 WHEN CS.ClaimStatusDesc = 'Re-Open' AND CL.ReopenedDate > aDT.assignedDate THEN DATEDIFF(DAY, CL.ReopenedDate, @asOf)
		 ELSE  DATEDIFF(DAY, aDT.assignedDate, @asOf)
		 END AS  DaysSinceAdjustedAssigned,
		 DATEDIFF(Day,lastPublishedDate,@asOf) DaysSinceLastPublished
	FROM
		Insurance.dbo.Claimant CL
	INNER JOIN Insurance.dbo.Claim C 
		ON C.ClaimID = CL.ClaimID
	INNER JOIN
		Insurance.dbo.Users U 
		ON U.UserName = C.ExaminerCode
	INNER JOIN
		Insurance.dbo.Users Users2 
		ON U.Supervisor = Users2.UserName
	INNER JOIN
		Insurance.dbo.Users Users3 
		ON Users2.Supervisor = Users3.UserName
	INNER JOIN
		Insurance.dbo.Office O 
		ON U.OfficeID = O.OfficeID
	INNER JOIN
		Insurance.dbo.ClaimantType CT 
		ON CT.ClaimantTypeID = CL.ClaimantTypeID
	INNER JOIN
		Insurance.dbo.Reserve R 
		ON R.ClaimantID = CL.ClaimantID
	INNER JOIN
		Insurance.dbo.ClaimStatus CS 
		ON CS.ClaimStatusID = CL.ClaimStatusID
	INNER JOIN
		Insurance.dbo.ReserveType RT 
		ON RT.ReserveTypeID = R.ReserveTypeID
	INNER JOIN
		Insurance.dbo.Patient P 
		ON P.PatientID = CL.PatientID
	LEFT JOIN @reservingToolTbl rTT
		ON rTT.claimNumber = C.ClaimNumber
	LEFT JOIN @assignedDateTbl aDT 
		ON aDT.PK = C.ClaimID
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
	WHERE PivotTable.claimantType in ('First Aid','Medical-Only')
		OR 
		(PivotTable.office = 'San Diego'
		AND  ISNULL([1],0) +   ISNULL([2],0) +   ISNULL([3],0) +   ISNULL([4],0) +   ISNULL([5],0) >= PivotTable.ReserveLimit
		)
		OR
		(PivotTable.office IN ('Sacramento','San Francisco') 
		  AND (ISNULL([1],0) > 800  
			OR ISNULL([5],0) > 100 
			OR ISNULL([2],0) > 0 
			OR ISNULL([4],0)  > 0 
			OR  ISNULL([4],0) > 0 )
		)
			)pre
		WHERE 
			(@varDaysToComplete IS NULL OR daysToComplete <= @varDaysToComplete) AND 
			(@varDaysOverdue IS NULL OR daysOverDue >= @varDaysOverdue) AND 
			(@varOffice IS NUll OR office = @varOffice) AND 
			(@varSupervisorCode IS NUll OR supervisorCode = @varSupervisorCode) AND 
			(@varExaminerCode IS NUll OR examinerCode = @varExaminerCode) AND 
			(@varTeam IS NULL OR examinerTitle like '%' + @varTeam + '%' OR 
			managerTitle like '%' + @varTeam + '%' OR 
			supervisor like '%' + @varTeam + '%' )	AND 
			(@varClaimsWithoutReservePublish = 0 OR lastPublishedDate IS NULL)

END;

EXEC SPGetOutStandingRTPublish @varDaysToComplete =100, @varTeam = 'support'
