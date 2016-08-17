#!/bin/bash
# Run build process in docker container.

set -ex -o pipefail

CID=
function docker_rm() {
    if [[ -z "$CID" ]]; then
        return 0
    fi
    if [[ -n "$LEAVE_CONTAINER" ]]; then
        if [[ "${LEAVE_CONTAINER}" != "0" ]]; then
            echo "Skip to clean container: ${CID}"
            return 0
        fi
    fi
    docker rm -f "$CID" 
}

trap "docker_rm" EXIT

BUILD_ENV_PATH=${1:?"ERROR: env file is not given."}

if [[ -n "${BUILD_ENV_PATH}" && ! -f "${BUILD_ENV_PATH}" ]]; then
  echo "ERROR: Can't find the file: ${BUILD_ENV_PATH}" >&2
  exit 1
fi

echo "COMMIT_ID=$(git rev-parse HEAD)" >> ${BUILD_ENV_PATH}
# /tmp is memory file system on docker.
echo "WORK_DIR=/var/tmp/rpmbuild" >> ${BUILD_ENV_PATH}

# http://stackoverflow.com/questions/19331497/set-environment-variables-from-file
set -a
. ${BUILD_ENV_PATH}
set +a

/usr/bin/env
img_tag="openvnet/${BRANCH_NAME}"
docker build -t "${img_tag}" - < "./deployment/docker/el7.Dockerfile"
CID=$(docker run ${BUILD_ENV_PATH:+--env-file $BUILD_ENV_PATH} -d "${img_tag}")
# Upload checked out tree to the container.
docker cp . "${CID}:/var/tmp/openvnet"
# Upload build cache if found.
if [[ -n "$BUILD_CACHE_DIR" ]]; then
  for f in $(ls "${BUILD_CACHE_DIR}"); do
    cached_commit=$(basename $f)
    cached_commit="${cached_commit%.*}"
    if git rev-list "${COMMIT_ID}" | grep "${cached_commit}" > /dev/null; then
      echo "FOUND build cache ref ID: ${cached_commit}"
      cat "${BUILD_CACHE_DIR}/$f" | docker cp - "${CID}:/"
      break;
    fi
  done
fi
# Run build script
docker exec -t "${CID}" /bin/bash -c "cd openvnet; SKIP_CLEANUP=1 ./deployment/packagebuild/build_packages_vnet.sh"
rel_path=$(docker exec -i "${CID}" cat /var/tmp/repo_rel.path)
if [[ -n "$BUILD_CACHE_DIR" ]]; then
    if [[ ! -d "$BUILD_CACHE_DIR" || ! -w "$BUILD_CACHE_DIR" ]]; then
        echo "ERROR: BUILD_CACHE_DIR '${BUILD_CACHE_DIR}' does not exist or not writable." >&2
        exit 1
    fi
    docker cp './deployment/docker/build-cache.list' "${CID}:/var/tmp/build-cache.list"
    docker exec "${CID}" tar cO --directory=/ --files-from=/var/tmp/build-cache.list > "${BUILD_CACHE_DIR}/${COMMIT_ID}.tar"
fi
# Pull compiled yum repository
docker cp "${CID}:${REPO_BASE_DIR}" "$(dirname ${REPO_BASE_DIR})"