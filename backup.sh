#!/bin/bash
# Backs up /data to a force-pushed 'chain-backup' branch. Meant to be invoked
# with an outer `timeout` so nothing here can hang the calling loop forever.
set -e
export GIT_TERMINAL_PROMPT=0

rm -rf /tmp/backup_repo
mkdir -p /tmp/backup_repo/data
cp -a /data/. /tmp/backup_repo/data/

cd /tmp/backup_repo
git init -q
git config user.email "backup@meduzcoin.local"
git config user.name "Meduz Backup"
echo "Automated chain-data backup, $(date -u +%Y-%m-%dT%H:%M:%SZ)" > README-BACKUP.txt
git add -A
git commit -q -m "Backup $(date -u +%Y-%m-%dT%H:%M:%SZ)"
echo "remote url (redacted): https://***@github.com/${BACKUP_REPO}.git"
git push -f "https://${BACKUP_GIT_TOKEN}@github.com/${BACKUP_REPO}.git" HEAD:chain-backup 2>&1

cd /
rm -rf /tmp/backup_repo
echo "backup-script-done"
