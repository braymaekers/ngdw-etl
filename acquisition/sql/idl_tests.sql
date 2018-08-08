
-- truncate table acquisition.role;
-- update acquisition.idl_file_control set control_row_count = null, row_count = null, status = null, status_description = null where status = 'success';

CREATE TABLE acquisition.idl_file_control (
	file_date int4 NULL,
	filename varchar(64) NULL,
	control_row_count int4 NULL,
	row_count int4 NULL,
	status varchar(8) NULL,
	status_description varchar(256) NULL
)
WITH (
	OIDS=FALSE
) ;

INSERT INTO acquisition.idl_file_control (file_date,filename,control_row_count,row_count,status,status_description) VALUES 
(20160102,'role',NULL,NULL,NULL,NULL), (20160101,'role',NULL,NULL,NULL,NULL);


CREATE TABLE acquisition.idl_file_metadata (
	filename varchar(64) NULL,
	field varchar NULL,
	data_type varchar(32) NULL,
	format varchar(32) NULL
)
WITH (
	OIDS=FALSE
) ;

INSERT INTO acquisition.idl_file_metadata (filename,field,data_type,format) VALUES 
('role','id','integer',NULL), ('role','name','string',NULL), ('role','age','integer',NULL)
,('role','role','string',NULL), ('role','date_role','date','yyyyMMdd');

CREATE TABLE acquisition.idl_table_metadata (
	target_table varchar(64) NULL,
	field varchar NULL
)
WITH (
	OIDS=FALSE
) ;


INSERT INTO acquisition.idl_table_metadata (target_table,field) VALUES 
('role','id'), ('role','name'), ('role','age'), ('role','role'), ('role','date_role');;

CREATE TABLE acquisition."role" (
	id int4 NULL,
	"name" text NULL,
	age int4 NULL,
	"role" text NULL,
	date_role timestamp NULL
)
WITH (
	OIDS=FALSE
) ;
