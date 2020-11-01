spark-submit \
--master local[4] \
--conf spark.ui.port=4050 \
--packages org.apache.hadoop:hadoop-aws:2.7.3 \
--packages com.qubole.spark/spark-sql-kinesis_2.12/1.2.0_spark-3.0  \
--packages io.delta/delta-core_2.12/0.7.0  \
main.py