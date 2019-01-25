#!/bin/bash

# This script will list the all instance tags in all regions..  (Generic script for all regions and all instances) 
# If you have access to all regions in AWS, this script will get into each region and take the instance id and loop it... 

function tags(){
 for instance_id in `aws ec2 describe-instances --region "$region" --query 'Reservations[*].Instances[*].InstanceId' --output text`
do
    # echo -e "\nListing Tags for Instance:'$instance_id' in $1..."
    # aws ec2 describe-instances --region $region

    echo "####### Listing Tags for $instance_id #######"
    aws ec2 describe-tags --region $region --filters Name="resource-id",Values=$instance_id | jq -r '.Tags[] | "\(.ResourceId)\t\(.Key)\t\(.Value)"'
done
echo "=================== Completed listing tags in "$region"  =========================="
}

for region in `aws ec2 describe-regions --output text | cut -f3`
do
     echo -e "\nGetting Tags details  in region:'$region'..."
     ## Calling tags function by passing region value
     tags "$region"
done



# when you run this script redirect output into one text file.. and output is like below..

#       Getting Tags details  in region:'eu-west-3'...
#       ###### Listing Tags for i-0e76b23930aec7326 #######
#       i-0e76b23930aec7326     Name    AmruthaDocker_training
#       ###### Listing Tags for i-0fc8ee66c26098fcd #######
#       i-0fc8ee66c26098fcd     Name    chandu_jenkins_agent_training
#       i-0fc8ee66c26098fcd     Owner   chandrashekar.bekkem
