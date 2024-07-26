start_animation "\nUploading zip to s3"

BACKUP_BUCKET="backup-${ENVIRONMENT_NAME//_/-}"

if aws s3api head-bucket --bucket "$BACKUP_BUCKET" --profile "$AWS_PROFILE" 2>/dev/null; then
    echo "\nBucket $BACKUP_BUCKET already exists."
elif aws s3api create-bucket --bucket "$BACKUP_BUCKET" --profile "$AWS_PROFILE" --region "$AWS_REGION"; then
    echo "\nBucket $BACKUP_BUCKET created."
else
    stop_animation
    echo "\nThere was an error while creating a bucket"
    rm -rf $BACKUP_DIR
    exit 1
fi

aws s3 cp $ZIP_ARCHIEVE "s3://$BACKUP_BUCKET" --profile $AWS_PROFILE
stop_animation