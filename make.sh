#!/bin/bash
#
# make.sh [instance] [version (default "2.7.1")]
#
# Build the package.

# Ensure a non zero exit value to break the build procedure.
set -e

instance=$1
if [ -z "$instance" ] ; then
	echo "Need a name of the project build."
	exit -1
fi

version=$2
if [ -z "$version" ] ; then
	version="2.7.1"
	echo "Default version ${version}"
fi

revision=$(git rev-parse HEAD)
app=$instance-$version
target=target/$app
expect=$target.tar.gz
make=Open-ILS

echo "Build $expect from revision $revision"
echo $revision > "${make}/web/build.txt"


# Remove previous builds.
if [ -d target ] ; then
	rm -r target
fi

# Move the files to a folder that has the same name as the Evergreen-ILS-version
rsync -av --delete --exclude='.git' --exclude='.gitignore' --exclude='make.sh' . $app

# Add dojo library
v=dojo-release-1.3.3
d=/tmp/$v.tar.gz
if [ ! -f $d ] ; then
    wget -O $d http://download.dojotoolkit.org/release-1.3.3/$v.tar.gz
fi

tar -C /tmp -xzf $d
mv /tmp/$v/* $app/$make/web/js/dojo/
if [ ! -d $app/$make/web/js/dojo/dojo ] ; then
    echo -e "dojo library not installed in ${app}/${make}/web/js/dojo"
fi

mkdir target
tar -zcvf $expect $app
rm -rf $app

if [ -f $expect ] ; then
    echo "Build ok."
else
	echo -e "Unable to build ${expect}"
fi
