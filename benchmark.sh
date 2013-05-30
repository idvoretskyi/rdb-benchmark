#!/bin/bash

## Input parameters

# Which workload to run (a, b, c, d, e, f)
WORKLOAD=${1:-"a"}

# How many client threads to run
CLIENTS=${2:-"10"}

echo "Running worload $WORKLOAD"
echo "Running $CLIENTS client thread(s)"

MONGOD=$PWD/mongod
RDB=$PWD/rethinkdb

YCSB_HOME=$PWD/YCSB
YCSB=$YCSB_HOME/bin/ycsb
YCSB_WORKLOADS=$YCSB_HOME/workloads

COMMON_CONFIG=$PWD/common_config

WORKLOAD_FILE=$YCSB_WORKLOADS/workload$WORKLOAD

WORKLOAD_DIR=data_$WORKLOAD

MONGO_PID=-1
RDB_PID=-1

function start_mongo {
    echo "Starting mongod"

    DO_WAIT=0
    if [[ ! -d mongo_data ]]; then
        mkdir mongo_data
        DO_WAIT=1
    fi

    $MONGOD --dbpath mongo_data &
    MONGO_PID=$!

    if [[ $DO_WAIT -eq 1 ]]; then
        sleep 200
    else
        sleep 5
    fi
}

function stop_mongo {
    kill -SIGINT $MONGO_PID
    sleep 5
}

function start_rdb {
    echo "Starting rethinkdb"

    if [[ ! -d rdb_data ]]; then
        $RDB create -d rdb_data
    fi

    $RDB serve -d rdb_data &
    RDB_PID=$!
    sleep 5
}

function stop_rdb {
    kill -SIGINT $RDB_PID
    sleep 5
}

# Initialize the data if it's not already there
if [[ ! -d $WORKLOAD_DIR ]]; then

    echo "Initializing workload data"

    mkdir $WORKLOAD_DIR
    pushd $WORKLOAD_DIR

    start_mongo

    echo "Loading workload data for mongo"
    $YCSB load mongodb -P $WORKLOAD_FILE -P $COMMON_CONFIG > /dev/null

    stop_mongo

    start_rdb

    echo "Loading workload data for rethinkdb"
    $YCSB load rethinkdb -P $WORKLOAD_FILE -P $COMMON_CONFIG > /dev/null

    stop_rdb

    popd
fi

pushd $WORKLOAD_DIR

start_mongo

# Run the workload
echo "Running workload for mongo"
$YCSB run mongodb -P $WORKLOAD_FILE -P $COMMON_CONFIG -p threadcount=$CLIENTS > mongodb-$CLIENTS.out

stop_mongo

start_rdb

echo "Running workload for rethinkdb"
$YCSB run rethinkdb -P $WORKLOAD_FILE -P $COMMON_CONFIG -p threadcount=$CLIENTS > rethinkdb-$CLIENTS.out

stop_rdb

popd
