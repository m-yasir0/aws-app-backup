RDS_IDENTIFIERS=$(read_json_variable "$RESOURCES_CONFIG" "RDS_CLUSTER_IDENTIFIERS")

IFS=',' read -r -A array <<< "$RDS_IDENTIFIERS"

SNAPSHOT_BUCKET="rds-snapshots-${ENVIRONMENT_NAME//_/-}"

for element in "${array[@]}"; do
    identifier=$(echo "$element" | sed 's/^"\(.*\)"$/\1/')
    RDS_SNAPSHOT_ID="rds-snapshot-"$identifier"-$(date +%Y%m%d%H%M%S)"
    EXPORT_TASK_IDENTIFIER="rds-export-$(date +%Y%m%d%H%M%S)"

    start_animation "Creating RDS cluster snapshot with identifier $RDS_SNAPSHOT_ID"
    aws rds create-db-cluster-snapshot --db-cluster-identifier $identifier --db-cluster-snapshot-identifier $RDS_SNAPSHOT_ID --profile $AWS_PROFILE > /dev/null 2>&1
    
    stop_animation

    start_animation "\nWaiting for RDS snapshot to be available..."
    aws rds wait db-cluster-snapshot-available --db-cluster-snapshot-identifier $RDS_SNAPSHOT_ID --profile $AWS_PROFILE

    stop_animation

    start_animation "\nExporting RDS snapshot..."
    SNAPSHOT_ARN=$(aws rds describe-db-cluster-snapshots --db-cluster-snapshot-identifier $RDS_SNAPSHOT_ID --query "DBClusterSnapshots[0].DBClusterSnapshotArn" --output text --profile $AWS_PROFILE)

    if aws s3api head-bucket --bucket "$SNAPSHOT_BUCKET" --profile "$AWS_PROFILE" 2>/dev/null; then
        echo "Bucket $SNAPSHOT_BUCKET already exists."
    elif aws s3api create-bucket --bucket "$SNAPSHOT_BUCKET" --profile "$AWS_PROFILE" --region "$AWS_REGION"; then
        echo "Bucket $SNAPSHOT_BUCKET created."
    else
        echo "\nThere was an error while creating a bucket"
        rm -rf $BACKUP_DIR
        exit 1
    fi

    aws rds start-export-task \
        --export-task-identifier $EXPORT_TASK_IDENTIFIER \
        --source-arn $SNAPSHOT_ARN \
        --s3-bucket-name $SNAPSHOT_BUCKET \
        --kms-key-id "arn:aws:kms:$AWS_REGION:$AWS_ACCOUNT_ID:key/$AWS_KMS_KEY" \
        --iam-role-arn $ROLE_ARN \
        --profile $AWS_PROFILE

    stop_animation

    echo "\nWaiting for export task to complete..."
    while true; do
        STATUS=$(aws rds describe-export-tasks --export-task-identifier ${EXPORT_TASK_IDENTIFIER} --profile $AWS_PROFILE --query "ExportTasks[0].Status" --output text)
        if [[ "${STATUS}" == "COMPLETE" ]]; then
            stop_animation
            echo "Export task completed."
            break
        elif [[ "${STATUS}" == "FAILED" ]]; then
            stop_animation
            echo "Export task failed."
            rm -rf $BACKUP_DIR
            exit 1
        else
            start_animation "\nExport task in progress... Status: ${STATUS}"
            sleep 60
        fi
    done

    start_animation "\nDownloading exported snapshot from S3..."
    aws s3 cp "s3://$SNAPSHOT_BUCKET/$EXPORT_TASK_IDENTIFIER" "$BACKUP_DIR/rds_backup/$SNAPSHOT_BUCKET" --recursive --profile $AWS_PROFILE

    stop_animation
    echo "Snapshot downloaded to $BACKUP_DIR/rds_backup/$SNAPSHOT_BUCKET"
done
