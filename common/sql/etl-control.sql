CREATE TABLE "etl-control".job (
	batch_id int4 NULL,
	v_job_name varchar(16) NULL,
	status varchar(16) NULL,
	checkpoint varchar(32) NULL,
	logtime timestamp NULL,
	ip_address text NULL,
	hostname text NULL
)
WITH (
	OIDS=FALSE
) ;


CREATE TABLE "etl-control"."pdi-job" (
	id_job int4 NULL,
	channel_id varchar(255) NULL,
	jobname varchar(255) NULL,
	status varchar(15) NULL,
	lines_read int8 NULL,
	lines_written int8 NULL,
	lines_updated int8 NULL,
	lines_input int8 NULL,
	lines_output int8 NULL,
	lines_rejected int8 NULL,
	errors int8 NULL,
	startdate timestamp NULL,
	enddate timestamp NULL,
	logdate timestamp NULL,
	depdate timestamp NULL,
	replaydate timestamp NULL,
	log_field text NULL
)
WITH (
	OIDS=FALSE
) ;
CREATE INDEX "IDX_pdi-job_1" ON "etl-control"."pdi-job" USING btree (id_job) ;
CREATE INDEX "IDX_pdi-job_2" ON "etl-control"."pdi-job" USING btree (errors, status, jobname) ;
