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

RepoName=""
RepoPath=""
RepoFile="./scripts/build/repo.json"
if [ ! -f ${RepoFile} ]; then
	echo "Error: repo.json file not found!"
	exit 1
fi
JsonData=$(cat ${RepoFile} | jq -c '.[]')
RepoConfigFile=""

function InitRepo() {
	local RepoBranch=""
	local RepoUrl=""
	for row in $(echo ${JsonData} | jq -r '. | @base64'); do
		_jq() {
			echo ${row} | base64 --decode | jq -r ${1}
		}
		RepoName=$(_jq '.name')
		RepoUrl=$(_jq '.url')
		RepoBranch=$(_jq '.branch')
		RepoPath=$(_jq '.localPath')
		if [ -z ${RepoName} ] || [ -z ${RepoUrl} ]; then
			echo "Error: RepoName or RepoUrl is empty!"
			exit 1
		fi
		if [ "${RepoBranch}" == "null" ] || [ -z "${RepoBranch}" ]; then
			echo "Warning: RepoBranch is empty or null, use master as default!"
			RepoBranch="main"
		fi
		if [ -z ${RepoPath} ]; then
			RepoPath=${RepoName}
		fi
		
		git subrepo clone -b ${RepoBranch} ${RepoUrl} ${RepoPath}
		if [ $? -ne 0 ]; then
			echo "Error: git clone -b ${RepoBranch} ${RepoUrl} ${RepoPath} failed!"
			exit 1
		fi

	done
}

# Load .gitrepo files in SubReposConfig to local integral repository
function LoadRepoConfig() {
	for row in $(echo ${JsonData} | jq -r '. | @base64'); do
		_jq() {
			echo ${row} | base64 --decode | jq -r ${1}
		}
		RepoName=$(_jq '.name')
		RepoPath=$(_jq '.localPath')
		if [ -z ${RepoName} ]; then
			echo "Error: RepoName is empty!"
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
function UpdateRepoConfig()
{	
	# Store the initial commit hash for integral repository
	local PARENT_COMMIT_HASH=$1
	# Push the changes in sub repository to remote
	git subrepo pull -a
	if [ $? -ne 0 ]; then
		echo "Error: git subrepo pull -a failed!"
		exit 1
	fi
	
	for row in $(echo ${JsonData} | jq -r '. | @base64'); do
		_jq() {
			echo ${row} | base64 --decode | jq -r ${1}
		}
		RepoName=$(_jq '.name')
		RepoPath=$(_jq '.localPath')
		if [ -z ${RepoName} ]; then
			echo "Error: RepoName is empty!"
			exit 1
		fi
		
		if [ -z ${RepoPath} ]; then
			RepoPath=${RepoName}
		fi

		# collect .gitrepo files in local integral repository to the targetConfigPath
		RepoConfigFile="./${RepoPath}/.gitrepo"
		# Check the RepoConfig File and replace the `parent` file with the PARENT_COMMIT_HASH
		if [ ! -f ${RepoConfigFile} ]; then
			echo "Error: ${RepoConfigFile} not found!"
			exit 1
		fi

		sed -i "s/parent.*/parent: ${PARENT_COMMIT_HASH}/" ${RepoConfigFile}

		cp ${RepoConfigFile} ${targetConfigPath}/.gitrepo.${RepoName}
	done

	# commit and push changes in .gitrepo files in the targetConfigPath
	cd ${targetConfigPath}
	git add .
	currentTime=$(date +%Y%m%d%H%I%M)
	git commit -m "Update .gitrepo files in ${currentTime}"
	git push
}
