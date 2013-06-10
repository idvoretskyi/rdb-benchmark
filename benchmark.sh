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
INSERT_CONFIG=$PWD/insert_config
RUN_CONFIG=$PWD/run_config

WORKLOAD_FILE=$YCSB_WORKLOADS/workload$WORKLOAD

WORKLOAD_DIR=data_$WORKLOAD

MONGO_PID=-1
RDB_PID=-1

function run_mongo_bench {
    pushd $WORKLOAD_DIR

    if [[ ! -d mongo_data ]]; then
        mkdir mongo_data

        $MONGOD --dbpath mongo_data &
        MONGO_PID=$!
        sleep 200

        echo "Loading workload data for mongo"
        $YCSB load mongodb -P $WORKLOAD_FILE -P $COMMON_CONFIG -P $INSERT_CONFIG > /dev/null

        kill -SIGINT $MONGO_PID
        sleep 50 # Allow time for writeback queue to flush
    fi

    echo ""
    $MONGOD --dbpath mongo_data &
    MONGO_PID=$!
    sleep 5

    echo "Running workload for mongo"
    $YCSB run mongodb -P $WORKLOAD_FILE -P $COMMON_CONFIG -P $RUN_CONFIG -p threadcount=$CLIENTS > mongodb-$CLIENTS.out

    kill -SIGINT $MONGO_PID

    popd
}

function run_rdb_bench {
    pushd $WORKLOAD_DIR

    if [[ ! -d rdb_data ]]; then
        $RDB create -d rdb_data

        $RDB serve -d rdb_data &
        RDB_PID=$!
        sleep 5

        echo "Loading workload data for rethinkdb"
        $YCSB load rethinkdb -P $WORKLOAD_FILE -P $COMMON_CONFIG -P $INSERT_CONFIG > /dev/null

        kill -SIGINT $RDB_PID
        sleep 50 # Allow time for writeback queue to flush
    fi

    echo ""
    $RDB serve -d rdb_data &
    RDB_PID=$!
    sleep 5

    echo "Running workload for rethinkdb"
    $YCSB run rethinkdb -P $WORKLOAD_FILE -P $COMMON_CONFIG -P $RUN_CONFIG -p threadcount=$CLIENTS > rethinkdb-$CLIENTS.out

    kill -SIGINT $RDB_PID
    sleep 5

    popd
}

if [[ ! -d $WORKLOAD_DIR ]]; then
    mkdir $WORKLOAD_DIR
fi

run_mongo_bench
run_rdb_bench
