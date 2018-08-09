
-- truncate table acquisition.cspartm_stg;
-- update acquisition.idl_file_control set control_row_count = null, row_count = null, status = null, status_description = null where status = 'success';

CREATE TABLE acquisition.idl_file_control (
	file_date int4 NULL,
	data_set varchar(64) NULL,
	control_row_count int4 NULL,
	row_count int4 NULL,
	status varchar(8) NULL,
	status_description varchar(256) NULL
)
WITH (
	OIDS=FALSE
) ;

INSERT INTO acquisition.idl_file_control (file_date,data_set,control_row_count,row_count,status,status_description) VALUES 
(20160102,'CSPARTM',NULL,NULL,NULL,NULL), (20160101,'CSPARTM',NULL,NULL,NULL,NULL);


CREATE TABLE acquisition.idl_file_metadata (
	data_set varchar(64) NULL,
	field varchar NULL,
	data_type varchar(32) NULL,
	format varchar(32) NULL
)
WITH (
	OIDS=FALSE
) ;

INSERT INTO acquisition.idl_file_metadata (data_set,field,data_type,format) VALUES 
('CSPARTM','id','integer',NULL), ('CSPARTM','name','string',NULL), ('CSPARTM','age','integer',NULL)
,('CSPARTM','role','string',NULL), ('CSPARTM','date_role','date','yyyyMMdd');

CREATE TABLE acquisition.idl_table_metadata (
	target_table varchar(64) NULL,
	field varchar(16) NULL
)
WITH (
	OIDS=FALSE
) ;


INSERT INTO acquisition.idl_table_metadata (target_table,field) VALUES 
('cspartm_stg','id'), ('cspartm_stg','name'), ('cspartm_stg','age'), ('cspartm_stg','role'), ('cspartm_stg','date_role');

CREATE TABLE acquisition.tcspartm_stg (
	id int4 NULL,
	"name" varchar(64) NULL,
	age int4 NULL,
	"role" varchar(64) NULL,
	date_role timestamp NULL,
	flag varchar(4) NULL
)
WITH (
	OIDS=FALSE
) ;

