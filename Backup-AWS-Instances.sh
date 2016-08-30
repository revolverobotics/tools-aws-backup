# how long to keep the snapshots
daysToKeep=60

# standard prefix for auto-generated snapshots
prefix="[Backup]"

# Get all instances
ec2_instances="$(aws ec2 describe-instances --query "Reservations[].Instances[].{InstanceId:InstanceId,InstanceState:State.Name,Name:Tags[?Key=='Name'].Value | [0],Volumes:BlockDeviceMappings[*].Ebs[].VolumeId | [0]}" --output text)"
IFS=$'\n' read -rd '' -a ec2_instances_array <<< "${ec2_instances}"
ec2_instances=${#ec2_instances_array[@]}

# Loop through our instances
for instance in "${ec2_instances_array[@]}"
do
  # Put instance data into an array
  IFS=$'\t' read -a instance_array <<< "${instance}"

  # If the instance isn't running, skip
  if [ "${instance_array[1]}" != "running" ]; then
    echo "Skipping non-running instance"
    continue
  fi

  # Assign variables
  instanceId="${instance_array[0]}"
  instanceName="${instance_array[2]}"
  volumeId="${instance_array[3]}"

  # generate a timestamp
  date=$(date +"%Y-%m-%d %H:%M:%S");

  # concatenate all information into one description
  description="$prefix $instanceName ($instanceId) [$volumeId]"

  # create a new snapshot
  snapshot=$(aws ec2 create-snapshot --volume-id $volumeId --description "$description")

  # tag snapshot
  snapshotId=$(echo "$snapshot" | grep SnapshotId)
  snapshotId=$(echo "$snapshotId" | awk '/snap-*/ {print $2}' | sed -e 's/^"//' -e 's/",$//')
  aws ec2 create-tags --resources $snapshotId --tags "Key=Name,Value='$instanceName'"
done
