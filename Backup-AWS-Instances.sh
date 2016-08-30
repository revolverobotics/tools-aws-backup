echo "Enumerating all EC2 instances for backup..."

EC2_INSTANCES="$(aws ec2 describe-instances --query "Reservations[].Instances[].[InstanceId,State.Name,Tags[?Key=='Name'].Value | [0], InstanceType]" --output text)"

IFS=$'\n' read -rd '' -a EC2_INSTANCES_ARRAY <<< "${EC2_INSTANCES}"

EC2_INSTANCES=${#EC2_INSTANCES_ARRAY[@]}

echo "Found ($EC2_INSTANCES) instances."

for instance in "${EC2_INSTANCES_ARRAY[@]}"
do
  printf '%s\t' "${instance[@]}"
  echo ""
done

