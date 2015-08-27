# NTAPPerf
This is an attempt to ease the pull of key performance stats from a NetApp Clustered Data Ontap configuration and provide meaningful data that can be relayed back to support. The intent is to solve the problem that Secured Environments have due to their inability to or reluctance to send statistic data to support.

The chosen method for solving this problem will be to capture statistics, analyze them to find the standard deviation, and provide an xml that lists the counts taken the max, mean, and min for three areas of each objects instance. The three areas will be Utilization, Saturation, and Errors.

Initial plans: Ideally one would use the cm stats that are pulled already from each controller. These are archived for use but I have not found a good method of retrieval for these. Thus my first attempt is to use the Get-NcPerfData Method. I'm pulling the stats in 10 second intervals for all the stats pre-definded.

Future Plans: Still figuring this out. Need to get a working draft completed to ensure that it is technically possible.
