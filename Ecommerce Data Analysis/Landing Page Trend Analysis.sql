#Comparing the bounce back rate both landing pages weekly
use mavenfuzzyfactory;


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
	wp.created_at >= '2012-06-01' AND 
    wp.created_at < '2012-08-31'  AND 
    ws.utm_source = 'gsearch' AND 
    ws.utm_campaign = 'nonbrand'
group by
	1),
landing_page_records AS  #find the total number of sessions 
(
SELECT 
    wp.created_at,
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
	MIN(date(lpr.created_at)) _week, 
	COUNT(DISTINCT CASE WHEN lpr.landing_page = '/home' THEN lpr.website_session_id end) home_sessions,
	COUNT(DISTINCT CASE WHEN lpr.landing_page = '/lander-1' THEN lpr.website_session_id end) lander_sessions,
    COUNT(DISTINCT bs.website_session_id)/ COUNT(DISTINCT lpr.website_session_id) * 100 bounce_rate
FROM 
	landing_page_records lpr
	LEFT JOIN bounced_sessions bs ON lpr.website_session_id = bs.website_session_id
GROUP BY 
    YEAR(lpr.created_at),
	WEEK(lpr.created_at)