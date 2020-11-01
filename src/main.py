from pyspark.sql import SparkSession, Row
import os

spark = SparkSession.builder.appName("practice").getOrCreate()
awsAccessKeyId = os.environ('awsAccessKey')
awsSecretAccessKey = os.environ('awsSecretAccessKey')

hadoop_conf = spark._jsc.hadoopConfiguration()
hadoop_conf.set("fs.s3n.impl", "org.apache.hadoop.fs.s3native.NativeS3FileSystem")
hadoop_conf.set("fs.s3n.awsAccessKeyId", awsAccessKeyId)
hadoop_conf.set("fs.s3n.awsSecretAccessKey", awsSecretAccessKey)

spark.sparkContext.setLogLevel("ERROR")

df = spark.read.format('parquet').load('s3n://rdp-dev-env/mydf')

df.show()