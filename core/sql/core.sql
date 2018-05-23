/* core tables */

CREATE TABLE core.product (
	product_name varchar(50) NULL,
	product_id varchar(6) NULL,
	product_family varchar(24) NULL,
	product_group varchar(24) NULL,
	id serial NOT NULL,
	CONSTRAINT product_pkey PRIMARY KEY (id)
)
WITH (
	OIDS=FALSE
) ;
