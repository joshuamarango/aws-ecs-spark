from pyspark.sql import SparkSession
from pyspark.sql.types import StructType, ArrayType, StringType, IntegerType
from pyspark.sql.functions import from_json, col, to_date, split, year
import os

spark = SparkSession.builder.appName("practice").getOrCreate()
spark.sparkContext.setLogLevel("ERROR")

awsAccessKeyId = os.environ('awsAccessKeyId')
awsSecretAccessKey = os.environ('awsSecretAccessKey')

hadoop_conf = spark._jsc.hadoopConfiguration()
hadoop_conf.set("fs.s3n.impl", "org.apache.hadoop.fs.s3native.NativeS3FileSystem")
hadoop_conf.set("fs.s3n.awsAccessKeyId", awsAccessKeyId)
hadoop_conf.set("fs.s3n.awsSecretAccessKey", awsSecretAccessKey)

kinesis = spark.readStream.format("kinesis") \
    .option("streamName", "users_stream") \
    .option("endpointUrl", "https://kinesis.eu-west-1.amazonaws.com") \
    .option("awsAccessKeyId", awsAccessKeyId) \
    .option("awsSecretKey", awsSecretAccessKey) \
    .option("startingPosition", "TRIM_HORIZON") \
    .option("failondataloss", "true") \
    .option("kinesis.executor.maxFetchTimeInMs", 1000) \
    .option("kinesis.executor.maxFetchRecordsPerShard", 100000) \
    .option("kinesis.executor.maxRecordPerRead	", 10000) \
    .option("kinesis.client.describeShardInterval", "3600s") \
    .option("kinesis.client.numRetries", 3) \
    .option("kinesis.client.retryIntervalMs", 10000) \
    .option("kinesis.client.avoidEmptyBatches", "false") \
    .load()

users_schema = StructType() \
    .add('userId', StringType()) \
    .add('dob', IntegerType()) \
    .add('gender', StringType()) \
    .add('fullName', StringType())
    
USERS_STREAM = kinesis \
    .select(from_json('data', users_schema).alias('json')) \
    .withColumn('userId', col('json.userId')) \
    .withColumn('dob_date', to_date(col('json.dob'), 'yyyy-MM-dd')) \
    .withColumn('dob_year', year(col('dob_date')).cast('int')) \
    .withColumn('gender', col('json.gender')) \
    .withColumn('firstName', split(col('fullName'), ' ').getItem(0)) \
    .withColumn('lastName', split(col('fullName'), ' ').getItem(1)) \
    .drop('json')
    
USERS_STREAM \
    .writeStream \
    .format("console") \
    .option("truncate", "false") \
    .outputMode("append") \
    .start()
  
spark.streams.awaitAnyTermination()