use mavenfuzzyfactory;
#UTM Source, Campaign, Domain Breakdown 
SELECT 
	utm_source,
	utm_campaign,
	http_referer,
	COUNT(website_session_id) sessions
 FROM website_sessions
 WHERE created_at < '2012-04-12'
 GROUP BY utm_source,utm_campaign, http_referer
 ORDER BY sessions desc;
 
 #Traffic Source Coverstion Rate 
SELECT 
	COUNT(DISTINCT ws.website_session_id) sessions, 
    COUNT(DISTINCT o.order_id) orders, 
    COUNT(DISTINCT o.order_id) / COUNT(DISTINCT ws.website_session_id) * 100 cvr
FROM website_sessions ws 
	LEFT JOIN orders o 
		ON ws.website_session_id = o.website_session_id
    WHERE 
		ws.created_at < '2012-04-14' AND 
		utm_source = 'gsearch' AND 
        utm_campaign = 'nonbrand';

#Traffic Source Trending 
SELECT 
	YEAR(created_at) year,
	WEEK(created_at) week_start_date,
    MIN(DATE(created_at)) week_start_date,
	COUNT(DISTINCT website_session_id) sessions
FROM website_sessions
WHERE utm_source = 'gsearch' AND 
	  utm_campaign = 'nonbrand'	AND 
      created_at < '2012-05-12'
GROUP BY 1,2
ORDER BY 1,2;

#Bid Optimization for Paid Traffic device-level performance
SELECT 
	ws.device_type,
	COUNT(DISTINCT ws.website_session_id) sessions, 
    COUNT(DISTINCT o.order_id) orders,
    COUNT(DISTINCT o.order_id) / COUNT(DISTINCT ws.website_session_id) * 100  cvr
FROM 
	website_sessions ws 
LEFT JOIN 
	orders o ON ws.website_session_id =  o.website_session_id 
WHERE
	ws.created_at < '2012-05-11' AND 
	ws.utm_source = 'gsearch' AND 
    ws.utm_campaign = 'nonbrand'
GROUP BY 
	1;
    
#Trending w/ Granular segments 
SELECT 
    MIN(DATE(created_at)) week_start_date,
	count(CASE WHEN ws.device_type = 'desktop' THEN website_session_id ELSE NULL END) desktop_sessions,
	count(CASE WHEN ws.device_type = 'mobile' THEN website_session_id ELSE NULL END) mobile_sessions
FROM 
	website_sessions ws
WHERE 
	ws.created_at < '2012-06-09' AND 
	ws.created_at > '2012-04-15' AND 
    utm_source = 'gsearch' AND 
    utm_campaign = 'nonbrand'
GROUP BY 
	YEAR(created_at), WEEK(created_at)