BITBUCKET_REPO_URL=$(read_json_variable "$RESOURCES_CONFIG" "BITBUCKET_REPO_URL")
SECRETS=$(aws secretsmanager get-secret-value --secret-id 'secretBackupFiesta' --query 'SecretString' --output text --profile "$AWS_PROFILE" 2>/dev/null)

SSH_PRIVATE=$(read_json_variable_from_json "$SECRETS" "privateKey")
SSH_PASSWORD=$(read_json_variable_from_json "$SECRETS" "privateKeyPassword")
SSH_PUBLIC=$(read_json_variable_from_json "$SECRETS" "publicKey")

if [ -z "$SSH_PRIVATE" ]; then
  echo "Failed to extract the private key from the secret"
  exit 1
fi

if [ -z "$SSH_PUBLIC" ]; then
  echo "Failed to extract the public key from the secret"
  exit 1
fi

eval "$(ssh-agent -s)"

temp_file=$(mktemp)
public_key_temp="$temp_file.pub"
cp $temp_file $public_key_temp
echo "$SSH_PUBLIC" > "$public_key_temp"

echo "$SSH_PRIVATE" > "$temp_file"
chmod 600 "$temp_file"

ssh_ask_temp=$(mktemp)
echo "echo $SSH_PASSWORD" > "$ssh_ask_temp"
export SSH_ASKPASS="$ssh_ask_temp"
chmod +x "$ssh_ask_temp"
export DISPLAY=":0"


printf "$SSH_PASSWORD" | ssh-add <(echo "$SSH_PRIVATE")
printf "$SSH_PASSWORD" | ssh-add "$temp_file"

rm "$ssh_ask_temp"

start_animation "Cloning Bitbucket repository...\n"

if GIT_SSH_COMMAND="ssh -i $temp_file" git clone "${BITBUCKET_REPO_URL}" "$BACKUP_DIR/codebase"; then
    echo "\nRepository cloned successfully."
    stop_animation
else
    echo "Failed to clone repository. Make sure to have SSH access to repository"
    rm -rf $BACKUP_DIR
    stop_animation
    ssh-add -d <(echo "$SSH_PRIVATE")
    ssh-agent -k
    rm "$temp_file"
    rm "$public_key_temp"
    rm "$ssh_ask_temp"
    exit 1
fi

ssh-add -d <(echo "$SSH_PRIVATE")
ssh-agent -k
rm "$temp_file"
rm "$public_key_temp"
