CREATE TEMPORARY VIEW fcc_complaints_clean AS
SELECT
  nullif(trim(id), '')                                    AS id,
  try_to_timestamp(ticket_created)                        AS ticket_created_at,
  try_to_timestamp(date_created)                          AS created_at,
  try_to_date(left(issue_date, 10))                       AS issue_date,
  try_to_timestamp(
    concat(left(issue_date, 10), ' ', upper(trim(issue_time))),
    'yyyy-MM-dd h:mm a'
  )                                                       AS issue_at,
  initcap(nullif(trim(issue_type), ''))                   AS issue_type,
  nullif(trim(method), '')                                AS method,
  upper(nullif(trim(state), ''))                          AS state,
  lpad(nullif(trim(zip), ''), 5, '0')                     AS zip,
  _source_file,
  _ingested_at
FROM STREAM(fcc_complaints_bronze);


CREATE OR REFRESH STREAMING TABLE fcc_complaints_silver
(
  CONSTRAINT valid_id       EXPECT (id IS NOT NULL) ON VIOLATION DROP ROW,
  CONSTRAINT valid_created  EXPECT (created_at IS NOT NULL) ON VIOLATION DROP ROW,
  CONSTRAINT plausible_date EXPECT (
    created_at >= timestamp'2010-01-01' AND created_at <= current_timestamp()
  ),
  CONSTRAINT valid_state    EXPECT (state IS NULL OR length(state) = 2)
)
COMMENT "Typed, deduplicated FCC robocall complaints — one row per complaint id"
TBLPROPERTIES ("quality" = "silver");


CREATE FLOW silver_upsert AS AUTO CDC INTO fcc_complaints_silver
FROM STREAM(fcc_complaints_clean)
KEYS (id)
SEQUENCE BY _ingested_at
STORED AS SCD TYPE 1;