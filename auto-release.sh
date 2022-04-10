APP_DOCKER_REPO=$APP_DOCKER_REPO
APP_MANIFEST=$APP_MANIFEST
HYPERION_APP_MANIFEST="values.yaml"
REPO=$REPO
GIT_REPO="github.com/$REPO.git"
HYPERION_REPO=$HYPERION_REPO
HYPERION_GIT_REPO="github.com/$HYPERION_REPO.git"
GIT_CONFIG_EMAIL=$GIT_CONFIG_EMAIL
GIT_CONFIG_NAME=$GIT_CONFIG_NAME
GIT_USERNAME=$GIT_USERNAME
GITHUB_TOKENS=$GITHUB_TOKENS
GIT_BRANCH=$GIT_BRANCH
RAW_GIT_REPO=$RAW_GIT_REPO
VERSION_FILE=$VERSION_FILE
RELEASE_BRANCH=$RELEASE_BRANCH
MIGRATOR_FILE=$MIGRATOR_FILE
MIGRATOR_LINE_1=$MIGRATOR_LINE_1
MIGRATOR_LINE_2=$MIGRATOR_LINE_2
VERSION_FILE_HYPERION="charts/devtron/values.yaml"

#Getting the commits
BUILD_COMMIT=$(git rev-parse HEAD)
echo $BUILD_COMMIT
echo $DOCKER_IMAGE_TAG
echo "========================check================================"
mkdir preci
cd preci
wget https://github.com/cli/cli/releases/download/v1.5.0/gh_1.5.0_linux_386.tar.gz -O ghcli.tar.gz
tar --strip-components=1 -xf ghcli.tar.gz
echo "=============================after cli download======================="
echo $GITHUB_TOKENS > tokens.txt
echo "===========================check token======================="
bin/gh auth login --with-token < tokens.txt
echo "================================authentication==============="
bin/gh repo clone "$REPO"
echo "========================================repo clone command above==="
cd devtron
git checkout "$GIT_BRANCH"
git checkout -b "$RELEASE_BRANCH"
git pull origin "$RELEASE_BRANCH"
echo "============ ls -la========"
ls -la
#Updating Image in the yaml for devtron
sed -i "s/quay.io\/devtron\/$APP_DOCKER_REPO:.*/quay.io\/devtron\/$APP_DOCKER_REPO:$DOCKER_IMAGE_TAG\"/" manifests/yamls/$APP_MANIFEST

#VERIFYING MANIFEST
cat manifests/yamls/$APP_MANIFEST

#Setting Git configurations
git config --global user.email "$GIT_CONFIG_EMAIL"
git config --global user.name "$GIT_CONFIG_NAME"
echo "https://raw.githubusercontent.com/$REPO/$GIT_BRANCH/$VERSION_FILE"
DEV_RELEASE=$(curl -L -s  "https://raw.githubusercontent.com/$REPO/$GIT_BRANCH/$VERSION_FILE" )
RELEASE_VERSION=$(../bin/gh release list -L 1 -R $REPO | awk '{print $1}')

#Comparing version mentioned in the version.txt with latest release version
if [[ $DEV_RELEASE == $RELEASE_VERSION ]]
  then
    #RELEASE_VERSION=$(../bin/gh release list -L 1 -R $REPO | awk '{print $1}')
    NEXT_RELEASE_VERSION=$(echo ${DEV_RELEASE} | awk -F. -v OFS=. '{$NF++;print}')
    echo "NEXTVERSION from inside loop: $NEXT_RELEASE_VERSION"
    sed -i "s/$DEV_RELEASE/$NEXT_RELEASE_VERSION/" $VERSION_FILE
  else
    NEXT_RELEASE_VERSION=$DEV_RELEASE
    echo "NEXTVERSION from inside ESLE: $NEXT_RELEASE_VERSION"
fi
#Updating LTAG Version in the installation-script
sed -i "s/LTAG=.*/LTAG=\"$NEXT_RELEASE_VERSION\";/" manifests/installation-script

