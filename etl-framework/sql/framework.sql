/* framework tables */

CREATE TABLE job_control (
	batch_id int4 NULL,
	scale_up varchar(32) NULL,
	main_job_project varchar(64) NULL,
	main_job_name varchar(256) NULL,
	work_unit_project varchar(64) NULL,
	work_unit varchar(256) NULL,
	work_unit_instance varchar(124) NULL,
	status varchar(32) NULL,
	starttime timestamp NULL,
	logtime timestamp NULL,
	ip_address text NULL,
	hostname text NULL,
	pid int4 NULL
)
WITH (
	OIDS=FALSE
) ;

/* pdi logging tables */

CREATE TABLE log_channel (
	id_batch int4 NULL,
	channel_id varchar(255) NULL,
	log_date timestamp NULL,
	logging_object_type varchar(255) NULL,
	object_name varchar(255) NULL,
	object_copy varchar(255) NULL,
	repository_directory varchar(255) NULL,
	filename varchar(255) NULL,
	object_id varchar(255) NULL,
	object_revision varchar(255) NULL,
	parent_channel_id varchar(255) NULL,
	root_channel_id varchar(255) NULL
)
WITH (
	OIDS=FALSE
);

CREATE TABLE pdi_job (
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
CREATE INDEX "IDX_pdi_job_1" ON pdi_job USING btree (id_job) ;
CREATE INDEX "IDX_pdi_job_2" ON pdi_job USING btree (errors, status, jobname) ;


CREATE TABLE pdi_trans (
	id_batch int4 NULL,
	channel_id varchar(255) NULL,
	transname varchar(255) NULL,
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
CREATE INDEX "IDX_pdi_trans_1" ON pdi_trans USING btree (id_batch) ;
CREATE INDEX "IDX_pdi_trans_2" ON pdi_trans USING btree (errors, status, transname) ;
