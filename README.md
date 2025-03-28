# sqlForDataAnalysis
Welcome to my SQL Data Analysis repository! This space showcases a collection of SQL projects aimed at transforming raw data into meaningful insights. From data cleaning and transformation to complex queries and reporting, each project demonstrates practical applications of SQL for business intelligence, data visualization, and performance optimization.

Projects
  -Insurance:
    At our Insurance company, the examiners are tasked with regularly using the Reserving Tool to help them estimate how much claim is going to cost the company.
    Our job is to determine how long an examiner has until they are required to use the reserving tool,  and if they are already past their due date, how many days they have been overdue. This needs to be done for all the claims assigned to all of our examiners.
     Key Takeaways: 
     -The procedure identifies outstanding claim reserves that need publication.
     -Filters claims dynamically based on various input parameters.
     -Uses PIVOT to transform reserve types into separate columns.
     -Applies business rules for overdue/completion days and claim inclusion.
     -Ensures only relevant claims are retrieved for specified offices.


## 1. Stored Procedure: Get Negative Reserve Type
```
 CREATE PROCEDURE SPGetNegativeReserveType
 @varNegativeReserveCount INT,
 @varReserveBucket VARCHAR(20) = NULL,
 @varMaximumAverageAmount FLOAT = NULL
AS
BEGIN
    SELECT ReserveTypeID, reserveBucket, negativeReserveCount, negativeReserveAverage
    FROM (
        SELECT ReserveTypeID,
            SUM(CASE WHEN ReserveAmount < 0 THEN 1 ELSE 0 END) AS negativeReserveCount,
            AVG(CASE WHEN ReserveAmount < 0 THEN ReserveAmount ELSE NULL END) AS negativeReserveAverage
        FROM Reserve
        GROUP BY ReserveTypeID
    ) AS x
    WHERE negativeReserveCount = @varNegativeReserveCount
        AND (@varReserveBucket IS NULL OR reserveBucket = @varReserveBucket)
        AND (@varMaximumAverageAmount IS NULL OR negativeReserveAverage <= @varMaximumAverageAmount)
END;
```

## 2. Claim Handling and Publish Order
```
SELECT ClaimNumber, ClaimantID, ExaminerCode, PublishedDate,
    ROW_NUMBER() OVER (PARTITION BY ClaimantID ORDER BY PublishedDate ASC) AS PublishOrder,
    LAG(PublishedDate) OVER (PARTITION BY ClaimNumber ORDER BY PublishedDate) AS PreviousPublishedDate,
    CASE WHEN TRY_CONVERT(DATE, LastAssignedDate) <= TRY_CONVERT(DATE, InitialProcessDate) THEN 1 ELSE 0 END AS HandledFromStartFlag
FROM ClaimLog
WHERE PublishedDate >= LastAssignedDate;

```

## 3. Using LAG() to Track Examiner Changes
```
SELECT ExaminerCode, PreviousExaminer,
    CASE WHEN ExaminerCode = PreviousExaminer THEN 'Handled from Start' ELSE 'Transferred' END AS Status
FROM (
    SELECT ExaminerCode,
        LAG(ExaminerCode) OVER (PARTITION BY ClaimNumber ORDER BY PublishedDate) AS PreviousExaminer
    FROM ClaimLog
) AS ExamLog;

```
## 4. Using ROW_NUMBER() for Ranking
```
SELECT ClaimNumber, PublishedDate,
    ROW_NUMBER() OVER (PARTITION BY ClaimNumber ORDER BY PublishedDate DESC) AS Rank
FROM ClaimLog;
```