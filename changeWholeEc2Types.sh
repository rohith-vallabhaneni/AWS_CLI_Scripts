#!/bin/sh

#This script looks for instanceID.txt file with format of
# Synt: <region>,<instance id>,<target ec2 type>
# Exmp: ap-southeast-1,i-asdfdv2321efv,t2.medium
# Verify and exit the script if instance_type is already at desired state
check_desire_state(){
  
  current_instance_type=$(aws ec2 describe-instances --instance-id $instance_id --query "Reservations[*].Instances[*].InstanceType" --output text)
  
  # Verify current instance status is avaialble with the given credentials. If the O/P is empty exit the script.
  if [ "$?" != 0 ]; then
     echo "ERROR: Unable to get instance type, verify access key, secret key and region"
     exit 1
  fi

  # If current and target instance types are same, skip the instance type change functionality 
  if [ "$current_instance_type" = "$instance_type" ]; then
      echo "INFO: Current and target instance types are same..."
      echo "INFO: Skipping instance type change for $instance_id.."
      fla=1   ## Setting up flag value to check wether we need to run other functions or not
      ## To make sure that instance is up and running
      start_instance
  fi
  if [ "$fla" != "1" ];
  then
      echo "INFO: Identified change in instance type"
      stop_instance
      create_snapshots
      change_instance_type
      start_instance
  fi
}

stop_instance () {
  ##Code to stop instance, notify user, wait till instance has stopped before returning
  ##First check if the instance is actually running
  instance_state=$(aws ec2 describe-instances --instance-ids $instance_id --query Reservations[*].Instances[*].State.Name --output text)
  echo "INFO: Instance state is: $instance_state"
      if [ $instance_state = "running" ]; then
          echo "INFO: Stopping instance $instance_id"
          aws ec2 stop-instances --instance-ids $instance_id
      fi
      i=0
      state=$instance_state
      until [ $state = "stopped" ]; do
          sleep 1s
          i=$((i+1))
          state=$(aws ec2 describe-instances --instance-ids $instance_id --query Reservations[*].Instances[*].State.Name --output text)
          printf "."
          if [ "$i" -ge "180" ]; then
              printf "\n"
              echo "ERROR: Instance took too long to stop, exiting"
              exit 1
          fi
      done
      printf "\n"
      echo "INFO: Instance successfully stopped after $i seconds"
    }
    create_snapshots(){
      aws ec2 describe-volumes --filter Name=attachment.instance-id,Values=$instance_id --query Volumes[*].{ID:VolumeId} --output text | tr '\t' '\n' > `pwd`/volumesList 2>&1
      for volume_id in $(cat volumesList)
      do
         #Create a decription for the snapshot that describes the volume: servername.device-backup-date
          temp="-backup-$(date +%Y-%m-%d)"
          description=$instance_id"-"$volume_id$temp
          description=${description// /.}
          #echo "Volume ID is $volume_id" >> $logfile
          echo "INFO: Creating snapshot $description"
          #Take a snapshot of the current volume, and capture the resulting snapshot ID
          snapresult=$(aws ec2 create-snapshot --output=text --description $description --volume-id $volume_id --query SnapshotId)
          # Add some tags to the snapshot
          tagresult=$(aws ec2 create-tags --resource $snapresult --tags Key=CreatedBy,Value=ChangeInstanceType)
          echo "INFO: Tags Added successfully.."
      done
    }
    change_instance_type () {
           ##Code to change the instance type, notify user, return
      instance_state=$(aws ec2 describe-instances --instance-ids $instance_id --query Reservations[*].Instances[*].State.Name --output text)
          if [ $instance_state == "stopped" ]; then
               echo "INFO: Changing $instance_id to $instance_type"
               aws ec2 modify-instance-attribute --instance-id $instance_id --instance-type "{\"Value\": \"$instance_type\"}"
          else
               echo "ERROR: Instance state is: $instance_state"
               echo "ERROR: Cannot change instance type in this state, exiting" 1>&2
               exit 1
          fi
   }
  ## Start Ec2 instance
    start_instance () {
      ##Code to start instance, notify user, wait till instance is running before returning
      echo "INFO: Starting instance $instance_id"
      aws ec2 start-instances --instance-ids $instance_id
      i=0
      state=$(aws ec2 describe-instances --instance-ids $instance_id --query Reservations[*].Instances[*].State.Name --output text)
      until [ $state = "running" ]; do
              sleep 1s
              i=$((i+1))
              printf "."
              if [ "$i" -ge "180" ]; then
                    echo "ERROR: Instance took too long to start, exiting"
                    exit 1
              fi
              state=$(aws ec2 describe-instances --instance-ids $instance_id --query Reservations[*].Instances[*].State.Name --output text)
              done
      new_instance_type=$(aws ec2 describe-instance-attribute --instance-id $instance_id --attribute instanceType)
      printf "\n"
      echo "INSTANCEID $new_instance_type"
      echo "INFO: Instance started in $i seconds"
      echo "INFO: Completed."
      }


## Main
change_instance (){
  temp_array="$(cat instanceID.txt | sed 's/,/ /g' | cut -d' ' -f 2,3)"
  instances_array=($temp_array)
  #echo "${tag_array[*]}"
  a=0;
  length=$(( ${#instances_array[*]}-1 ))
  for var in `seq 0 2 $length`; do
     echo "${instances_array[var]} ${instances_array[var+1]}";
     instance_id="${instances_array[var]}"
     instance_type="${instances_array[var+1]}"
     check_desire_state
  done
}
change_instance
