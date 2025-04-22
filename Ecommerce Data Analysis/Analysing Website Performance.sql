#Top website Page 
SELECT 
	pageview_url,
    COUNT(DISTINCT website_pageview_id) sessions
FROM 
	website_pageviews
WHERE
	created_at < '2012-06-09'
GROUP BY 
	1
ORDER BY 
	2 DESC ;
    
    
#landing pages by sessions 
CREATE TEMPORARY TABLE IF NOT EXISTS sessions  AS (
WITH first_page_view  AS ( #find all the initial page for each session
SELECT 
	website_session_id,
    min(website_pageview_id) landing_page_id
FROM 
	website_pageviews
WHERE 
	created_at < '2012-06-12'
GROUP BY 
	1
)

SELECT  #find the count of landing page by sessions
	 wp.pageview_url,
     wp.website_session_id
FROM 
	first_page_view fpv
	JOIN website_pageviews wp 
	ON wp.website_pageview_id = fpv.landing_page_id
GROUP BY 
	1,2
);
#calculating bounce rate
CREATE TEMPORARY TABLE IF NOT EXISTS  bounced_sessions AS (
WITH first_page_view  AS ( #find all the initial page for each session
SELECT 
	website_session_id,
    min(website_pageview_id) landing_page_id
FROM 
	website_pageviews
WHERE 
	created_at < '2012-06-14'
GROUP BY 
	1
)

SELECT 
	fpv.website_session_id bounced_sessions,
    count(wp.website_pageview_id)
FROM 
	first_page_view fpv
     JOIN  website_pageviews wp ON wp.website_session_id = fpv.website_session_id 
GROUP BY 1 
HAVING count(wp.website_pageview_id) = 1
);

SELECT 
	COUNT(s.website_session_id) total_sessions,
    COUNT(bs.bounced_sessions) bounced_sessions,
    COUNT(bs.bounced_sessions) / COUNT(s.website_session_id) * 100 bounce_rate
FROM 
	sessions s 
	left join bounced_sessions bs 
    ON s.website_session_id = bs.bounced_sessions;
    
    #Comparing the bounce back rate both landing pages

SET  @min = (SELECT min(created_at) FROM website_pageviews WHERE pageview_url = '/lander-1');
SET @max = date('2012-07-28');

#1st find all of the landing page sessions
WITH 
	landing_page_records_pre AS(
SELECT 
	wp.website_session_id,
    min(website_pageview_id) website_pageview_id
FROM 
	website_pageviews wp
LEFT JOIN website_sessions ws ON wp.website_session_id = ws.website_session_id
WHERE 
	wp.created_at >= @min AND 
    wp.created_at < @max  AND 
    ws.utm_source = 'gsearch' AND 
    ws.utm_campaign = 'nonbrand'
group by
	1),
landing_page_records AS ( #find the total number of sessions 
SELECT 
	wp.pageview_url landing_page,
    wp.website_session_id 
FROM 
	landing_page_records_pre lpr
    JOIN website_pageviews wp 
		ON lpr.website_pageview_id = wp.website_pageview_id 
),
bounced_sessions AS (
SELECT 
	ws.website_session_id,
    count(ws.website_pageview_id) total_sessions
FROM 
	landing_page_records_pre lprp
    join website_pageviews ws ON lprp.website_session_id  = ws.website_session_id
GROUP BY 1
HAVING count(ws.website_pageview_id) = 1
)

SELECT 
	lpr.landing_page,
    COUNT(DISTINCT lpr.website_session_id) total_sessions,
    COUNT(DISTINCT bs.website_session_id) bounced_sessions,
    COUNT(DISTINCT bs.website_session_id) / COUNT(DISTINCT lpr.website_session_id) * 100 bounce_rate
FROM 
	landing_page_records lpr 
    LEFT JOIN bounced_sessions bs ON lpr.website_session_id = bs.website_session_id
GROUP BY 
	1