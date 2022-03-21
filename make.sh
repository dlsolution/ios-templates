#!/bin/sh
set -e

# Script inspired by https://gist.github.com/szeidner/613fe4652fc86f083cefa21879d5522b

readonly PROGNAME=$(basename $0)
readonly WORKING_DIR=$(cd -P -- "$(dirname -- "$0")" && pwd -P)

die() {
    echo "$PROGNAME: $*" >&2
    exit 1
}

usage() {
    if [ "$*" != "" ] ; then
        echo "Error: $*"
    fi

    cat << EOF
Usage: $PROGNAME --bundle-id [BUNDLE_ID_PRODUCTION] --bundle-id-staging [BUNDLE_ID_STAGING] --project-name [PROJECT_NAME]
Set up an iOS app from tuist template.
Options:
-h, --help                                   display this usage message and exit
-b, --bundle-id [BUNDLE_ID_PRODUCTION]       the production id (i.e. com.example.package)
-s, --bundle-id-staging [BUNDLE_ID_STAGING]  the staging id (i.e. com.example.package.staging)
-n, --project-name [PROJECT_NAME]            the project name (i.e. MyApp)
EOF
    exit 1
}

bundle_id_production=""
bundle_id_staging=""
project_name=""

readonly CONSTANT_PROJECT_NAME="{PROJECT_NAME}"
readonly CONSTANT_BUNDLE_PRODUCTION="{BUNDLE_ID_PRODUCTION}"
readonly CONSTANT_BUNDLE_STAGING="{BUNDLE_ID_STAGING}"

while [ $# -gt 0 ] ; do
    case "$1" in
    -h|--help)
        usage
        ;;
    -b|--bundle-id)
        bundle_id_production="$2"
        shift
        ;;
    -s|--bundle-id-staging)
        bundle_id_staging="$2"
        shift
        ;;
    -n|--project-name)
        project_name="$2"
        shift
        ;;
    -*)
        usage "Unknown option '$1'"
        ;;
    *)
        usage "Too many arguments"
      ;;
    esac
    shift
done

if [ -z "$bundle_id_production" ] ; then
    read -p "BUNDLE ID PRODUCTION (i.e. com.example.project):" bundle_id_production
fi

if [ -z "$bundle_id_staging" ] ; then
    read -p "BUNDLE ID STAGING (i.e. com.example.project.staging):" bundle_id_staging
fi

if [ -z "$project_name" ] ; then
    read -p "PROJECT NAME (i.e. NewProject):" project_name
fi

if [ -z "$bundle_id_production" ] || [ -z "$bundle_id_staging" ] || [ -z "$project_name" ] ; then
    usage "Input cannot be blank."
fi

# Enforce package name
regex='^[a-z][a-z0-9_]*(\.[a-z0-9_]+)+[0-9a-z_]$'
if ! [[ $bundle_id_production =~ $regex ]]; then
    die "Invalid Package Name: $bundle_id_production (needs to follow standard pattern {com.example.package})"
fi

echo "=> 🐢 Starting init $project_name ..."

# Trim spaces in APP_NAME
readonly PROJECT_NAME_NO_SPACES=$(echo "$project_name" | sed "s/ //g")

# Rename files structure
echo "=> 🔎 Replacing files structure..."


## user define function
rename_folder(){
	local DIR=$1
	local NEW_DIR=$2
    if [ -d "$DIR" ]
    then
        mv ${DIR} ${NEW_DIR}
    fi
}

# Rename test folder structure
rename_folder "${CONSTANT_PROJECT_NAME}Tests" "${PROJECT_NAME_NO_SPACES}Tests"

# Rename UI Test folder structure
rename_folder "${CONSTANT_PROJECT_NAME}UITests" "${PROJECT_NAME_NO_SPACES}UITests"

# Rename app folder structure
rename_folder "${CONSTANT_PROJECT_NAME}" "${PROJECT_NAME_NO_SPACES}"

echo "✅  Completed"

