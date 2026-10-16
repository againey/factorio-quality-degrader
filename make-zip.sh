#!/bin/bash

MODNAME='quality-degrader'
VERSION=$1
ZIPFILE="${MODNAME}_${VERSION}.zip"
DIRECTORY=$MODNAME
EXCLUDE="${DIRECTORY}/make-zip.sh ${DIRECTORY}/thumbnail.svg ${DIRECTORY}/TODO.md ${DIRECTORY}/.editorconfig ${DIRECTORY}/${MODNAME}_*.zip"

find . -name "${MODNAME}_*.zip" -delete
cd ..
zip -r $DIRECTORY/$ZIPFILE $DIRECTORY -x $DIRECTORY/.git\* $EXCLUDE
cd $DIRECTORY
