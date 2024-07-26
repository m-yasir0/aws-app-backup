BITBUCKET_REPO_URL=$(read_json_variable "$RESOURCES_CONFIG" "BITBUCKET_REPO_URL")

start_animation "Cloning Bitbucket repository...\n"
if git clone "${BITBUCKET_REPO_URL}" "$BACKUP_DIR/codebase"; then
    echo "\nRepository cloned successfully."
    stop_animation
else
    echo "Failed to clone repository. Make sure to have SSH access to repository"
    rm -rf $BACKUP_DIR
    stop_animation
    exit 1
fi
