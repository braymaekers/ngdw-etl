# General Info

* The Data dictionary is the bible for ETL Development.
  * Info: table name, column name, data type, business description, column definition, business rules over the field, where is the field used (how the ETL touches it, creates it, …), …
  * The data lineage later down in the project will validate if we applied the processing in the right way.
* Referential data will be very slowly changing (eg. only 2000 participants)
* The volume will be in the transaction data
* There is sample and example data available, this can be used to produce an ETL demo
  * Product and instrument is done (mapping is done)

## ETL Framework Processing Rules

* 3 processing layers: Acquisition, Core, Service
* Referential data will flow all the way through: business wants to see updates ASAP
* Transaction data will have a schedule stage by stage (A, C, S)
* Although some business domains might have a single scheduled workflow, it will be required to design them as if all processing layers would have an independent schedule
  * Eg. For the Service load, still check which batch_id's you have left for processing (although for a single workflow this should only be a single batch_id)
  * With this in mind: having restartability on the unit might be enough (did the previous load failed > clean up first)

### Acquisition loads

* Taken care of by Customer
* Data gets appended to tables (insert only)
* As-is copy from source systems (garbage-in, garbage-out)
  * Only contains deltas (for RM this means a snapshot, for referential data this means CRUD)
  * No referential integrity checking, deltas can arrive in any order
* 3 methods:
  * File transfer (non-DB2 sources)
  * DB2 Load Utility (DB2 ingest)
  * DB2 Replication
* No history is being kept: data gets discarded once successfully loaded into Core
* Frequency:
  * Mostly once a day
  * RM might be every 15 minutes
  * Still no decision on business-user maintained data
* Audit columns
  * *ngdw_id*: records get a unique ID assigned from a DB sequence (no use for this number at this point beyond lineage)
  * *batch_id*: only when the DB2 scripts would get orchestrated with PDI

### Core loads

* Acquisition to Core
* Processing logic
  * History gets created into the Core layer
    * Deletes, Inserts, Updates into A all becomes inserts into C
    * effective_from and \_to will be driven by a business date that is part of the input
    * The ETL will take care of the history processing
    * `effective_to column from active/latest record will have a date in PDI, problem?`
  * No validation of data: still garbage-in, garbage-out
  * Mostly 1 A table to 1 C table
  * In case there are mutliple A sources for a C table
    * Normalization/deduplication of sources into master C table
    * Or in case of some attributes coming from table 1 and others from table 2: we will approach this as independent loads
      * Some columns will be designated as triggering updates for late arriving data
      * Assume a new participant gets registered + gets an address update, but we get the address update first
      * The address update (which triggers an insert) will have the business key and blank name info
      * Once the registration comes in, we update the name info and not create new history for this
  * For transaction data, Core will not have any dimension lookups and processing logic will be very limited
* We process the *_processing* tables
  * `Stephen needs to check whether renaming is allowed due to admin rights needed in DB. Stephen agrees that this approach is definitely needed for high volumn transaction data`
  * Since the acquisition tables could be continuously loaded (eg. hourly), we need to process the current snapshot of it while the core load starts. 
  * This snapshot needs to be untouched while the core load runs (and potentially needs to restart due to failure)
  * Therefore we would rename the current acquisition table to name_processing and create an empty name table (existing acquisition table). We do this as part of a transaction, making this table immutable to any other process.
  * This would create the abstraction that we need

*Eg.*

```sql
BEGIN;
ALTER TABLE table1 RENAME TO table1_processing;
CREATE TABLE table1 AS TABLE table1_processing WITH NO DATA;
COMMIT;
```

*Because of the Begin and Commit we sent the sql script as a single transaction so no other database transaction can change the table.*

* __`One core load will have a single Acquisition table as input`__
  * If this table still exists, the last load failed. 
  * If this table does not exists, the last load was successful
  * The same info (previous load = success or not) is also be present in the job_control table (checkpoint = error or finished) unless there was a system crash which avoided the ETL from updating the job_control table
    * What do we do in case of status = running: this can mean that the job is actually still running, or that the job died without updating the table? 
      * The next time the core load starts, it checks the status. If it is still running and the run time exceeds the normal limit (will be configurable) the current process would be killed (to make sure it is actually no longer running) (Pentaho server: stop job REST API; Kitchen: kill PID)
      * When the administrators need to restart the server (virtual or Pentaho server) after a server failure, they need use a special parameter that tells the ETL to ignore the previous status (we know all jobs have been killed by server failure anyway). Eg. P_FORCE_LOAD
* __If the last load was successful__
  * We rename the current acquisition table to *name*\_*processing*
  * We associate the job’s batch id with the data inserted into the core table(s), so there is only 1 batch id per core load, even if there are multiple output tables in core
* __If the last load was not successful__
  * We delete the last load’s batch_id from the core table(s)
  * What in case of updatess that already happened
    * The updates that happened, don't need to be rolled back, since the new load will redo the same updates anyway
    * We reprocess the processing tables and assign a new batch_id (the one from the current load) to the records getting loaded in the core table(s)
* __How do we know the last load’s batch_id?__
  * Retrieve from job_control
  * Contains the last batch_id per main job
  * This can work since the core load (even when multiple output tables involved) will be driven by one job (using the same batch_id for all tables involved)
* __Audit columns__
  * _ngdw_id_: If there are multiple sources, we need to decide on master
  * _batch_id_: coming from PDI job
* __Simple example__
  * _When load 114 starts > last load (113) failed > remove 113 from core table and load processing table again into core table with new batch id (114)_

### Service loads

* We need to keep track of the last batch_id that we processed from the core tables
  * Next load: we take all batch_id > last batch_id to process into services tables
* The data model in the Service layer will be dependent on reporting needs: this is not fully known at this point
* Will be hosted in a columnar DB2 instance (DB2 Blue)
* Referential data might be duplicated into multiple datamarts
* Since columnar DB, flattened out models might be used, ...
* `We don’t yet know how errored loads need to be reprocessed here, but most likely similar to Core`

### What does restartability look like

* We have orchestration restartbility (Diethard's solution)
* Data restartability is still an open point
  * restartability would simply be the “delete the batch that did not process correctly and process it again”