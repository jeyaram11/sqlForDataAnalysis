use QualityAnalysis

--main KPI 
SELECT 
    SUM(All_Task) AS total_tasks,
    SUM(Sample) AS sample_total,
    SUM(Defects) AS total_defects,
    SUM(Errors) AS total_errors,
    FORMAT(COALESCE((SUM(Errors) * 1.0) / NULLIF(SUM(Sample), 0), 0), 'P2') AS errors_pct, -- *1.0 ensure the divison is tread as a decimal calculation 
	FORMAT(COALESCE(SUM(Defects) * 1.0 / NULLIF(SUM(Sample),0),0),'P2') as Defects_pct,
	FORMAT(COALESCE(SUM(sample) * 1.0 / NULLIF(SUM(All_Task),0),0),'P2') as sampling_pct,
	FORMAT(1-(COALESCE(SUM(Defects) * 1.0 / NULLIF(SUM(Sample),0),0)), 'P2') as sampling_pct
FROM 
   data;

--break down data by month 

SELECT 
    DATEPART(month,Date) as _monthNo,
	FORMAT(Date,'MMMM')_Month,
    SUM(All_Task) AS total_tasks,
    SUM(Sample) AS sample_total,
    SUM(Defects) AS total_defects,
    SUM(Errors) AS total_errors,
    FORMAT(COALESCE((SUM(Errors) * 1.0) / NULLIF(SUM(Sample), 0), 0), 'P2') AS errors_pct, -- *1.0 ensure the divison is tread as a decimal calculation 
	FORMAT(COALESCE(SUM(Defects) * 1.0 / NULLIF(SUM(Sample),0),0),'P2') as Defects_pct,
	FORMAT(COALESCE(SUM(sample) * 1.0 / NULLIF(SUM(All_Task),0),0),'P2') as sampling_pct,
	FORMAT(1-(COALESCE(SUM(Defects) * 1.0 / NULLIF(SUM(Sample),0),0)), 'P2') as sampling_pct
 FROM 
 dbo.data
 GROUP BY  DATEPART(month,Date),FORMAT(Date,'MMMM')
 ORDER BY  DATEPART(month,Date)