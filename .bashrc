source 'helper/json_helper.sh'
source 'libs/animation.sh'

CONFIG="config"
BACKUP_SCRIPTS="backup_scripts"
AWS_CONFIG="$CONFIG/aws.json"
ENV_CONFIG="$CONFIG/env.json"
RESOURCES_CONFIG="$CONFIG/resources.json"
DATE=$(date +"%Y%m%d")

if [ ! -f "$AWS_CONFIG" ]; then
  echo "AWS config file not found: $AWS_CONFIG"
  rm -rf $BACKUP_DIR
  exit 1
fi

if [ ! -f "$ENV_CONFIG" ]; then
  echo "Env config file not found: $AWS_CONFIG"
  rm -rf $BACKUP_DIR
  exit 1
fi

if [ ! -f "$RESOURCES_CONFIG" ]; then
  echo "Resources config file not found: $AWS_CONFIG"
  rm -rf $BACKUP_DIR
  exit 1
fi

AWS_PROFILE=$(read_json_variable "$AWS_CONFIG" "AWS_PROFILE")
AWS_KMS_KEY=$(read_json_variable "$AWS_CONFIG" "AWS_KMS_KEY")
AWS_REGION=$(read_json_variable "$AWS_CONFIG" "AWS_REGION")
AWS_ACCOUNT_ID=$(read_json_variable "$AWS_CONFIG" "AWS_ACCOUNT_ID")

BACKUP_DIR=$(read_json_variable "$ENV_CONFIG" "BACKUP_DIR")
ENVIRONMENT_NAME=$(read_json_variable "$ENV_CONFIG" "ENVIRONMENT_NAME")

echo "\n
██████╗  █████╗  ██████╗██╗  ██╗██╗   ██╗██████╗ 
██╔══██╗██╔══██╗██╔════╝██║ ██╔╝██║   ██║██╔══██╗
██████╔╝███████║██║     █████╔╝ ██║   ██║██████╔╝
██╔══██╗██╔══██║██║     ██╔═██╗ ██║   ██║██╔═══╝ 
██████╔╝██║  ██║╚██████╗██║  ██╗╚██████╔╝██║     
╚═════╝ ╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝ ╚═════╝ ╚═╝     
                                                 
███████╗██╗███████╗███████╗████████╗ █████╗      
██╔════╝██║██╔════╝██╔════╝╚══██╔══╝██╔══██╗     
█████╗  ██║█████╗  ███████╗   ██║   ███████║     
██╔══╝  ██║██╔══╝  ╚════██║   ██║   ██╔══██║     
██║     ██║███████╗███████║   ██║   ██║  ██║     
╚═╝     ╚═╝╚══════╝╚══════╝   ╚═╝   ╚═╝  ╚═╝                                                                     
"
sleep 2

echo "\n\nUsing AWS profile $AWS_PROFILE"

if aws sts get-caller-identity --profile "$AWS_PROFILE"> /dev/null 2>&1; then
    echo "\nExisting AWS session is active."
else
    start_animation "\nNo existing aws session. Logging in with SSO..."
    if aws sso login --profile "${AWS_PROFILE}"; then
        echo "\nLogged in successfully with AWS SSO."
        stop_animation
    else
        echo "\n\nAWS authentication failed."
        rm -rf $BACKUP_DIR
        stop_animation
        exit 1
    fi
fi

ROLE_ARN=$(read_json_variable "$AWS_CONFIG" "AWS_EXPORT_ROLE_ARN")
source "$BACKUP_SCRIPTS/bitbucket_backup.sh"
source "$BACKUP_SCRIPTS/rds_backup.sh"
source "$BACKUP_SCRIPTS/s3_backup.sh"

start_animation "\nCreating zip archive..."
ZIP_ARCHIEVE="$DATE"_"$ENVIRONMENT_NAME"_"System-Backup.zip"
zip -r $ZIP_ARCHIEVE $BACKUP_DIR/*
stop_animation

source "$BACKUP_SCRIPTS/upload_zip.sh"
