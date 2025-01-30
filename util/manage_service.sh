#!/bin/bash
update_server_state() {
  local server_state=$1
  
  aws cloudformation update-stack \
    --stack-name "$STACK_NAME" \
    --use-previous-template \
    --capabilities CAPABILITY_IAM \
    --parameters ParameterKey=ServerState,ParameterValue="$server_state" \
                 ParameterKey=FactorioImageTag,UsePreviousValue=true \
                 ParameterKey=InstancePurchaseMode,UsePreviousValue=true \
                 ParameterKey=InstanceType,UsePreviousValue=true \
                 ParameterKey=SpotPrice,UsePreviousValue=true \
                 ParameterKey=SpotMinMemoryMiB,UsePreviousValue=true \
                 ParameterKey=SpotMinVCpuCount,UsePreviousValue=true \
                 ParameterKey=KeyPairName,UsePreviousValue=true \
                 ParameterKey=YourIp,UsePreviousValue=true \
                 ParameterKey=HostedZoneId,UsePreviousValue=true \
                 ParameterKey=RecordName,UsePreviousValue=true \
                 ParameterKey=EnableRcon,UsePreviousValue=true \
                 ParameterKey=DlcSpaceAge,UsePreviousValue=true \
                 ParameterKey=UpdateModsOnStart,UsePreviousValue=true \
                 ParameterKey=AutoUpdateServer,UsePreviousValue=true

  echo "Server state updated to $server_state for stack $STACK_NAME."
  wait_for_stack_update
}
function wait_for_stack_update() {
  echo "⏳ Waiting for stack update to complete..."
  while true; do
    STATUS=$(aws cloudformation describe-stacks \
      --stack-name $STACK_NAME \
      --query 'Stacks[0].StackStatus' \
      --output text)

    echo "📊 Current stack status: $STATUS"

    # Check if we've reached a final state
    case $STATUS in
    *COMPLETE | *FAILED)
      break
      ;;
    esac

    sleep 10
  done

  # Check if the final state is a failure
  if [[ $STATUS == *"ROLLBACK_COMPLETE"* ]]; then
    echo "❌ Stack update failed and rolled back"
    exit 1
  elif [[ $STATUS == *"COMPLETE"* ]]; then
    echo "✅ Stack update completed successfully"
  else
    echo "❌ Stack update failed with status: $STATUS"
    exit 1
  fi
}

# Function to connect to task0 using ecsconnect
connect_to_task() {
  echo "Connecting to task0 in stack $STACK_NAME..."
  # Replace the following line with the actual ecsconnect command
  ecsconnect --stack-name "$STACK_NAME" --task task0
}

# Function to display usage
usage() {
  echo "Usage: $0 <stack-name> <start|stop|shell>"
  exit 1
}

# Check if the correct number of arguments is provided
if [ "$#" -ne 2 ]; then
  usage
fi

STACK_NAME=$1
ACTION=$2

case "$ACTION" in
  start)
    update_server_state "Running"
    ;;
  stop)
    update_server_state "Stopped"
    ;;
  shell)
    connect_to_task
    ;;
  *)
    usage
    ;;
esac

