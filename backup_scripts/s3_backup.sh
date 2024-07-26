S3_BUCKETS=$(read_json_variable "$RESOURCES_CONFIG" "S3_BUCKETS")

IFS=',' read -r -A array <<< "$S3_BUCKETS"

start_animation
for element in "${array[@]}"; do
    bucket=$(echo "$element" | sed 's/^"\(.*\)"$/\1/')
    aws s3 cp "s3://$bucket/" "$BACKUP_DIR/s3_backup/$bucket" --recursive --profile $AWS_PROFILE
done
stop_animation
