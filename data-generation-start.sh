ES_HOME=/home/denklewer/Tools/elasticsearch-7.3.2
LOGSTASH_HOME=/home/denklewer/Tools/logstash-7.3.2
KAFKA_HOME=/home/denklewer/Tools/kafka_2.12-2.3.0
ATTACK_SIMULATOR_HOME=/home/denklewer/Projects/ss7-attack-simulator/restcomm-jss7-1
ATTACK_SIMULATOR_BIN=$ATTACK_SIMULATOR_HOME/ss7/restcomm-ss7-simulator/bin

WD=$(pwd)

#Color printing
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# Helper functions
STEP_VAR=0
step_function () {
  ((STEP_VAR++))
  now=$(date +"%T")
  printf  "[$now] ${GREEN}$STEP_VAR.$1${NC} \n"
}

print_function () {
  now=$(date +"%T")
  echo "["$now"]" $1
}

#Script Start
step_function "Start ZooKeeper"
gnome-terminal --tab --working-directory=$KAFKA_HOME \
               -t ZooKeeper \
			   -- bash -c "./bin/zookeeper-server-start.sh config/zookeeper.properties; exec bash"
sleep 5
step_function "Start Kafka"
gnome-terminal --tab \
               --working-directory=$KAFKA_HOME \
			   -t Kafka_Server \
			   -- bash -c "./bin/kafka-server-start.sh config/server.properties; exec bash"
			   
			   
step_function "Start Elasticsearch"
gnome-terminal --tab \
               --working-directory=$ES_HOME \
			   -t Elasticsearch \
			   -- bash -c "elasticsearch; exec bash"

sleep 15

step_function "Create Kafka topics"
cd $KAFKA_HOME
SOME_VAR=`(sh bin/kafka-topics.sh --list --bootstrap-server localhost:9092)`
echo $SOME_VAR
bin/kafka-topics.sh --create --bootstrap-server localhost:9092 --replication-factor 1 --partitions 1 --topic ss7-raw-input
bin/kafka-topics.sh --create --bootstrap-server localhost:9092 --replication-factor 1 --partitions 1 --topic ss7-preprocessed


SOME_VAR=`(sh bin/kafka-topics.sh --list --bootstrap-server localhost:9092)`
echo $SOME_VAR

if [[ ${#SOME_VAR} -gt 0 ]]
then
  print_function "Topics has been created. Kafka OK"
else
  print_function "Topics has not been created. Kafka Failure"
fi

step_function "Run logstash. WARNING:enter user credentials in terminal"
gnome-terminal --tab \
               --working-directory=$LOGSTASH_HOME \
			   -t Logstash \
			   -- bash -c "sudo ./bin/logstash -f $WD/tshark-kafka-es.conf; exec bash"

step_function "Run attack simulator"
gnome-terminal --tab \
               --working-directory=$ATTACK_SIMULATOR_BIN \
			   -t Attack_Simulator \
			   -- bash -c "run.sh attack_simulator -a complex -s 2; exec bash"




