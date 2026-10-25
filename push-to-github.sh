#!/usr/bin/env bash
# Pushes this repo to a new GitHub repository over SSH.
set -e
cd "$(dirname "$0")"
read -rp "GitHub username: " GHUSER
read -rp "Repository name (will be created on github.com): " REPO
git remote remove origin 2>/dev/null || true
git remote add origin "git@github.com:${GHUSER}/${REPO}.git"
git branch -M main
git push -u origin main
echo "Pushed: https://github.com/${GHUSER}/${REPO}"
