rdb-benchmark
=============

Scripts for benchmarking RethinkDB.

### Quick setup

After cloning this repo there are few steps you have to
take to get it ready to run YCSB.

1. `$ git submodule init` - initialize YCSB submodule
2. `$ git submodule update` - actually pull the code (why is this a separate step?)
3. `$ cd YCSB/; mvn clean package` - build YCSB

Now YCSB is ready to run. To run all YCSB workload in our default
configuration: `./all_benchmark.sh`. This will create a `data_*` directory for
each workload. WARING: This will take a long time! The first time any workload
is run the data for that workload needs to be initialized. Subsequent runs will
simply run against the existing data files so don't delete the `data_*`
directory unless you want to wait again.

### Benchmark Output

For each workload run, the benchmark script creates a folder called `data_` that
holds data and results. The first time a workload is run (and the data folder
doesn't exist) be warned that it will take a long time for the workload to run
because we need to first insert all of the data into the database. Subsequent
runs will go much faster as long as you don't delete the data directory.

For each run, the script creates output files called mongodb-.out and
rethinkdb-.out. Subsequent runs of the same workload and thread count will
overwrite this output so be sure to copy it elsewhere if you want to save it
between runs.

YCSB produces a lot of output per run but the relevant number are at the top.
Our main concern is the line [OVERALL], `Throughput(opts/sec), ******`. You may
also be interested in per operation type (read, update, etc.) average latency.
You can find these by greping for [READ], AverageLatency(us), etc. Keep in mind
that these throughput numbers aggregate all client threads. It might be
interesting to build a curve of throughput per thread across different numbers
of client threads.

### Configuration

By default the benchmark script runs a single server and 10 client threads in
RethinkDB's default mode (durability=hard, noreply=false). The MongoDB
equivalent of this is `write_concern=fsync_safe`. This is meant to recreate what
we expect to be a pretty typical setup for our users.

Some aspects of this configuration are easy to change, some hard. To change the
number of threads simply supply the desired number to the benchmark script as
the second argument. To change the "write concern" you have to edit the file
"common_config". To test mongo's default configuration rather than rethinkdb's,
change the line mongodb.writeConcern=fsync_safe to normal,
rethinkdb.hard_durability=true to false and rethinkdb.no_reply=false to true.
Setting up more than 1 server is not currently supported by the script. We we
get to the point where we want to do this I'll have to do some legwork to get
that working.
