#!/bin/bash
#startuptime1=$(date +%s%3N)

while getopts ":i:a:c:r:" opt; do
  case $opt in
    i) docker_image="$OPTARG"
    ;;
    a) storage_account="$OPTARG"
    ;;
    c) container_name="$OPTARG"
    ;;
    r) resource_group="$OPTARG"
    ;;
    p) port="$OPTARG"
    ;;
    t) script_file="$OPTARG"
    ;;
    \?) echo "Invalid option -$OPTARG" >&2
    ;;
  esac
done

if [ -z $docker_image ]; then
    docker_image="azuresdk/azure-cli-python:latest"
fi

if [ -z $script_file ]; then
    script_file="writeblob.sh"
fi

for var in storage_account resource_group
do
    if [ -z ${!var} ]; then
        echo "Argument $var is not set" >&2
        exit 1
    fi 

done

# Install Azure CLI 

AZ_REPO=$(lsb_release -cs)
echo "deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli/ $AZ_REPO main" | \
     sudo tee /etc/apt/sources.list.d/azure-cli.list
     
sudo apt-key adv --keyserver packages.microsoft.com --recv-keys 52E16F86FEE04B979B07E28DB02C46DF417A0893
sudo apt-get install apt-transport-https
sudo apt-get update && sudo apt-get install azure-cli

sudo apt-get -y update
sudo apt-get install cifs-utils

today=$(date +%Y-%m-%d)
currenttime=$(date +%s)
machineName=$(hostname)
scenario2="BuildTask"
sudo mkdir /mnt/azurefiles
sudo mount -t cifs //acrtestlogs.file.core.windows.net/logshare /mnt/azurefiles -o vers=3.0,username=acrtestlogs,password=ZIisPCN0UrjLfhv6Njiz0Q8w9YizeQgIm6+DIfMtjak4RJrRlzJFn4EcwDUhNvXmmDv5Axw9yGePh3vn1ak8cg==,dir_mode=0777,file_mode=0777,sec=ntlmssp

sudo mkdir /mnt/azurefiles/$today
sudo mkdir /mnt/azurefiles/$today/Scenario2
sudo mkdir /mnt/azurefiles/$today/Scenario2/$machineName$currenttime

echo "---create build task---"
buildbegin=$(date +%s%3N)
BuildStartTime=$(date +%H:%M:%S)
for i in `seq 1 100`
  do
    az acr build-task create  --name buildhelloworld$machineName$i  -r acrbuildrg2  -t helloworld$i:v1  --context https://github.com/luoli911/aci-helloworld  --git-access-token 2d218102827a740f05d07b1dcc4fcc6844afb2a4
  done
buildend=$(date +%s%3N)
BuildEndTime=$(date +%H:%M:%S)
buildtasktime=$((buildend-buildbegin))
echo registry,region,starttime,endtime,buildtasktime:acrbuildrg2,eastus,$BuildStartTime,$BuildEndTime,$buildtasktime >> /mnt/azurefiles/$today/Scenario2/$machineName$currenttime/buildtask-output.log


