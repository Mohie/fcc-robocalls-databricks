CREATE OR REFRESH STREAMING TABLE fcc_complaints_bronze
(
  CONSTRAINT valid_ticket_id EXPECT (id IS NOT NULL),
  CONSTRAINT has_date EXPECT (date_created IS NOT NULL),
  CONSTRAINT schema_violation EXPECT (_rescued_data IS NULL)
)
COMMENT "Raw FCC robocall complaints, ingested as-is with all columns as strings"
TBLPROPERTIES ("quality" = "bronze")
AS SELECT
  *,
  _metadata.file_path              AS _source_file,
  _metadata.file_modification_time AS _source_modified_at,
  current_timestamp()              AS _ingested_at
FROM STREAM read_files(
  "${dataset_path}",
  format => 'csv',
  header => true,
  multiLine => true,
  schema =>'id STRING,
    ticket_created STRING,
    date_created STRING,
    issue_date STRING,
    issue_time STRING,
    issue_type STRING,
    method STRING,
    issue STRING,
    caller_id_number STRING,
    type_of_call_or_messge STRING,
    advertiser_business_phone_number STRING,
    city STRING,
    state STRING,
    zip STRING,
    location_1 STRING,
    type_of_property_goods_or_services STRING',
  schemaEvolutionMode => 'rescue'
);