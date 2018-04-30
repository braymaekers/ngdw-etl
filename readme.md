# ETL Framework Processing Rules
## Acquisition loads: 
* Taken care of by DB2 scripts
	* Data gets appended to tables (insert only)
	* As-is copy from source systems
	* No history is being kept: data gets discarded once processed
* Audit columns
	* *ngdw_id*: records get a unique ID assigned from sequence (no use for this number at this point beyond lineage)
	* *batch_id*: only when the DB2 scripts would get orchestrated with PDI

## Core loads: 
* Acquisition to Core
* We process the *_processing* tables
	* Since the acquisition tables could be continuously loaded (eg. hourly), we need to process the current snapshot of it while the core load starts. 
	* This snapshot needs to be untouched while the core load runs (and potentially needs to restart due to failure)
	* Therefore we would rename the current acquisition table to name_processing and create an empty name table (existing acquisition table). We do this as part of a transaction, making this table immutable to any other process.

*Eg.*
```sql 
BEGIN;
ALTER TABLE table1 RENAME TO table1_processing;
CREATE TABLE table1 AS TABLE table1_processing WITH NO DATA;
COMMIT;
```
*Because of the Begin and Commit we sent the sql script as a single transaction so no other database transaction can change the table.*

* __One core load might have multiple “processing” tables as input__
	* If this table(s) still exists, the last load failed. 
	* If this table(s) does not exists, the last load was successful
	* The same info (previous load = success or not) is also be present in the job_control table (checkpoint = error or finished) unless there was a system crash which avoided the ETL from updating the job_control table
		* What do we do in case of status = running: this can mean that the job is actually still running, or that the job died without updating the table? 
			* The next time the core load starts, it checks the status. If it is still running and the run time exceeds the normal limit (will be configurable) the current process would be killed (to make sure it is actually no longer running) (Pentaho server: stop job REST API; Kitchen: kill PID)
			* When the administrators need to restart the server (virtual or Pentaho server) after a server failure, they need use a special parameter that tells the ETL to ignore the previous status (we know all jobs have been killed by server failure anyway). Eg. P_FORCE_LOAD
* __If the last load was successful__
	* We rename the current acquisition table to *name*_*processing*
	* We associate the job’s batch id with the data inserted into the core table(s), so there is only 1 batch id per core load, even if there are multiple output tables in core
	`
	* TO BE DISCUSSED WITH STEPHEN
		* What does a core load look like? Multiple inputs, multiple outputs? Will there be sequential stages? (requiring restartability)
		* effective_from (part of input data) & effective_to
		* Do we only insert records into core, or do we also update existing records' effective_to date? (this can be handled by DB2)
	`
* __If the last load was not successful__
	* We delete the last load’s batch_id from the core table(s)
	* WHAT IN CASE OF THE EFFECTIVE_FROM AND TO UPDATES?
		* The updates that happened, do we need to roll them back or can they stay there, since the new load will redo the same updates
			* Or will DB2 also roll this back?
		* We reprocess the processing tables and assign a new batch_id (the one from the current load) to the records getting loaded in the core table(s)
* __How do we know the last load’s batch_id?__
	* Retrieve from job_control
	* Contains the last batch_id per main job
	* This can work since the core load (even when multiple output tables involved) will be driven by one job (using the same batch_id for all tables involved)
* Audit columns
	* *ngdw_id*: If there are multiple sources, we need to decide on master
	* *batch_id*: coming from PDI job
* Simple example: When load 114 starts > last load (113) failed > remove 113 from core table and load processing table again into core table with new batch id (114)

## Services loads
* We need to keep track of the last batch_id that we processed from the core tables
* Next load: we take all batch_id > last batch_id to process into services tables
* We don’t yet know how errored loads need to be reprocessed here

## What does restartability look like?
* If we have separate main jobs/schedules for the core and services load, we will not need Diethard’s solution
* If we combine them OR if we really have many steps/units per job, we will need it
* This will depend on how many steps there will be per processing layer
* At this point, restartability would simply be the “delete the batch that did not process correctly and process it again”