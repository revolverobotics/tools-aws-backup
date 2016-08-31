# how long to keep the snapshots
daysToKeep=60

# standard prefix for auto-generated snapshots
prefix="[Backup]"

################################################################################
# Backup all our instances #####################################################
################################################################################

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
  # snapshot=$(aws ec2 create-snapshot --volume-id $volumeId --description "$description")

  # tag snapshot
  snapshotId=$(echo "$snapshot" | grep SnapshotId)
  snapshotId=$(echo "$snapshotId" | awk '/snap-*/ {print $2}' | sed -e 's/^"//' -e 's/",$//')
  # aws ec2 create-tags --resources $snapshotId --tags "Key=Name,Value='$instanceName'"
done

################################################################################
# Remove snapshots older than $daysToKeep ######################################
################################################################################

# get all automatically generated snapshots
all_snapshots=$(aws ec2 describe-snapshots --filters "Name=description,Values='[Backup]*'" --query "Snapshots[].[SnapshotId,Description,StartTime]" --output text);
IFS=$'\n' read -rd '' -a all_snapshots_array <<< "${all_snapshots}"
all_snapshots=${#all_snapshots_array[@]}

# Loop through our snapshots
for snapshot in "${all_snapshots_array[@]}"
do
  # Put instance data into an array
  IFS=$'\t' read -a snapshot_array <<< "${snapshot}"

  snapshotId="${snapshot_array[0]}"

  # The below will only work on GNU date, not OS X date
  timestampSnapshot=$(date -d "${snapshot_array[2]}" "+%s");

  timestampCurrent=$(date +"%s")
  timestampDiff=$(( $timestampCurrent - $timestampSnapshot ))
  timestampDiffMax=$(( 60 * 60 * 24 * $daysToKeep  ))

  # if the current snapshot is older than timestampDiffMax, delete it
  if [ "$timestampDiff" -gt "$timestampDiffMax" ]
    then
      # echo "Would delete snapshot $snapshotId"
      aws ec2 delete-snapshot --snapshot-id $snapshotId
  fi
done
