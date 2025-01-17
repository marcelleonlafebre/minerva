#chmod 755 minerva_spark.sh
#aws ec2 create-key-pair --key-name emr-keypair --query 'mlkey86' --output text > emr-keypair.pem --profile usrmll #problem: keypair createt in another region
#chmod 400 emr-keypair.pem
#MY_IP=191.99.4.35 #my ip configure inbound rule of security group
#MY_VPC=vpc-0a8deb7833a41f00d #my vpc id vpc-05e65d63
#aws ec2 create-security-group --group-name ssh-my-ip --description "For SSHing from my IP" --vpc-id $MY_VPC --profile usrmll #for the first time
SUBNET_ID=subnet-32106c1f #Public subnet subnet-025a581e6a93be02c
MY_SG=sg-0af3e4ea0a0a50680 #The security group matched with vpc
#aws ec2 authorize-security-group-ingress --group-id $MY_SG --protocol tcp --port 22 --cidr $MY_IP/32 --profile usrmll
CLUSTER_ID=$(aws emr create-cluster --name autoClusterSpark --applications Name=Spark Name=Hadoop --configurations file://conf_emr_spark.json --release-label emr-6.12.0 --use-default-roles \
--instance-groups InstanceGroupType=MASTER,Name=Master,InstanceCount=1,InstanceType=m5.xlarge InstanceGroupType=CORE,Name=Core,InstanceCount=1,InstanceType=m5.xlarge InstanceGroupType=TASK,Name=Task-1,InstanceCount=1,InstanceType=m5.xlarge InstanceGroupType=TASK,Name=Task-2,InstanceCount=1,InstanceType=m5.xlarge InstanceGroupType=TASK,Name=Task-3,InstanceCount=1,InstanceType=m5.xlarge InstanceGroupType=TASK,Name=Task-4,InstanceCount=1,InstanceType=m5.xlarge InstanceGroupType=TASK,Name=Task-5,InstanceCount=1,InstanceType=m5.xlarge InstanceGroupType=TASK,Name=Task-6,InstanceCount=1,InstanceType=m5.xlarge InstanceGroupType=TASK,Name=Task-7,InstanceCount=1,InstanceType=m5.xlarge InstanceGroupType=TASK,Name=Task-8,InstanceCount=1,InstanceType=m5.xlarge \
--log-uri s3://bigdatamell/log_spark --ec2-attributes KeyName=emr-keypair,AdditionalMasterSecurityGroups=$MY_SG,SubnetId=$SUBNET_ID --no-auto-terminate --profile usrmll)
echo $CLUSTER_ID
ACTIVE_CLUSTER=$(aws emr list-clusters --cluster-states WAITING --profile usrmll) 
while [[ "$ACTIVE_CLUSTER" == "" ]];
do
echo $ACTIVE_CLUSTER
sleep 10
ACTIVE_CLUSTER=$(aws emr list-clusters --cluster-states WAITING --profile usrmll)
done
echo "Success Cluster"
CLUSTER_ID=${CLUSTER_ID: -14}
echo $CLUSTER_ID
#MASTER_URL=$(aws emr describe-cluster --cluster-id $CLUSTER_ID --profile usrmll | jq -r ".Cluster.MasterPublicDnsName")
DESC_CLUSTER=$(aws emr describe-cluster --cluster-id $CLUSTER_ID --profile usrmll)
MASTER_URL=${DESC:144:42} #duda?
#CLUSTER_STATUS=$(aws emr describe-cluster --cluster-id $CLUSTER_ID | jq -r ".Cluster.Status")
echo $MASTER_URL
scp -i emr-keypair.pem tpcds_query67a.sql ec2-user@$MASTER_URL:/home/ec2-user/tpcds_query67a.sql
ssh ec2-user@$MASTER_URL -i emr-keypair.pem
sudo su -
mv /home/ec2-user/tpcds_query67a.sql /root/tpcds_query67a.sql
#ejecutar el query leido desde archivo
spark-sql -f tpcds_query67a.sql >tpcds_query67a.out #concatenar fecha hora y guardar en variable para proximos pasos 
#Esperar hasta la salida y guardar los resultados en bucket s3
aws s3 cp tpcds_query67a.out s3://bigdatamell/log_spark/tpcds_query67a.out
echo "Success Cluster"
#hacer que tome el archivo de query a ejecutar por parametro
exit
exit
aws emr terminate-clusters --cluster-ids $CLUSTER_ID --profile usrmll
aws emr list-clusters --cluster-states WAITING --profile usrmll