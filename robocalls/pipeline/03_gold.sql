CREATE OR REFRESH MATERIALIZED VIEW complaints_by_state_month
COMMENT "Complaint volume by state and month"
TBLPROPERTIES ("quality" = "gold")
AS SELECT
  state,
  date_trunc('month', created_at)          AS month,
  count(*)                                 AS complaints,
  count(DISTINCT caller_id_number)         AS distinct_callers,
  sum(CASE WHEN method = 'Wireless' THEN 1 ELSE 0 END) AS wireless_complaints
FROM fcc_complaints_silver
WHERE state IS NOT NULL AND created_at IS NOT NULL
GROUP BY state, date_trunc('month', created_at);


CREATE OR REFRESH MATERIALIZED VIEW complaint_mix_by_month
COMMENT "Issue type and contact method mix over time"
TBLPROPERTIES ("quality" = "gold")
AS SELECT
  date_trunc('month', created_at)                        AS month,
  issue_type,
  method,
  count(*)                                               AS complaints,
  round(100.0 * count(*) / sum(count(*)) OVER (
    PARTITION BY date_trunc('month', created_at)
  ), 2)                                                  AS pct_of_month
FROM fcc_complaints_silver
WHERE created_at IS NOT NULL
GROUP BY ALL;


CREATE OR REFRESH MATERIALIZED VIEW repeat_reported_numbers
COMMENT "Caller IDs reported across multiple states — spoofing and campaign signal"
TBLPROPERTIES ("quality" = "gold")
AS SELECT
  caller_id_number,
  count(*)                                  AS total_complaints,
  count(DISTINCT state)                     AS states_reporting,
  min(created_at)                           AS first_reported_at,
  max(created_at)                           AS last_reported_at,
  datediff(max(created_at), min(created_at)) AS active_days
FROM fcc_complaints_silver
WHERE caller_id_number IS NOT NULL
  AND length(regexp_replace(caller_id_number, '[^0-9]', '')) >= 10
GROUP BY caller_id_number
HAVING count(*) >= 5;