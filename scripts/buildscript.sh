#!/bin/bash -e
#Global variables that are needed to be passed:
#BUILD_NUMBER - Usually passed by jenkins, used to build the GLUON_RELEASE string
#GLUONBRANCHES - The autoupdater branches to use: stable, beta and so on
#GLUONRELEASE - Release number to use for the images
#TAG - Git tag or branch 
#BUILDTARGETS - Comma seperated list of targets to build
#COMMUNITIES - Communities to build the firmware for
#VERBOSE - Set to 1 or 0 to enable or disable verbose building
#JOBS - Number of compiler threads
echo "---------------------------------------------------------------------------------------------------------"
echo "Build ID: ${BUILD_NUMBER}"
echo "Gluon branches to build: $(echo ${GLUONBRANCHES} | sed 's/,/ /g')"
echo "Gluon Release: ${GLUONRELEASE}"
echo "Git tag/branch: ${TAG}"
echo "Targets to build: $(echo $BUILDTARGETS | sed 's/,/ /g')"
echo "Gluon release number will be: ${GLUONRELEASE}-${BUILD_NUMBER}"
echo "Communities are: $(echo $COMMUNITIES | sed 's/,/ /g')"
[ "${VERBOSE}" = "true" ] && echo "Verbose mode is ON"
echo "Number of make jobs to run : ${JOBS}"

#Clear dist directory
rm -rf dist/*

#Build FW for all selected communities
for COMMUNITY in $(echo $COMMUNITIES | sed 's/,/ /g')
do
    echo "---------------------------------------------------------------------------------------------------------"
    echo "Building firmwares for community: ${COMMUNITY}"
    for GLUONBRANCH in $(echo $GLUONBRANCHES | sed 's/,/ /g')
    do
        echo "Building ${GLUONBRANCH} images"
        #Delete old site config folder and output directory 
        rm -rf output
        rm -rf site
        
        #(Re)Create output & log directory
        mkdir -p output/logs
        
        #Pull config based on selected GLUONBRANCH
        case "${COMMUNITY}" in
            ddorf)
            	repo="https://github.com/ffddorf/gluon-site.git"
                case "${GLUONBRANCH}" in
                    stable|beta)
                        echo "Gluon config branch/tag: ${GLUONRELEASE}"
                        git clone --branch ${GLUONRELEASE} ${repo} site >/dev/null 2>&1
                        echo "Gluon config commit ID: $(cd site && git rev-parse --verify HEAD)"
                    ;;
                    *)
                        echo "Gluon config branch/tag: master"
                        git clone ${repo} site >/dev/null 2>&1
                        echo "Gluon config commit ID: $(cd site && git rev-parse --verify HEAD)"
                    ;;
                esac
            ;;
            neuss)
            	repo="https://github.com/ffne/gluon-site.git"
                case "${GLUONBRANCH}" in
                    stable|beta)
                        echo "Gluon config branch/tag: ${GLUONRELEASE}"
                        git clone --branch ${GLUONRELEASE} ${repo} site >/dev/null 2>&1
                        echo "Gluon config commit ID: $(cd site && git rev-parse --verify HEAD)"
                    ;;
                    *)
                        echo "Gluon config branch/tag: master"
                        git clone ${repo} site >/dev/null 2>&1
                        echo "Gluon config commit ID: $(cd site && git rev-parse --verify HEAD)"
                    ;;
                esac
            ;;
            *)
                echo "Gluon config branch/tag: lede-dev"
                git clone --branch lede-dev https://github.com/ffddorf/site-ddorf.git site >/dev/null 2>&1
                echo "Gluon config commit ID: $(cd site && git rev-parse --verify HEAD)"
            ;;
        esac
    
        echo "Running 'make update'"
        make update &> output/logs/mkupdate.log
        echo "Clear old build targets folder for rebuild"
        for TARGET in $(echo $BUILDTARGETS | sed 's/,/ /g')
        do
            make clean GLUON_TARGET="${TARGET}" &> output/logs/clean.log
        done
        
        for TARGET in $(echo $BUILDTARGETS | sed 's/,/ /g')
        do
            echo "Building Gluon Target: ${TARGET}"
            if [ "${VERBOSE}" = "true" ]; then
                make GLUON_BRANCH="${GLUONBRANCH}" GLUON_TARGET="${TARGET}" GLUON_RELEASE="${GLUONRELEASE}-${BUILD_NUMBER}" -j${JOBS} V=99 &> output/logs/${TARGET}.log
            else
                make GLUON_BRANCH="${GLUONBRANCH}" GLUON_TARGET="${TARGET}" GLUON_RELEASE="${GLUONRELEASE}-${BUILD_NUMBER}" -j${JOBS} &> output/logs/${TARGET}.log
            fi
        done
        echo "Building manifest"
        make manifest GLUON_RELEASE="${GLUONRELEASE}-${BUILD_NUMBER}" GLUON_BRANCH="${GLUONBRANCH}"
        echo "Copying release folder contents"
        mkdir -p dist/${COMMUNITY}/${GLUONBRANCH}
        mv output/images/* dist/${COMMUNITY}/${GLUONBRANCH}/
        mv output/logs dist/${COMMUNITY}/${GLUONBRANCH}/
        cp -r site dist/${COMMUNITY}/${GLUONBRANCH}/ && rm -rf dist/${COMMUNITY}/${GLUONBRANCH}/site/.git
        echo "Generating version.json"
        echo "{\"version\": \"${GLUONRELEASE}-${BUILD_NUMBER}\",\"tag\": \"${TAG}\"}" > dist/${COMMUNITY}/${GLUONBRANCH}/version.json
        echo "${GLUONBRANCH} build for ${COMMUNITY} done"
    done
done
echo "Buildscript finished"
