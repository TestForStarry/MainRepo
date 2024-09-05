ACTOR=$1
ACTOR_ID=$2

git config user.name $ACTOR
git config user.email "$ACTOR_ID+$ACTOR@users.noreply.github.com"
source /tmp/git-subrepo/.rc
source ./scripts/build/repo.sh
CloneRepoConfig
LoadRepoConfig
UpdateRepoConfig