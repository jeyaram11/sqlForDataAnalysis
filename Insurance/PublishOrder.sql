--query to find the publish order of the claims and if they are handled from the start 
SELECT sub.ClaimNumber, sub.ClaimantID, sub.ReservingToolID
   , sub.ExaminerCode, sub.SupervisorCode, sub.ManagerCode
   , sub.ExaminerTitle, sub.SupervisorTitle, sub.ManagerTitle
   , sub.Office, sub.lastAssignedDate,sub.InitialProcessDate, sub.PublishedDate
   , row_Number() OVER (partition by ClaimantID order by PublishedDate asc) 
as PublishOrder
   , CASE WHEN try_convert(date, lastAssignedDate) <= try_convert(date, 
initialprocessdate) THEN 1 ELSE 0 END AS HandledFromStartFlag
   , LAG(PublishedDate,1) OVER (PARTITION BY ClaimNumber ORDER BY 
PublishedDate) as PreviousPublishedDate
  FROM(
 SELECT C.ClaimNumber, cl.ClaimantID, RT.ReservingToolID
    , x.newvalue as ExaminerCode, U2.Username as SupervisorCode, 
U3.Username as ManagerCode
    , U.Title as ExaminerTitle, U2.Title as SupervisorTitle, U3.Title as 
ManagerTitle
    , o.OfficeDesc as Office
    , y.lastAssignedDate
    , RT.EnteredOn as PublishedDate
    , cl.ClosedDate
    , cl.ClaimStatusID
    , min(r.processeddate) as InitialProcessDate FROM 
(
select pk, max(entrydate) as lastAssignedDate
from ClaimLog
where FieldName = 'examinercode'
group by pk 
) y 
INNER JOIN ClaimLog x on x.PK = y.PK AND x.EntryDate = y.lastAssignedDate  AND x.FieldName ='examinercode'
INNER JOIN Claim c on C.ClaimID = Y.PK
INNER JOIN Claimant cl ON cl.ClaimID  = c.ClaimID
INNER JOIN ReservingTool RT ON c.ClaimNumber = RT.ClaimNumber AND RT.IsPublished = 1
LEFT JOIN Reserve R ON cl.ClaimantID = R.ClaimantID
LEFT JOIN [Users] U ON x.newvalue = U.Username
   LEFT JOIN [Users] U2 ON U.Supervisor = U2.Username
   LEFT JOIN [Users] U3 ON U2.Supervisor = U3.Username
   LEFT JOIN [Office] O ON U.OfficeID = O.OfficeID
   WHERE 
    ((cl.closeddate is null) 
     OR (cl.ReopenedDate > cl.ClosedDate and cl.reopenedreasonid <> 3)
    )
    and r.EnteredBy not like 'DBA'
	GROUP BY C.ClaimNumber, cl.ClaimantID
    , RT.ReservingToolID, y.lastAssignedDate
    , x.newvalue, U2.Username, U3.Username
    , U.Title, U2.Title, U3.Title
    , o.officedesc
    , cl.ClosedDate
    , RT.EnteredOn
    , cl.ClaimStatusID
	)sub
	WHERE PublishedDate >=lastAssignedDate