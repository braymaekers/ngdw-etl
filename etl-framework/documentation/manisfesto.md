# Manifesto

The Framework main objective is to structure etl development by enforcing folder structure, naming conventions and separation between configuration and code.

It also provides:

* management over the usage of kitchen to scale-up using other temporary JVM within the current environment (both from BA repository execution and file based execution)
* capabilities for orchestration restart control through a set of concepts that creates a controllable execution path

## Folder Structure

The folder structure prescribed by the Framework enforces separation between code and configuration and tries to create an easy to read and easy to access environment. Separation between code and configuration allows for smooth code flow between different environments, which will make the process of deploying much more easy to manage.

The basic idea is to have different folder structures for configuration and for code, that could be different git repositories, and to separate the configurations for different environments in different folders. Generically, projects using the Framework should have a structure like this inside a main **Project** folder:

* **Framework** - folder containing the Framework code
* **Configuration** - folder containing all the configurations
* **ETL** - the folder contain all the etl developed within the project scope

### Framework Folder

It holds the core code to make it all happen. It is structured under the following folders:

* _control_ - here are kept all the artifacts that allows the orchestration restart control
* _developer-tools_ - this folder has the tools that are useful during development and testing
* _execution_ - in here the Framework has the jobs that perform the execution orchestration
* _utilities_ - this folder contains services that are used by the Frameowrk to perform some tasks, like decrypt passwords to execute kitchen over code on BA Server, or load configurations during execution

### ETL Folder

The ETL code for the project should be kept under a specific project folder, for the _single layer approach_, or it can be kept under different sub-project folders that help to make difference between the data layers/stages (this would be called the _multiple layer approach_).

For the _single layer approach_ the folder structure should be something like:

* _project_
  * content-pdi
  * scripts
  * sql
  * log
  * documentation

For the _multiple layer approach_ the folder structure should be something like this:

* _common_ - this folder will hold code that is common between different sub-projects and that orchestrate code from different project layers
  * content-pdi
  * scripts
  * sql
  * log
  * documentation
* _project-layer-1_
  * content-pdi
  * scripts
  * sql
  * log
  * documentation
* _project-layer-2_
  * content-pdi
  * scripts
  * sql
  * log
  * documentation

#### _content-pdi_ Folder

These folders will have all the ETL code. They should obey to two basic rules: Work Units should be kept under the specific _project-layer_ folder where they belong, Main Jobs should be kept under the _content-pdi_ folder.

### Configuration Folder

This folder contains the elements that glue the Framework, ETL code and environment configurations. The orientation is to separate the different environments by different folders and apply GIT governance accordingly.

So, for a project with 3 environments, develop, test and production we would create the following folder structure:

* **config-local**
* **config-test**
* **config-production**

## Configuration Parameters

The Framework uses a set of parameters to load the correct environment for a specific execution. This set of parameters are divided in the following files:

* ../.kettle/kettle.properties - for generic and global parameters
* ../properties/framework.properties - for Framework related parameters
* ../properties/common.properties - for database connections parameters
* ../properties/_project\_layer_.properties - for _project\_layer_ Framework properties and specific layer properties

### Parameters on ../.kettle/kettle.properties

kettle.properties connects the dots between the different folders that the Framework relies on. This is accomplished using the following parameters:

* _ETL\_FRAMEWORK\_DIR_ - the path in the file system to the Framework folder
* _ETL\_FRAMEWORK\_HOME_ - the path to the Framework where the code content is, either on the file system (../framework/content-pdi), or on the BA Server (/public/framework)
* _PROJECT\_DIR_ - the path on the file system to the main **Project** folder
* _CONTENT\_DIR_ - the path, either on file system, or on BA Server, to the ETL code
* _COMMON\_DIR_ - the path, either on file system, or on BA Server, to the common folder
* _CONFIG\_DIR_ - the path on file system to the configuration main folder that controls the current environment (e.g. _../Project/Configuration/config-local_)
* _FILE\_MGMT\_DIR_ - the path on the file system to the main **Project** folder; this is will be used to point to the correct file management location by the _project-layer_ properties files
* LOG_DIR - the path on the file system to the main **Project** folder; this is will be used to point to the correct log location by the _project-layer_ properties files

When running the Framework on a BA Server these parameters will help the communication:

