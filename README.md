# Disclaimer

This Script is developed by Mr. Suman Adhikari for own day to day tasks and all the demo below listed are ran on my own RnD env. Any harm by running the script to their respectiv env by anyone is not the under my responsibility.. One can fork, download and customize in their onw way...


# Oracle Database Health Check Script Unix Platforms.

The script is designed to collect logs and metrics from O/S, Database Instance and Clusterware if exits. The script is interactive so it prompts input from the user. It also generates AWR/ADDM reports for 24 hrs, from stript fired time minus 24. 

## Some Snapshots: 
When ever the script is run, it prompts the following screen. The script collects all the database instance running in the box and prompts the user against which instance the DBHC is to be performed.

![Alt text](img/1.png?raw=true "Run the DBHC script and select Instance.")

![Alt text](img/2.png?raw=true "Run the DBHC script and select Instance.")


The Scripts prompts error if wrong instance name is provided.

![Alt text](img/3.png?raw=true "Error When wrong instance name is provided.")


When ever the Log and metrics collection for instance is successful the script then generates AWR/ADDM report for 24hrs(From now to back 24 hr).

![Alt text](img/4.png?raw=true "Snapshot showing AWR/ADDM reports being generated.")


After finishing collecting statistics and metrics for instance specific the script now collects the logs and metrics for OS.It collects logs for Unix boxes running (IBM AIX, Oracle Solaris, Linux, HP-UX). If the script is ran other than this list it prompts error. The collection of O/S logs can be skipped too.

![Alt text](img/10.png?raw=true "Shapshot showing O/S log collecting and halted when wrong O/S choice is made.")


The script also collects the logs and metrics for ORACLe clusterware. The log collection for Clusterwarae can be skipped.

![Alt text](img/8.png?raw=true "Snapshot prompting to collect RAC logs.")

The Logs and files are collected with successful execution of Script in below hierarchy.

![Alt text](img/9.png?raw=true "Snapshot prompting to collect RAC logs.")
