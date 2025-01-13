#!/bin/bash

set -x

#!/bin/bash -eux

GO_LINUX_PACKAGE_URL="https://dl.google.com/go/go1.14.linux-amd64.tar.gz"
wget --no-check-certificate --progress=dot:mega ${GO_LINUX_PACKAGE_URL} -O go-linux.tar.gz 
tar -zxf go-linux.tar.gz
mv go /usr/local/
mkdir -p /go/bin /go/src /go/pkg

export GO_HOME=/usr/local/go
export GOPATH=/go
export PATH=${GOPATH}/bin:${GO_HOME}/bin/:$PATH

THIS_GITHUB_EVENT=$(cat $GITHUB_EVENT_PATH)
RELEASE_UPLOAD_URL=$(echo $THIS_GITHUB_EVENT | jq -r .release.upload_url)
RELEASE_UPLOAD_URL=${RELEASE_UPLOAD_URL/\{?name,label\}/}
RELEASE_TAG_NAME=$(echo $THIS_GITHUB_EVENT | jq -r .release.tag_name)
PROJECT_NAME=$(basename $GITHUB_REPOSITORY)

EXECUTABLE_FILES=`/build.sh`

echo "The executable files recieved are : $EXECUTABLE_FILES"
EXECUTABLE_FILES=`echo "${EXECUTABLE_FILES}" | awk '{$1=$1};1'`
echo "The executable files NOW are : $EXECUTABLE_FILES"

PROJECT_ROOT="/go/src/github.com/${GITHUB_REPOSITORY}"
TMP_ARCHIVE=tmp.tgz
CKSUM_FILE=md5sum.txt

echo "The PROJECT_ROOT is : $PROJECT_ROOT"
echo "The SUBDIR is : $SUBDIR"
echo "The EXECUTABLE_FILES is : $EXECUTABLE_FILES"
echo "The CKSUM_FILE is : $CKSUM_FILE"

md5sum ${PROJECT_ROOT}/${SUBDIR}/${EXECUTABLE_FILES} | cut -d ' ' -f 1 > ${CKSUM_FILE}

echo "The TMP_ARCHIVE is : $TMP_ARCHIVE"
echo "The CKSUM_FILE is : $CKSUM_FILE"
echo "The PROJECT_ROOT is : $PROJECT_ROOT"
echo "The SUBDIR is : $SUBDIR"

tar cvfz ${TMP_ARCHIVE} ${CKSUM_FILE} --directory ${PROJECT_ROOT}/${SUBDIR} ${EXECUTABLE_FILES} 

NAME="${NAME:-${EXECUTABLE_FILES}_${RELEASE_TAG_NAME}}_${GOOS}_${GOARCH}"

echo "The values passed to the curl commands are : "
echo "value of TMP_ARCHIVE : $TMP_ARCHIVE"
echo "value of GITHUB_TOKEN : $GITHUB_TOKEN"
echo "value of RELEASE_UPLOAD_URL : $RELEASE_UPLOAD_URL"
echo "value of NAME : $NAME"
echo "value of TMP_ARCHIVE : $TMP_ARCHIVE"


curl \
  --tlsv1.2 \
  -X POST \
  --data-binary @${TMP_ARCHIVE} \
  -H 'Content-Type: application/octet-stream' \
  -H "Authorization: Bearer ${GITHUB_TOKEN}" \
  "${RELEASE_UPLOAD_URL}?name=${NAME}.${TMP_ARCHIVE/tmp./}"
