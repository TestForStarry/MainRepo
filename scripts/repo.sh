#!/bin/bash

targetConfigPath="/tmp/SubReposConfig"

function InitRepoConfig() {
	SubReposConfigUrl="git@github.com:TestForStarry/SubRepos.git"

	# Pull SubReposConfig from remote repository
	echo "Pulling SubReposConfig from ${SubReposConfig} ..."
	git clone ${SubReposConfigUrl} ${targetConfigPath}
	if [ $? -ne 0 ]; then
		echo "Error: git clone ${SubReposConfigUrl} failed!"
		exit 1
	fi
}

local RepoName=""
local RepoPath=""
local RepoFile="./scripts/repo.json"
if [ ! -f ${RepoFile} ]; then
	echo "Error: repo.json file not found!"
	exit 1
fi
local JsonData=$(cat ${RepoFile} | jq -c '.[]')
local RepoConfigFile=""
# Load .gitrepo files in SubReposConfig to local integral repository
function loadRepo() {
	for row in $(echo ${JsonData} | jq -r '. | @base64'); do
		_jq() {
			echo ${row} | base64 --decode | jq -r ${1}
		}
		RepoName=$(_jq '.name')
		RepoPath=$(_jq '.localPath')
		if [ -z ${RepoName} ]; then
			echo "Error: RepoName or RepoUrl is empty!"
			exit 1
		fi
		
		if [ -z ${RepoPath} ]; then
			RepoPath=${RepoName}
		fi
		RepoConfigFile="${targetConfigPath}/.gitrepo.${RepoName}"
		if [ ! -f ${RepoConfigFile} ]; then
			echo "Error: ${RepoConfigFile} not found!"
			exit 1
		fi
		cp ${RepoConfigFile} ./${RepoPath}/.gitrepo
	done
	echo "Load .gitrepo files in SubReposConfig to local integral repository successfully!"
}

# Commit changes in .gitrepo files in the local integral repo and push to remote repository
function updateRepo()
{	
	for row in $(echo ${JsonData} | jq -r '. | @base64'); do
		_jq() {
			echo ${row} | base64 --decode | jq -r ${1}
		}
		RepoName=$(_jq '.name')
		RepoPath=$(_jq '.localPath')
		if [ -z ${RepoName} ]; then
			echo "Error: RepoName or RepoUrl is empty!"
			exit 1
		fi
		
		if [ -z ${RepoPath} ]; then
			RepoPath=${RepoName}
		fi

		# collect .gitrepo files in local integral repository to the targetConfigPath
		RepoConfigFile="./${RepoPath}/.gitrepo"
		if [ ! -f ${RepoConfigFile} ]; then
			echo "Error: ${RepoConfigFile} not found!"
			exit 1
		fi
		cp ${RepoConfigFile} ${targetConfigPath}/.gitrepo.${RepoName}
	done

	# commit and push changes in .gitrepo files in the targetConfigPath
	cd ${targetConfigPath}
	git add .
	currentTime=$(date +%Y%m%d%H%I%M)
	git commit -m "Update .gitrepo files in ${currentTime}"
	git push
}