#Updating latest installation-script URL in the devtron-installer.yaml
sed -i "s/url:.*/url: $RAW_GIT_REPO$NEXT_RELEASE_VERSION\/manifests\/installation-script/" manifests/install/devtron-installer.yaml



echo "=================If else check from migration======================="
if [[ $MIGRATOR_LINE_1 == "x" ]]
  then
   echo "No Migration Changes"
  else 
# ========== Updating the Migration script with latest commit hash ==========
    echo "Migration hash update"
    sed -i "$MIGRATOR_LINE_1 s/value.*/value: $BUILD_COMMIT/" manifests/yamls/$MIGRATOR_FILE
fi

if [[ $MIGRATOR_LINE_2 == "x" ]]
  then
   echo "No Migration Changes for casbin"
  else 
# ========== Updating the Migration script with latest commit hash ==========
    echo "Migration hash update"
    sed -i "$MIGRATOR_LINE_2 s/value.*/value: $BUILD_COMMIT/" manifests/yamls/$MIGRATOR_FILE
fi
echo "=================If else end for migration======================="

git commit -am "Updated latest image of $APP_DOCKER_REPO in the installer"
git push -f https://$GIT_USERNAME:$GITHUB_TOKENS@$GIT_REPO --all
#Creating Release ######################

PR_RESPONSE=$(../bin/gh pr create --title "RELEASE: PR for $NEXT_RELEASE_VERSION" --body "Updates in $APP_DOCKER_REPO micro-service" --base $GIT_BRANCH --head $RELEASE_BRANCH --repo $REPO)
echo "FINAL PR RESPONSE: $PR_RESPONSE"


echo "==============================Hyperion Repo==========================="
cd ..
ls
pwd
echo "=============================checking files=========================="
bin/gh repo clone "gunish-dt/hyperionRelease"
cd charts
git checkout "$GIT_BRANCH"
git checkout -b "$RELEASE_BRANCH"
git pull origin "$RELEASE_BRANCH"


#Updating Image in the yaml for hyperion
sed -i "s/quay.io\/devtron\/$APP_DOCKER_REPO:.*/quay.io\/devtron\/$APP_DOCKER_REPO:$DOCKER_IMAGE_TAG\"/" charts/devtron/$HYPERION_APP_MANIFEST

#VERIFYING MANIFEST
cat charts/devtron/$HYPERION_APP_MANIFEST

echo "######################################"

if [[ $DEV_RELEASE == $RELEASE_VERSION ]]
  then
    #RELEASE_VERSION=$(../bin/gh release list -L 1 -R $REPO | awk '{print $1}')
    HYP_RELEASE_VERSION=$(echo ${DEV_RELEASE} | awk -F. -v OFS=. '{$NF++;print}')
    echo "NEXTVERSION from inside loop: $HYP_RELEASE_VERSION"
    sed -i "s/$DEV_RELEASE/$HYP_RELEASE_VERSION/" $VERSION_FILE_HYPERION
  else
    HYP_RELEASE_VERSION=$DEV_RELEASE
    echo "NEXTVERSION from inside ESLE: $HYP_RELEASE_VERSION"
fi
  
git commit -am "Updated latest image of $APP_DOCKER_REPO in Values.yaml file"
git push -f https://$GIT_USERNAME:$GITHUB_TOKENS@$HYPERION_GIT_REPO --all
#Creating Release ######################
#RELEASE_RESPONSE=$(../bin/gh release create $NEXT_RELEASE_VERSION --target $RELEASE_BRANCH -R $REPO)
#echo "FINAL RELEASE RESPONSE: $RELEASE_RESPONSE"
#Creating PR into main branch
HYPE_PR_RESPONSE=$(../bin/gh pr create --title "RELEASE: PR for $NEXT_RELEASE_VERSION" --body "Updates in $APP_DOCKER_REPO micro-service" --base $GIT_BRANCH --head $RELEASE_BRANCH --repo $HYPERION_REPO)
echo "FINAL PR RESPONSE: $HYPE_PR_RESPONSE"