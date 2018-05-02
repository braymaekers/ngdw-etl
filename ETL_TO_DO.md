# ETL Framework Development TO-DOs
## tr_log_batch_id: DONE
* Also set V_PID to the current PID
	
## tr_upd_job_control + tr_upd_job_control_error: DONE
* Updates (key is jobname field) instead of inserts
  * New field: starttime, only gets a value at checkpoint = start  
		`ALTER TABLE pdi_control.job_control ADD COLUMN starttime TIMESTAMP	`
  * New input field in get variables  
		`pid	${V_PID}	Integer	#`
  * New field in table output   
		`ALTER TABLE pdi_control.job_control ADD COLUMN pid INTEGER`
		
## jb_start_actions
### DONE:
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
	`IF status = 'success' OR null THEN V_START_FLAG=1 AND V_RESTART_FLAG=0  
	IF status = 'error' THEN V_START_FLAG=1 AND V_RESTART_FLAG=1`  
  __`???How far should we go? Should we check the existence of the _processing table here + the fact that the data got correctly loaded into the core table?`__  
	`IF status = 'running' THEN`  
      * this could mean 2 things:
	    * The job is actually still running
		* The job is no longer running (eg. system failure) and the status is not correctly updated
	  * CURRENT SOLUTION:  
	    `IF runtime <= max_runtime THEN V_START_FLAG=0 AND V_RESTART_FLAG=0 (we leave it running)  
		IF runtime > max_runtime THEN <kill process> + update status to 'error' + V_START_FLAG=1 AND V_RESTART_FLAG=1`
### TO DO/IMPROVEMENT in case job is no longer running, but the status was not correctly updated
* If that is the case, we need to check if the _processing table still exists --> this would mean we need to reprocess
* If that table does not exist, it means it was processed correctly into core and we don't need to do a restart  
  `we check if the _processing table still exists  
  IF SO: we update status to error AND V_START_FLAG=1 AND V_RESTART_FLAG=1  
  IF NOT: we update status to success AND V_START_FLAG=1 AND V_RESTART_FLAG=0`   
* FOR SERVICE LOADS THERE MIGHT BE OTHER LOGIC WHICH WE DON'T KNOW YET
* Where do we set max_runtime? in job.properties or job_control table? If in job_control this means we need to have a job record in this table before we can run the job (init record)
  * job.properties used at this point (V_MAX_RUNTIME)
* I only tested the kitchen pid kill
  * Not yet tested the jobStop rest api on the Pentaho server
		
## jb_unit_of_work_wrapper --> jb_unit_of_work_wrapper_core: DONE
DONE:
* We need a specific version for CORE and SERVICE since restart actions are dependent on the layer
* For CORE:
  * IF V_RESTART_FLAG=1 THEN reprocess the existing _processing table
  * IF V_RESTART_FLAG=0 THEN create new _processing table
* This wrapper could be used per CORE load: 1 A table to 1 C table
  * This assumes the schedule is at the level of the core job. The last status will tell us if this core load completed successfully or not
	
NOT IMPLEMENTED YET:
* Wrapper for Service:
  * IF V_RESTART_FLAG=1 THEN reproces from the last successfull batch_id
  * IF V_RESTART_FLAG=0 THEN reproces from the last successfull batch_id
* Combined Core + Service load
  * If the scheduled job would combine the core and service load: than we could leverage the checkpoint (V_LAST_CHECKPOINT_REACHED) to tell us the last successfully reached checkpoint
  * If core completed successfully, we skip core
		
	??? At this point: no need for diethard's restartability feature
	??? With the current logic, you could have seperate core and service loads, or combined into one
	??? Since when they are ran seperate, V_RESTART would also be set, same as for combined process

## Proper local environment setup
* Linux VM per developerPentaho
* Correct Pentaho version
* DB2 database that hosts the DWH
* Will oracle be used for pdi_logging and pdi_control?
	
## Adding proper error handling to the ETL framework
* Making sure it leaves a good trace when something goes wrong
	
## Updating ETL framework scripts to shell
	
## Update all DLL for common tables

## Testing the deploy + repository setup
* Matching and non-matching repository structures
	
## git branch strategy

## AES Password encryption

## Applying all development conventions to the ETL framework
* colored notes in the jobs and transformations
* naming conventions
* variable name: only the ones from the framework do not have V_, all others do --> this is how I applied it, but might not be written down in dev-guidelines