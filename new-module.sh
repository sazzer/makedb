#!/bin/sh

MODULE_NAME=$1

if [ -z "$MODULE_NAME" ]; then
    echo Module name not specified
    exit 1
fi

if [ -f build.modules ]; then
    if grep "^$MODULE_NAME$" build.modules > /dev/null; then
        echo Module already registered
        exit 2
    fi
fi

if [ -f $MODULE_NAME ]; then
    echo Unable to create module. Filename already exists
    exit 3
fi

echo $MODULE_NAME >> build.modules
mkdir -p $MODULE_NAME
mkdir -p $MODULE_NAME/clean
mkdir -p $MODULE_NAME/src
mkdir -p $MODULE_NAME/test
