#!/bin/bash
mkdir temp_file
cp -R /app/data temp_file
cp config.yml temp_file
cd temp_file/data
sqlite3 sqlite.db "DELETE FROM service_histories;"
cd ..
# Check if required environment variables are set
if [ -z "$GITHUB_USERNAME" ] || [ -z "$REPO_NAME" ] || [ -z "$GITHUB_TOKEN" ]; then
    echo "Error: Please set GITHUB_USERNAME, REPO_NAME, 和 GITHUB_TOKEN environment variables"
    exit 1
fi

# Create timestamp for backup (Shanghai time)
TIMESTAMP=$(TZ='Asia/Shanghai' date +"%Y-%m-%d-%H-%M-%S")
BACKUP_FILE="data-${TIMESTAMP}.zip"
echo "$BACKUP_FILE" > README.md

# Compress data directory and config.yml
zip -r -P "$ZIP_PASSWORD" "$BACKUP_FILE" data config.yml

# GitHub repository details
GITHUB_REPO="https://${GITHUB_USERNAME}:${GITHUB_TOKEN}@github.com/${GITHUB_USERNAME}/${REPO_NAME}.git"

# Clone or pull the repo
if [ ! -d "temp_repo" ]; then
    git clone "$GITHUB_REPO" temp_repo
fi
cd temp_repo

# Fetch existing backup files from the repository
git pull origin main

# Add backup file to repo root
cp "../$BACKUP_FILE" "../README.md" ./

# Remove old backups, keeping only the 5 most recent
BACKUPS=$(ls data-*.zip 2>/dev/null | sort -r)
BACKUPS_TO_REMOVE=$(echo "$BACKUPS" | tail -n +6)
for backup in $BACKUPS_TO_REMOVE; do
    git rm "$backup"
done

# Commit and push
git add "$BACKUP_FILE" "README.md"
git config user.name "Backup Script"
git config user.email "backup@localhost"
git commit -m "Add backup: $BACKUP_FILE"
git push

# Clean up
cd ..
rm "$BACKUP_FILE"
rm -rf /app/temp_file

echo "Backup completed successfully"
