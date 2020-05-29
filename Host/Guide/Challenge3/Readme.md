# 	Challenge 3 -- Redesign SSIS jobs into ELT with ADF

[< Previous Challenge](/Host/Guide/Challenge2/Readme.md)&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[Next Challenge>](/Host/Guide/Challenge4/README.md)

## Description
The objective of this lab is to modernize the ETL pipeline that was originally built in SSIS.  A detailed diagram of the current workflow is included below.  We need to rebuild this pipeline in Azure leveraging scale-out architecture to transform this data.  The data flow will include steps to extract the data from the OLTP platform, store it in the Azure Data Lake and bulk ingest it into Azure Synapase Analytics.  This will be run on a nightly basis, and will need to leverage Azure Data Factory as a job orchestration and scheduling tool.

![Current SSIS Workflow](/images/SSISFlow.png)

1. The first step of the pipeline is to retrieve the “ETL Cutoff Date”. This date can be found in the [Integration].[Load_Control] in Azure Synapse DW and should have been created as part of challenge 1.
1. The next step ensures that the [Dimension].[Date] table is current by executing the [Integration].[PopulateDateDimensionForYear] in Azure Synapse DW
1. Next the [Integration].[GetLineageKey] procedure is executed to create a record for each activity in the [Integration].[Lineage Key] table
1. This step Truncates the [Integration].[[Table]_Staging] tables to prep them for new data
1. This step retrieves the cutoff date for the last successful load of each table from the [Integration].[ETL Cutoffs] Table
1. New data is now read from the OLTP source (using [Integration].[Get[Table]Updates] procedures) and copied into the [Integration].[[Table]_Staging] tables in the target DW
1. Finally the staged data is merged into the [Dimension] and [Fact] tables in the target DW
    - <b>NOTE: As part of this step, surrogate keys are generated for new attributes in Dimension tables (tables in the [Dimension] schema), so Dimenion tables must be loaded before FACT tables to maintain data integrity

## Host Notes

1. The challenge provided to students requires that a singel pipeline be created to stage and refresh the [Dimension].[City] table.  The solution for this "Basic" challenge can be found here.

1. In order to make this pipeline more dynamic and scalable, this solution can be extended to use expressions and parameters (as called out in the additional challenges section of the Student guide).  The configuration for this "Advanced" solution is described below and can also be found here.

## Environment Setup

1. Add a new activity to your Azure Data Factory to load data from the new Azure Data Lake into the _Staging tables in the Data Warehouse in Azure Synapse via Polybase
    - The primary benefit of using ELT loading pattern in Azure is to take advantage of the capabilities of scale out cloud technologies to load data as quickly as possible and then leverage the power of Azure Synapse Analytics to transform that data, and finally merge it into its final destination.  In order to ingest the data that was loaded into the data lake in the previous challenge, you should add a new acitvity to the existing Azure Data Factory to load each table via Polybase.  A way to implement this dynamically would be to create parameterized stored procedures and call them using a Stored Procedure activity.  An example of how to load data via CTAS can be found [here](https://docs.microsoft.com/en-us/azure/synapse-analytics/sql-data-warehouse/load-data-from-azure-blob-storage-using-polybase).

    <b>NOTE:</b> This process leverages stored procedures to import the data via CTAS statements in Azure Synapse.  As mentioned, alternative approaches could be to execute Copy commands or leverage the Copy activity directly. 

1. Create another activity to merge the new data into the target Fact and Dimension tables in your DW from your _Staging tables
    - Now that your data has been loaded into the DW, you will need to merge the results into the Fact and Dimension schemas.  To accomplish this, you can use the Integration.Migrate... stored procedures that were created in Challenge 1.  In order to execute the queries via your Azure Data Factory pipeline:
        - add a new Execute Stored Procedure Activity, and configure it to execute the Integration.MigrateStagedCityData stored procedure in your Synapse DW
        <b>Note:</b> As mentioned before, you should use expressions to call the stored procedure so that the activity can be reused for each table being merged
    <b>NOTE: </b>As stated in the Description above, Dimension tables will need to be fully loaded before Fact tables, so be sure to account for that when building this activity.  In the solution included, this is achieved by creating a concept of "SequenceId" in the [Integration].[ETL Cutoffs] table in the Azure Synapse DW.  The script to add the sequence id to the table, and populate correctly can be found <here>.  

1. Add another new activity to your new pipeline to move the files to the \Out directory in your data lake once they have been loaded into your DW table
    - Now that you are able to load and merge the updated data, you will want to add a final activity to your pipeline that will copy the files from the \In directory in your data lake into the corresponding folder in your \Out directory.  This will let any downstream process and/or client know that it no longer needs to be loaded.  Keeping it in the \Out directory, however will allow the data to be persisted in your lake for future use.  You can refer back to challenge 2 for guidance on how to create a copy data activity inside Azure Data Factory
    <b>Note:</b> Depending on how dynamic you made the dataset for the Azure Data Lake store, you will likely need to create a 2nd dataset at this point for the archive directly.

1. Test your new Azure Data Factory Pipeline by validating that data added to the source system will flow through to final target tables
    - In order to test your new pipeline, you can modify an existing record or add a new one in the source OLTP database, and execute your new Data Factory pipeline to ensure the updated data is copied to your data lake, and ultimately updated in your data warehouse.  There are multiple ways to trigger your new pipeline, but the easiest is to just choose "Trigger Now" from within the Azure Data Factory UI as described [here](https://docs.microsoft.com/en-us/azure/data-factory/quickstart-create-data-factory-portal#trigger-the-pipeline-manually).


## SOLUTIONS
[Go to Solution](/Host/Solutions/Challenge3)

