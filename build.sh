#!/bin/bash

if [ -z $SQL_USER ]; then
    SQL_USER=inari
fi
SQL_CMD="psql --set ON_ERROR_STOP=on"

MODULES_FILE=build.modules
SOURCE_FILE=build.sources
CLEAN_FILE=build.clean
TEST_FILE=build.test

SOURCE_DIR=src
CLEAN_DIR=clean
TEST_DIR=test

TOP_DIR=$TOP_DIR_OUT

while getopts ":u: :b :c :t" opt; do
    case $opt in
        u)
            SQL_USER=$OPTARG
            ;;
        b)
            MODE_BUILD="build"
            ;;
        c)
            MODE_CLEAN="clean"
            ;;
        t)
            MODE_TEST="test"
            ;;
        :)
            echo "Option -$OPTARG requires an argument." >&2
            exit 1
            ;;
     esac
done

function main
{

    if [ -z $TOP_DIR ]; then
        # Only set if we're recursing
        echo "Using username: $SQL_USER"
    fi
    if [ -z $MODE_BUILD ] && [ -z $MODE_CLEAN ] && [ -z $MODE_TEST ]; then
        MODE_BUILD="build"
    fi
    if [ ! -z $MODE_CLEAN ]; then
        clean
    fi
    if [ ! -z $MODE_BUILD ]; then
        build
    fi
    if [ ! -z $MODE_TEST ]; then
        runtests
    fi
    recurse
}

function build
{
    if [ -f ${SOURCE_FILE} ]; then
        SOURCES=`cat ${SOURCE_FILE}`
    else 
        if [ -d ${SOURCE_DIR} ]; then
            SOURCES=`find ${SOURCE_DIR} -type f -name "*.sql"`
        fi
    fi

    for src in ${SOURCES}; do
        if [ $src -nt $src.out ]; then
            echo "Building $src"
            execute $src | tee $src.out
            case ${PIPESTATUS[0]} in
                0)
                    ;;
                *)
                    exit 2
                    ;;
            esac
        fi
    done
}

function clean
{
    if [ -f ${CLEAN_FILE} ]; then
        CLEANS=`cat ${CLEAN_FILE}`
    else 
        if [ -d ${CLEAN_DIR} ]; then
            CLEANS=`find ${CLEAN_DIR} -type f -name "*.sql"`
        fi
    fi

    for src in ${CLEANS}; do
        echo "Running $src"
        execute $src
    done
    if [ -f ${SOURCE_FILE} ]; then
        SOURCES=`cat ${SOURCE_FILE}`
    else 
        if [ -d ${SOURCE_DIR} ]; then
            SOURCES=`find ${SOURCE_DIR} -type f -name "*.sql"`
        fi
    fi
    for src in ${SOURCES}; do
        rm -f ${src}.out
    done
}

function runtests
{
    if [ -f ${TEST_FILE} ]; then
        TESTS=`cat ${TEST_FILE}`
    else 
        if [ -d ${TEST_DIR} ]; then
            TESTS=`find ${TEST_DIR} -type f -name "*.sql"`
        fi
    fi

    for src in ${TESTS}; do
        echo "Running $src"
        execute $src || exit 2
    done
}

function recurse
{
    if [ -f ${MODULES_FILE} ]; then
        case $MODE in
            clean)
                MODULES=`tac ${MODULES_FILE}`
                ;;
            *)
                MODULES=`cat ${MODULES_FILE}`
                ;;
        esac
    fi

    for module in ${MODULES}; do
        echo "Building module: $module"
        pushd $module 2>&1 > /dev/null
        export TOP_DIR_OUT=../$TOP_DIR
        export SQL_USER
        export MODE_BUILD
        export MODE_CLEAN
        export MODE_TEST

        $TOP_DIR_OUT/build.sh || exit $?
        popd 2>&1 > /dev/null
    done
}

function execute
{
    cmd=${SQL_CMD}
    if [ ! -z ${SQL_USER} ]; then
        cmd="$cmd -U ${SQL_USER}"
    fi
    $cmd -f $1
    return $?
}
main