# Search and replace in files
echo "=> 🔎 Replacing package and package name within files..."
BUNDLE_ID_PRODUCTION_ESCAPED="${bundle_id_production//./\.}"
BUNDLE_ID_STAGING_ESCAPED="${bundle_id_staging//./\.}"
LC_ALL=C find $WORKING_DIR -type f -exec sed -i "" "s/$CONSTANT_BUNDLE_STAGING/$BUNDLE_ID_STAGING_ESCAPED/g" {} +
LC_ALL=C find $WORKING_DIR -type f -exec sed -i "" "s/$CONSTANT_BUNDLE_PRODUCTION/$BUNDLE_ID_PRODUCTION_ESCAPED/g" {} +
LC_ALL=C find $WORKING_DIR -type f -exec sed -i "" "s/$CONSTANT_PROJECT_NAME/$PROJECT_NAME_NO_SPACES/g" {} +
echo "✅  Completed"

# check for tuist and install
if ! command -v tuist &> /dev/null
then
    echo "Tuist could not be found"
    echo "Installing tuist"
    readonly TUIST_VERSION=`cat .tuist-version`
    curl -Ls https://install.tuist.io | bash
    tuist install ${TUIST_VERSION}
fi

# Generate with tuist
echo "Tuist found"
tuist generate
echo "✅  Completed"

# Install dependencies
echo "Installing gems"
bundle install
echo "Installing pod dependencies"
# bundle exec pod install --repo-update
echo "✅  Completed"

# Generate app-icon
OUTDIR=${PROJECT_NAME_NO_SPACES}/Resources/Assets/Assets.xcassets/AppIcon.appiconset

if [ ! -d ./${PROJECT_NAME_NO_SPACES} ] 
  then
    echo Add project first
    exit 1
fi

if [ ! -f icon.png ]
  then
    echo Please add a PNG image named icon.png with size 1024x1024 to this folder and re-run this script.
    exit 1
fi

echo Making $OUTDIR if it does not already exist.
[ -d $OUTDIR ] || mkdir -p $OUTDIR

echo Generating Icons...

sips -z 40 40 --out $OUTDIR/icon-app-20@2x.png icon.png
sips -z 60 60 --out $OUTDIR/icon-app-20@3x.png icon.png
sips -z 58 58 --out $OUTDIR/icon-app-29@2x.png icon.png
sips -z 87 87 --out $OUTDIR/icon-app-29@3x.png icon.png
sips -z 80 80 --out $OUTDIR/icon-app-40@2x.png icon.png
sips -z 120 120 --out $OUTDIR/icon-app-40@3x.png icon.png
sips -z 120 120 --out $OUTDIR/icon-app-60@2x.png icon.png
sips -z 180 180 --out $OUTDIR/icon-app-60@3x.png icon.png
sips -z 20 20 --out $OUTDIR/icon20.png icon.png
sips -z 40 40 --out $OUTDIR/icon20@2x.png icon.png
sips -z 29 29 --out $OUTDIR/icon29.png icon.png
sips -z 58 58 --out $OUTDIR/icon29@2x.png icon.png
sips -z 40 40 --out $OUTDIR/icon40.png icon.png
sips -z 80 80 --out $OUTDIR/icon40@2x.png icon.png
sips -z 76 76 --out $OUTDIR/icon76.png icon.png
sips -z 152 152 --out $OUTDIR/icon76@2x.png icon.png
sips -z 167 167 --out $OUTDIR/icon83.5@2x.png icon.png
sips -z 1024 1024 --out $OUTDIR/icon1024.png icon.png 

# Remove gitkeep files
echo "Remove gitkeep files from project"
sed -i "" "s/.*\(gitkeep\).*,//" $PROJECT_NAME_NO_SPACES.xcodeproj/project.pbxproj
echo "✅  Completed"

# Remove Tuist files
echo "Remove tuist files"
rm -rf .tuist-version
rm -rf tuist
rm -rf Project.swift

# Remove script files and git/index
echo "Remove script files and git/index"
rm -rf make.sh
rm -rf .github/workflows/test_install_script.yml
rm -f .git/index
echo "✅  Completed"

# Done!
echo "=> 🚀 Done! App is ready to be tested 🙌"
