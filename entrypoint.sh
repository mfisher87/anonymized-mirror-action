#!/bin/sh

# Exit if the current remote URL is the destination URL
if git config --get remote.origin.url | grep -q "$INPUT_DESTINATION_GIT_URL"; then
	exit 0
fi

# Setup ssh
mkdir -p "$HOME/.ssh"
SSH_FILEPATH="$HOME/.ssh/id_ed25519"
echo "$INPUT_SSH_PRIVATE_KEY" > "$SSH_FILEPATH"
chmod 600 "$SSH_FILEPATH"

# Set safe directory
git config --global --add safe.directory "$GITHUB_WORKSPACE"

# Rewrite authors
git filter-branch --env-filter '
	export GIT_COMMITTER_NAME="$INPUT_ANON_NAME"
	export GIT_COMMITTER_EMAIL="$INPUT_ANON_EMAIL"
	export GIT_AUTHOR_NAME="$INPUT_ANON_NAME"
	export GIT_AUTHOR_EMAIL="$INPUT_ANON_EMAIL"
	' --tag-name-filter cat -- --branches --tags

# Don't host check
git config --global core.sshCommand "ssh -i "$SSH_FILEPATH" -o IdentitiesOnly=yes -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no"

# Update remote URL
git remote set-url origin "$INPUT_DESTINATION_GIT_URL"

# Push to destination
git push --force --tags origin "HEAD:$INPUT_MIRROR_BRANCH"
