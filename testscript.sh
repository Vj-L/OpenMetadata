#!/bin/bash

CONF_FILE=openmetadata.yaml

GIT_CLONE_HOME_DIR=/home/ubuntu
GIT_CLONE_URL="https://github.com/open-metadata/OpenMetadata.git"
GIT_BRANCH="main"
GIT_PROJECT_NAME=OpenMetadata
SERVER_DIR=/opt/openmetadata

# Clone the repo main branch
git clone $GIT_CLONE_URL --branch $GIT_BRANCH --single-branch $GIT_CLONE_HOME_DIR/$GIT_PROJECT_NAME

# Build Maven project
mvn -f $GIT_CLONE_HOME_DIR/$GIT_PROJECT_NAME/pom.xml -DskipTests clean package
if [ $? -ne 0 ]
then
exit $?
fi

# Stop Open Metadata Script
$SERVER_DIR/bin/openmetadata.sh stop $SERVER_DIR/conf/$CONF_FILE

# Clean openmetadata directory
rm -rf $SERVER_DIR

# untar dist project
tar zxvf $GIT_CLONE_HOME_DIR/$GIT_PROJECT_NAME/openmetadata-dist/target/openmetadata-*.tar.gz -C $SERVER_DIR --strip-components>


# Run Bootstrap Migrate Script
$SERVER_DIR/bootstrap/bootstrap_storage.sh validate &> /dev/null
if [ $? -ne 0 ]
then
echo "Failed to validate database migrations. Self healing using bootstrap_storage.sh repair command..."
$SERVER_DIR/bootstrap/bootstrap_storage.sh repair
fi
$SERVER_DIR/bootstrap/bootstrap_storage.sh migrate-all

# Start Open Metadata Service
$SERVER_DIR/bin/openmetadata.sh start $SERVER_DIR/conf/$CONF_FILE

# Cleanup
rm -rf $GIT_CLONE_HOME_DIR/$GIT_PROJECT_NAME
