# Backup Fiesta

Backup Fiesta is a comprehensive backup solution designed to streamline and automate the process of backing up your important data from various locations such as AWS S3, Bitbucket, and RDS.

## Table of Contents
- [Installation](#installation)
- [Dependencies](#dependencies)
- [AWS Profile Setup](#aws-profile-setup)
- [Configuration](#configuration)
- [Usage](#usage)
- [Scripts](#scripts)
- [Additional AWS Setup Requirements](#additional-aws-setup-requirements)

## Installation

To set up Backup Fiesta, follow these steps:

1. **Clone the repository:**
    ```bash
    git clone <repository-url>
    cd backup_fiesta
    ```

2. **Install necessary dependencies:**
    Ensure you have the required tools and dependencies installed. Backup Fiesta primarily uses shell scripts, so a Unix-like environment is recommended.


## Dependencies

Backup Fiesta relies on several tools and libraries to function correctly. Make sure you have the following dependencies installed on your system.

### For Ubuntu/Debian:

1. **Bash**: Ensure you have a modern version of Bash installed (version 4.0 or above).
2. **AWS CLI**: Required for interacting with AWS services.
    ```bash
    sudo apt-get install awscli
    ```
3. **git**: For Bitbucket backups.
    ```bash
    sudo apt-get install git
    ```
4. **zip/unzip**: For handling zip files.
    ```bash
    sudo apt-get install zip
    ```

5. **SSH Agent**: Required for managing SSH keys for secure connections.
    ```bash
    sudo apt-get install openssh-client
    ```

### For macOS:

1. **Bash**: Ensure you have a modern version of Bash installed (version 4.0 or above). The default version of Bash on macOS is outdated, so you might need to update it.
    ```bash
    brew install bash
    ```
2. **AWS CLI**: Required for interacting with AWS services.
    ```bash
    brew install awscli
    ```
3. **git**: For Bitbucket backups.
    ```bash
    brew install git
    ```
4. **zip/unzip**: For handling zip files.
    ```bash
    brew install zip
    ```
5. **SSH Agent**: Required for managing SSH keys for secure connections.
    ```bash
    brew install openssh
    ```

## AWS Profile Setup

Backup Fiesta requires an AWS profile to be set up on your system. Follow these steps to set up an AWS profile if you haven't already:

1. **Configure AWS CLI with your credentials:**
    ```bash
    aws configure
    ```

2. **Enter the following details when prompted:**
    - AWS Access Key ID
    - AWS Secret Access Key
    - Default region name (e.g., us-east-1)
    - Default output format (json)

For more details, refer to the [AWS CLI Configuration Guide](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-quickstart.html).



## Configuration

Backup Fiesta uses JSON configuration files located in the `config` directory. You can find example configuration files in the `config.example` directory.

### Config Files:
- **env.json**: Environment-specific settings.
- **resources.json**: Resource configurations.
- **aws.json**: AWS-specific configurations.

To use the configuration files, copy the example files to the `config` directory and modify them according to your setup:
```bash
cp config.example/env.json config/env.json
cp config.example/resources.json config/resources.json
cp config.example/aws.json config/aws.json
```

Edit the copied files to include your specific settings.

## Usage

Backup Fiesta provides various scripts to perform different types of backups. Below are the main scripts and their usage:

### Running Backup Script

- **Start backup**

using:
```bash
source .bashrc     
```

Ensure the scripts have execute permissions. If not, you can set them using:
```bash
chmod +x backup_scripts/*.sh
```

## Scripts

### upload_zip.sh
This script handles the upload of zipped backup files to a specified destination.

### bitbucket_backup.sh
This script performs a backup of Bitbucket repositories.

### s3_backup.sh
This script backups specified buckets from S3.

### rds_backup.sh
This script performs a backup of RDS databases.

### libs/animation.sh
This library script provides animations and progress indicators used by the main backup scripts.

### helper/json_helper.sh
This helper script provides functions to read and manipulate JSON data within the backup scripts.


## Additional AWS Setup Requirements

### SSH Key Management

1. **Store SSH Keys in AWS Secrets Manager:**
   - Store your SSH public key and private key in AWS Secrets Manager.
   - If your private key is encrypted, also store the private key password.

2. **Example Secrets Manager Entries:**
   - `privateKey`
   - `publicKey`
   - `privateKeyPassword` (if applicable)

### Customer Managed KMS Key

1. **Create a Customer Managed KMS Key:**
   - Go to the AWS KMS console and create a new customer managed key.
   - Note down the KMS key ID.

2. **Add KMS Key ID to Configuration:**
   - Update the `config/aws.json` file with the KMS key ID.

### IAM Role for RDS Snapshot Export

1. **Create an IAM Role:**
   - Create an IAM role with permissions to export RDS snapshots.

2. **Required Permissions:**
   - `rds:StartExportTask`
   - `s3:PutObject`
   - `s3:GetObject`
   - `s3:GetListBucket`
   - `kms:Encrypt`
   - `kms:Decrypt`

3. **Attach the Role to the RDS Instance:**
   - Attach the created IAM role to your RDS instance.
