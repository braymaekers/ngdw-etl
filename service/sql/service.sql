/* service tables */

CREATE TABLE service.dim_product (
	id int4 NULL,
	product_id varchar(6) NULL,
	product_name varchar(50) NULL,
	product_family varchar(24) NULL,
	product_group varchar(24) NULL
)
WITH (
	OIDS=FALSE
) ;
