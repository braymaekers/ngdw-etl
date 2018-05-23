# Documentation TO-DOs

* Updated version of the Dev-Guidelines document based on the feedback from HKEX
* First version of the ETL Technical Specification document
  * We will propose a table of contents to HKEX, after approval we can start documenting in detail

## DEV-environment Setup

* Citrix machine per developer
  * Windows VM
  * Software: Pentaho Design Tools, DB2 Express, DB2 SQL Client, Notedpad++
  * Missing: Gitlab, data for development, Jira setup
  * Will not be installed: Pentaho Server, Oracle DB (where control + pdi_logging will be sitting) --> from Citrix we can connect to these resources on D1
  * Problem at this point: VMs are very slow, not usable for development

## Product-Instrument ETL demo

* At this moment we do not yet have access to sample (p-like) data to start developing product_instrument as a demo for all future ETL activities
* We need to start developing this business area for multiple reasons: to validate data mapping activities, to make sure all info is there to start developing the ETL, to validate the ETL framework, to validate our ideas of processing the data into CORE
* Vanessa mentioned this data should be available beginning of next week (07/05/2018)

## Git Branching Strategy

* Needs to be further discussed and fine-tuned

## ETL Framework Development TO-DOs

### Switching pdi_control and pdi_logging to Oracle

### jb_start_actions_service

* **implemented**
* For service jobs there might be other start checks, but we don't know those yet
* **open_issue** Where do we set max_runtime of a job? in job.properties or job_control table or seperate table? If in job_control this means we need to have a job record in this table before we can run the job (init record) --> job.properties used at this point (V_MAX_RUNTIME)
* I only tested the kitchen pid kill
  * Not yet tested the jobStop rest api on the Pentaho server

### jb_unit_of_work_wrapper_service

* **implemented**
* Wrapper for Service:
  * IF V_RESTART_FLAG=1 THEN reproces from the last successfull batch_id
  * IF V_RESTART_FLAG=0 THEN reproces from the last successfull batch_id
* Combined Core + Service load
  * If the scheduled job would combine the core and service load: than we could leverage the checkpoint (V_LAST_CHECKPOINT_REACHED) to tell us the last successfully reached checkpoint
  * If core completed successfully, we skip core

### Batching framework for transaction loads

* This is under consideration

### Adding proper Write to log + error handling to the ETL framework

* Making sure it leaves a good trace when something goes wrong
* Making the log more debuggable
* specific key words needed for the monitoring tool

`14.	Ellis said Hitachi could use the format (e.g., keywords like ERROR, WARNING or INFORMATION) provided by HKEX to configure Pentaho so that the file log produced by PDI would conform to the syntax recognizable by BMC Patrol for monitoring.  It should be sufficient for BMC Patrol to monitor file logs (no need to monitoring PDI Logging Tables).`

### Updating ETL framework scripts to shell

### Update all DLL for common tables

### Testing the deploy + repository setup

* **done**
* Matching and non-matching repository structures

### AES Password encryption

* **done** and **tested**

### File Logging Level

* File logging is not controlled by variable, it is set on the job entry that triggers file logging. What we can control are 2 things:
  * For DB logging: we can say for which work units we want to do this: job, transformation, channel, step, job entry. For the ETL framework to work we need job logging. All others are optional. If the ETL Test Coverage solution will be used, at least step + channel is also required.
* For File logging: we can control the level (so the verbosity) + our ETL writes custom message to the log, we can control from what level they are shown as well)

### Applying all development conventions to the ETL framework

* colored notes in the jobs and transformations
* naming conventions
* variable names: they all start with V_

### Log table housekeeping job

* Remove logging lines older than x days
* Check how the batch_id gets generated, if it is max+1, we cannot truncate the table, but should only delete old lines

### Configuring log tables for concurrent access

https://wiki.pentaho.com/display/EAI/Configuring+log+tables+for+concurrent+access

## SAMPLE jb_product-instrument_core.kjb (core/content-pdi)

* Core example for acquisition table product
* Uses core/content-pdi/product-instrument/jb_product_core.kjb
* Empty demo table product: 

```sql
create table sales_dwh.product (id integer, name varchar(50));
```

* Different scenarios
  * First time run as usual via launcher
  * Second time, update job_control's status to error: since there is no \_processing table, he should do a regular start, no restart
  * Third time, update job_control's status to error and create the \_processing table, in this case he will do a restart
  * Fourth time: 
    * set core/content-pdi/product-instrument/jb_product_core.kjb's delay to 60 seconds
    * run the job with P_SCALE_UP=true
    * open a second spoon and launch the job again (10 seconds after the other started)
    * ==> since the max_runtime is set to 10 seconds, the second run will kill the first run's kitchen, and restart the load from the existing \_processing table

## ETL Framework Development - ALREADY COMPLETED

### tr_log_batch_id

* Also set V_PID to the current PID

### tr_upd_job_control + tr_upd_job_control_error

* Updates (key is jobname field) instead of inserts
  * New field: starttime, only gets a value at checkpoint = start  `ALTER TABLE pdi_control.job_control ADD COLUMN starttime TIMESTAMP	`
  * New input field in get variables `pid	${V_PID}	Integer	#`
  * New field in table output `ALTER TABLE pdi_control.job_control ADD COLUMN pid INTEGER`

### jb_start_actions_core

* Right now we only allow the main job to start when the last run's status = success OR null
* Right now it is assumed that if status is running, we don't start again AND if status is error we wait for a manual fix 
* --> we need to have an automated solution for both situations
* TO-BE: if status is running, we check if the runtime > max_runtime
  * If job is running on Pentaho server: we call the rest API to kill it and we update the status to error
  * If job is running on kitchen: we kill the kitchen pid and update the status of the job to error

* Solution:
  * In general:
    * status can only be: 'running', 'success' or 'error'
  * checkpoint can be anything, only serves the purpose of indicating progress
  * jb_start_actions will check the status of last load (and not the existence of the _processing table since this needs to be a generic solution for both CORE and SERVICE jobs)

```txt
`IF status = 'success' OR null THEN V_START_FLAG=1 AND V_RESTART_FLAG=0`
`IF status = 'error'  THEN`
  `IF snapshot table still exists (this must mean there was an error during the processing of the snapshot)
  THEN V_START_FLAG=1 AND V_RESTART_FLAG=1`
  `IF _processing table does not exist (this must mean the rename failed (snapshot never got created) OR something failed after the drop of the snapshot) 
  THEN V_START_FLAG=1 AND V_RESTART_FLAG=0`
`IF status = 'running' THEN`
    * This could mean 2 things:
    * The job is actually still running
  * The job is no longer running (eg. system failure) and the status is not correctly updated
  * Solution
    `IF runtime <= max_runtime THEN V_START_FLAG=0 AND V_RESTART_FLAG=0 (we leave it running)`
  `IF runtime > max_runtime THEN <kill process> + update status to 'error'`
      `IF snapshot table still exists THEN V_START_FLAG=1 AND V_RESTART_FLAG=1`
      `IF snapshot table does not exist THEN V_START_FLAG=1 AND V_RESTART_FLAG=0`
```

### jb_unit_of_work_wrapper_core: DONE

DONE:

* We need a specific version for CORE and SERVICE since restart actions are dependent on the layer
* For CORE:
  * IF V_RESTART_FLAG=1 THEN reprocess the existing _processing table
  * IF V_RESTART_FLAG=0 THEN create new _processing table
* This wrapper could be used per CORE load: 1 A table to 1 C table
  * This assumes the schedule is at the level of the core job. The last status will tell us if this core load completed successfully or not