#!/bin/bash

: '
Description:
This script automates the backup of a MySQL database from a remote Linux server to a local storage location. It establishes an SSH connection to the remote server using public key authentication and uses the mysqldump command to create a backup of the specified database with a timestamp appended to the file name. If the backup is successful, it removes any backups older than 10 days from the remote backup path.

The script uses the "scp" command to copy the backup file from the remote server to a local path. The script also specifies a minimum backup file size in KB and checks the size of the transferred backup file using the "du" command. If the file size is smaller than the specified minimum size, the script exits with an error message, removes the incomplete backup file, and terminates. Otherwise, it removes any local backups of this database older than 10 days from the local backup path.

The script contains several variables that can be adjusted according to specific needs, such as the remote server details (server name, username, password, private key location, backup path), local backup path, database name, MySQL username, password, timestamp format, minimum backup file size, and backup retention periods on the remote and local backup paths.

Overall, this script automates the MySQL database backup process and ensures that backup files are transferred securely to a local storage location and meet specific size requirements.
'

# Exit immediately if a command exits with a non-zero status.
set -e

# Remote Linux server details
REMOTE_SERVER="remote.server.com"
REMOTE_USER="username"
REMOTE_PASSWORD="password"
PRIVATE_KEY="/path/to/private/key"
REMOTE_BACKUP_PATH="/backup/path/on/remote/server"

# Local file path for backup storage
LOCAL_BACKUP_PATH="/path/to/backups"

# Database name to be backed up
DB_NAME="database_name"

# MySQL username and password
MYSQL_USER="mysql_user"
MYSQL_PASSWORD="mysql_password"

# Timestamp for backup file
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

# Minimum backup file size in KB
MINIMUM_SIZE=1000

# Number of days to keep backups in remote backup path
REMOTE_BACKUP_DAYS=10

# Number of days to keep backups in local backup path
LOCAL_BACKUP_DAYS=10

# Establish SSH connection to remote server using public key authentication
ssh -i $PRIVATE_KEY $REMOTE_USER@$REMOTE_SERVER "

# Backup MySQL database with timestamp and if successful, remove backups older than 10 days
mysqldump -u $MYSQL_USER -p$MYSQL_PASSWORD $DB_NAME > $REMOTE_BACKUP_PATH/$DB_NAME-backup_$TIMESTAMP.sql && \
find $REMOTE_BACKUP_PATH/$DB_NAME-backup* -mtime +$REMOTE_BACKUP_DAYS -type f -delete
"

# Copy database backup to local file path using SCP
scp -i $PRIVATE_KEY $REMOTE_USER@$REMOTE_SERVER:$REMOTE_BACKUP_PATH/$DB_NAME-backup_$TIMESTAMP.sql $LOCAL_BACKUP_PATH/$DB_NAME-backup_$TIMESTAMP.sql

# Check backup file size and if it's smaller than the minimum specified size, exit with error message
backup_size=$(du -k "$LOCAL_BACKUP_PATH/$DB_NAME-backup_$TIMESTAMP.sql" | awk '{print $1}')
if [ $backup_size -lt $MINIMUM_SIZE ]; then
    echo "Error: Backup file size is $backup_size KB, which is less than the minimum accepted value of $MINIMUM_SIZE KB. Backup aborted."
    rm $LOCAL_BACKUP_PATH/$DB_NAME-backup_$TIMESTAMP.sql
    exit 1
else
	find $LOCAL_BACKUP_PATH/$DB_NAME-backup* -mtime +$LOCAL_BACKUP_DAYS -type f -delete
    echo "MySQL database backup successfully transferred to $LOCAL_BACKUP_PATH - Removed any local backup for this database older than $LOCAL_BACKUP_DAYS days."
fi

exit 0
