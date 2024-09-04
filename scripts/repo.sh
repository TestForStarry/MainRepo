#!/bin/bash
urls=(
	"git@github.com:TestForStarry/TestRepo1.git,TestRepo1"
  	"git@github.com:TestForStarry/TestRepo2.git,TestRepo2"
)
branch=main

for str in ${urls[@]}; do
  IFS=',' read -r -a inner_array <<<"$str"
  echo ${inner_array[0]}
  git subrepo clone ${inner_array[0]} -b $branch ${inner_array[1]}
done
