FROM ubuntu:20.04

# Install pre-requisites
RUN apt-get update && apt-get -y upgrade && apt update && apt-get install sudo -y
RUN apt-get install openssh-server -y
RUN apt-get install software-properties-common -y && apt-get install -y wget -y  
RUN sudo /etc/init.d/ssh start

# Generate ssh keys for Hadoop
RUN ssh-keygen -t rsa -P '' -f ~/.ssh/id_rsa
RUN cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys
RUN chmod 0600 ~/.ssh/authorized_keys

# Install Java 1.8
RUN sudo add-apt-repository ppa:openjdk-r/ppa
RUN sudo apt-get update
RUN sudo apt-get install openjdk-8-jdk -y
RUN sudo update-alternatives --config java && sudo update-alternatives --config javac

# Install pip
RUN sudo apt-get install -y python3-pip

# Download Scala, Spark, Hadoop & Hive
RUN mkdir ~/downloads
RUN wget -O ~/downloads/scala-2.12.12.deb https://downloads.lightbend.com/scala/2.12.12/scala-2.12.12.deb
RUN wget -O ~/downloads/spark-3.0.1-bin-hadoop2.7.tgz https://apache.mirrors.nublue.co.uk/spark/spark-3.0.1/spark-3.0.1-bin-hadoop2.7.tgz
RUN wget -O ~/downloads/hadoop-2.7.7.tar.gz https://archive.apache.org/dist/hadoop/core/hadoop-2.7.7/hadoop-2.7.7.tar.gz
RUN wget -O ~/downloads/apache-hive-3.1.2-bin.tar.gz https://www.mirrorservice.org/sites/ftp.apache.org/hive/hive-3.1.2/apache-hive-3.1.2-bin.tar.gz

# Install Scala
RUN sudo dpkg -i ~/downloads/scala-2.12.12.deb

# Unarchive all packages under directory /usr/local/
RUN sudo tar -xzf ~/downloads/spark-3.0.1-bin-hadoop2.7.tgz -C /usr/local/
RUN sudo tar -xzf ~/downloads/hadoop-2.7.7.tar.gz -C /usr/local/
RUN sudo tar -xzf ~/downloads/apache-hive-3.1.2-bin.tar.gz -C /usr/local/

# Allow User to edit folder(s)
RUN sudo chown -R root /usr/local/spark-3.0.1-bin-hadoop2.7/
RUN sudo chown -R root /usr/local/hadoop-2.7.7/
RUN sudo chown -R root /usr/local/apache-hive-3.1.2-bin/

# Create Symlinks
RUN cd /usr/local/
RUN sudo ln -s /usr/local/spark-3.0.1-bin-hadoop2.7/ /usr/local/spark
RUN sudo chown -h root:root /usr/local/spark
RUN sudo ln -s /usr/local/hadoop-2.7.7/ /usr/local/hadoop
RUN sudo chown -h root:root /usr/local/hadoop
RUN sudo ln -s /usr/local/apache-hive-3.1.2-bin/ /usr/local/hive
RUN sudo chown -h root:root /usr/local/hive

# Create folders for Hadoop logs and HDFS Storage
RUN sudo mkdir /logs
RUN sudo chown -R root /logs
RUN mkdir /logs/hadoop
RUN sudo mkdir /hadoop
RUN sudo chown -R root /hadoop
RUN mkdir -p /hadoop/hdfs/namenode
RUN mkdir -p /hadoop/hdfs/datanode
RUN mkdir -p /tmp/hadoop

# Update and Create ENV variables
ENV JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64
ENV PATH=$PATH:$JAVA_HOME/bin
ENV HADOOP_HOME=/usr/local/hadoop
ENV HIVE_HOME=/usr/local/hive
ENV PATH=$PATH:$HADOOP_HOME/bin
ENV PATH=$PATH:$HADOOP_HOME/sbin
ENV PATH=$PATH:$HIVE_HOME/bin
ENV HADOOP_MAPRED_HOME=$HADOOP_HOME
ENV HADOOP_COMMON_HOME=$HADOOP_HOME
ENV HADOOP_HDFS_HOME=$HADOOP_HOME
ENV HADOOP_CONF_DIR=$HADOOP_HOME/etc/hadoop
ENV YARN_HOME=$HADOOP_HOME
ENV HADOOP_COMMON_LIB_NATIVE_DIR=$HADOOP_HOME/lib/native
ENV HADOOP_OPTS="-Djava.library.path=$HADOOP_HOME/lib/native"
ENV HADOOP_LOG_DIR=/logs/hadoop
ENV SPARK_HOME=/usr/local/spark
ENV PATH=$PATH:$SPARK_HOME/bin
ENV SPARK_HOME=/usr/local/spark
ENV PYSPARK_PYTHON=/usr/bin/python3
ENV PYSPARK_DRIVER_PYTHON=/usr/bin/python3

# Configure Hadoop
RUN cd /usr/local/hadoop/etc/hadoop
COPY ./config/hadoop/hadoop-env.sh /usr/local/hadoop/etc/hadoop/
COPY ./config/hadoop/core-site.xml /usr/local/hadoop/etc/hadoop/
COPY ./config/hadoop/mapred-site.xml /usr/local/hadoop/etc/hadoop/
COPY ./config/hadoop/hdfs-site.xml /usr/local/hadoop/etc/hadoop/
COPY ./config/hadoop/yarn-site.xml /usr/local/hadoop/etc/hadoop/

# Format & Start Hadoop
RUN mkdir -p /home/node/app && chown -R root:root /home/node/app
WORKDIR /home/node/app
COPY src/ ./
RUN pip3 install -r ./requirements.txt

EXPOSE 4050
CMD [ "bash", "spark-structured-stream.sh" ]