* DI_SERVER.PROTOCOL - protocol used to connect to BA Server
* DI_SERVER.HOST - the BA Server hostname
* DI_SERVER.POR - the BA Server port
* DI_SERVER.WEBAPP - the webapp pentaho webapp on tomcap
* DI_SERVER.USERNAME - the username to connect to BA Server APIs
* DI_SERVER.PASSWORD - the password to connect to the BA Server APIs
* DI_SERVER.REPOSITORY - the repository name (should be the same as in the repositories.xml)

## Orchestration Restart Control

The orchestration restart provided by the Framework aims to control units of work that are orchestrated in jobs. We call it orchestration restart control to create a difference between orchestration and data restart control. 

Data restart control should be implemented during the ETL development and is related with what data operations should be performed on the ETL when something goes wrong with one execution and we restart again the same operation.

Orchestration restart control determines what Work Units should be executed during a Main Job Execution, based on the previous Main Job execution and the previous Work Unit Execution. This means that, Framework orchestration restart control is performed on a set of concepts and rules that prevent:

* a Main Job to restart while the same Main Job is executing
* a Main Job Work Unit to execute if the previous execution was successful but the Main Job failed

**Note**: the Framework can be used without the orchestration restart control, either using regular PDI jobs, either using Framework Main Jobs.

The Framework can be used without the orchestration restart control, either on regular PDI jobs, either on Framework Main Jobs.

### WORK UNIT

Work Units are the smallest elements controlled by the Framework. They can be built from .ktrs or .kjbs. Each one can be used as a checkpoint for Project Jobs. A Work Unit can only be execute if the Main Job can be executed and if the current status is different from _success_ or _running_.

Work Unit possible status:

* _running_ - not allowed to start
* _success_ - execution skipped
* _error_ - allow to start
* _finished_ - when all work units from one job finish with success

### MAIN JOBS

This Framework elements represent the orchestration of Work Units. They can only be executed if their current status is _finished_ or _error_.

Main Job possible status:

* _running_ - when it starts and if the system crashes for some reason
* _error_ - if an error was detected on one of the Work Units that the Main Job orchestrates
* _finished_ - when all Work Units finished with success

### MAIN RULES

1. The Framework allows restart control over their Main Jobs and the Work Units orchestrated by them.
1. All Framework executable Main Jobs should be inside the folder _project-layer_/content-pdi (physical path).
1. All Framework transversal Main Jobs (orchestration of work units from different projects) should be placed on ../common/content-pdi (physical path).
1. All Framework Main Jobs execute Work Units (ktrs or kjbs) that are under the folder _Project_/content-pdi/_project-layer_/ (physical path).
1. The Framework uses a table to control the execution of Main Jobs and Work Units called _job\_control_ where the name of the Main job, _Project_, Work Unit and current status is recorded

## Main Job Execution

Every Main Job, regardless the usage Orchestration Restart Control, must be execute through the Framework Job ../framework/[content-pdi]/execution/fw-jb_launcher.kjb (content-pdi is only needed if the execution is started using files instead of PDI Server repository).

This Framework Job will load the necessary environment to execute the Main Job requested and, if Orchestration Restart Control is being used, will also perform the restart validations. Additionally, this Job will also control the mode execution: local execution (same JVM available), or Foreign execution (new JVM created by kitchen, meaning scale-up).

The Job receives the following parameters:

* **P\_JOB\_NAME** - the Main Job that should be executed, for example jb_main_common_load_product_family_and_instrument
* **P\_PROJECT\_NAME** - the _Project_ name that holds the Main Job, for example common
* **P\_SCALE\_UP** - the indication of how we are going to execute, true for kitchen execution, false the current JVM

## Scale-up with Kitchen

The Framework allows the possibility to use more available memory than the 24 GBs reocmmend by Pentaho BPs. This is made by triggering kitchen execution from the fw-jb_launcher.kjb, using the parameter P_SCALE_UP with the value _true_.

This feature can be launched both on environments that are executing etl code from the file system or from the BA Server - to control this execution please fill the Framework parameter SCALE_UP_MODE with the values _FILE_ for kitchen execution based on the file system, and _BA\_SERVER_ for kitchen executions of code kept on BA Server.

## Necessary Configurations

../.kettle/repositories.xml is needed to tell kitchen what are is the available repository.

Remember to describe the necessity of having the pentaho-server/pentaho-solutions/kettle/slave-server-config.xml file defined to allow kitchen to know where the server is, when using the API service runJob.
