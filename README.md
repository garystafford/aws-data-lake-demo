# Building a Data Lake on AWS

## References

- [Amazon Redshift TICKIT Sample Database](https://docs.aws.amazon.com/redshift/latest/dg/c_sampledb.html)

## AWS Glue Data Catalog Tables

```text
--------------------------------
|           GetTables          |
+------------------------------+
|  bronze_ecomm_date           |
|  bronze_ecomm_listing        |
|  bronze_ecomm_sale           |
|  bronze_tickit_crm_user      |
|  bronze_tickit_ems_category  |
|  bronze_tickit_ems_event     |
|  bronze_tickit_ems_venue     |
|  silver_ecomm_date           |
|  silver_ecomm_listing        |
|  silver_ecomm_sale           |
|  silver_tickit_crm_user      |
|  silver_tickit_ems_category  |
|  silver_tickit_ems_event     |
|  silver_tickit_ems_venue     |
|  source_ecomm_date           |
|  source_ecomm_listing        |
|  source_ecomm_sale           |
|  source_tickit_crm_user      |
|  source_tickit_ems_category  |
|  source_tickit_ems_event     |
|  source_tickit_ems_venue     |
+------------------------------+
```
## Data Lake Naming Conventions

```text
+-------------+---------------------------------------------------------------------+
| Prefix      | Description                                                         |
+-------------+---------------------------------------------------------------------+
| _source     | Data Source metadata only                                           |
| _bronze     | Bronze/Raw data from data sources (org. call _converted in video)   |
| _silver     | Silver/Augmented data - raw data with initial ELT/cleansing applied |
| _gold       | Gold/Curated data - aggregated/joined refined data                  |
+-------------+---------------------------------------------------------------------+
```

## Demo Commands

```shell
aws cloudformation deploy \
    --stack-name data-lake-demo-glue \
    --template-file ./cloudformation/data-lake-demo-glue.yml \
    --capabilities CAPABILITY_NAMED_IAM

# optional to delete stack when done with demo
aws cloudformation delete-stack --stack-name data-lake-demo-glue

DATA_LAKE_BUCKET="open-data-lake-demo-us-east-1"

# clear out existing data lake data
aws s3 rm "s3://${DATA_LAKE_BUCKET}/tickit/" --recursive


# clear out existing data lake data catalog
aws glue delete-database --name data_lake_demo

aws glue create-database \
  --database-input '{"Name": "data_lake_demo", "Description": "Track sales activity for the fictional TICKIT web site"}'

aws glue get-tables \
  --database-name tickit_demo \
  --query 'TableList[].Name' \
  --output table

aws glue start-crawler --name tickit_postgresql;
aws glue start-crawler --name tickit_mysql;
aws glue start-crawler --name tickit_mssql

aws glue get-jobs \
  --query 'Jobs[].Name' \
  | grep tickit_ | sort

aws glue start-job-run --job-name tickit_bronze_crm_user;
aws glue start-job-run --job-name tickit_bronze_ecomm_date;
aws glue start-job-run --job-name tickit_bronze_ecomm_listing;
aws glue start-job-run --job-name tickit_bronze_ecomm_sale;
aws glue start-job-run --job-name tickit_bronze_ems_category;
aws glue start-job-run --job-name tickit_bronze_ems_event;
aws glue start-job-run --job-name tickit_bronze_ems_venue

aws glue start-job-run --job-name tickit_silver_crm_user;
aws glue start-job-run --job-name tickit_silver_ecomm_date;
aws glue start-job-run --job-name tickit_silver_ecomm_listing;
aws glue start-job-run --job-name tickit_silver_ecomm_sale;
aws glue start-job-run --job-name tickit_silver_ems_category;
aws glue start-job-run --job-name tickit_silver_ems_event;
aws glue start-job-run --job-name tickit_silver_ems_venue

aws glue get-tables \
  --database-name data_lake_demo \
  --query 'TableList[].Name' \
  --output table

aws s3 ls ${DATA_LAKE_BUCKET}/tickit/

aws s3api list-objects-v2 \
  --bucket ${DATA_LAKE_BUCKET} \
  --prefix "tickit/bronze" \
  --query "Contents[].Key" --output table \
  --max-items 25
```
