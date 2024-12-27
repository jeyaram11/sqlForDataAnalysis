--Project 1 
--Determine how long an examiner has until they are requried to use the reserving tool, and if thet are already past thier due date, how many days they have been overdue. Do this for all the claims assigned to all of our examiners.

--step 1 -- the last date a claimant re-opened claim 
Select ClaimantID,
	   ClosedDate,
	   ReopenedDate 
FROM Claimant

-- step 2 -- the date an examiner was assigned a claim 

SELECT * FROM (
	SELECT *, 
		ROW_NUMBER() OVER(Partition by PK Order BY EntryDate DESC) AS _order_ FROM ClaimLog
WHERE FieldName = 'ExaminerCode'
			)_orderedlist_
WHERE _order_ = 1


-- step 3 - the last date an examiner published on the reserving tool for each claim 

SELECT ClaimNumber,
	max(EnteredOn) AS LastSavedOn 
	FROM ReservingTool
WHERE IsSaved = 1
GROUP BY ClaimNumber
