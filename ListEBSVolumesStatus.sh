#!/bin/bash

# This script lists all EBS volumes statuses into table format..
# you need to have access to the all regions

outputFile="AWS_EBS_Status"

for region in `aws ec2 describe-regions --output text | cut -f3`
do
     echo -e "\nListing Instances in region:'$region'..."
        aws ec2 describe-volumes --region "$region" --query 'Volumes[*].{VolumeID: VolumeId, AZ:"AvailabilityZone",tags:Tags[0].Value, ebs_size:Size, InstanceID:Attachments[0].InstanceId, VolumeType: VolumeType, VolumeState: Attachments[0].State, IOPS: Iops}' --output table >> "$outputFile"
done

# Output

#+------------+-------+----------------------+------------------------+--------------+-------------+------------+----------+
#|     AZ     | IOPS  |     InstanceID     |       VolumeID     | VolumeState  | VolumeType  | ebs_size   |     tags      |
#+------------+-------+----------------------+------------------------+--------------+-------------+------------+----------+
#|  us-west-1a|  100  |  i-09dc73c20fdd376 |  vol-08c523dcc703e |  attached    |  gp2        |  30        |  TabBank_POC  |
#|  us-west-1a|  150  |  i-037f88fde50ad06 |  vol-0f19ea9a533de |  attached    |  gp2        |  50        |  Kube         |
#|  us-west-1a|  150  |  i-037c9fe5228750d |  vol-0e611bf1dfed6 |  attached    |  gp2        |  50        |  Kube         |
#|  us-west-1a|  150  |  iec0c1835884934a6 |  vol-09 83dd6e98fa |  attached    |  gp2        |  50        |  Kube         |
#+------------+-------+----------------------+------------------------+--------------+-------------+------------+----------+
