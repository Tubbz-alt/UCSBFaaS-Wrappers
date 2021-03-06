#! /bin/bash
#test -- running with tracing on and fleece
if [ -z ${1+x} ]; then echo 'USAGE: ./overhead.sh aws_profile num_runs data_bucket_name prefix'; exit 1; fi
if [ -z ${2+x} ]; then echo 'USAGE: ./overhead.sh aws_profile num_runs data_bucket_name prefix'; exit 1; fi
if [ -z ${3+x} ]; then echo 'USAGE: ./overhead.sh aws_profile num_runs data_bucket_name prefix'; exit 1; fi
if [ -z ${4+x} ]; then echo 'Unset prefix as arg4 (full path to/including UCSBFaaS-Wrappers). Set and rerun. Exiting...!'; exit 1; fi
#DATABKT=big-data-benchmark
PROF=$1
COUNT=$2
DATABKT=$3
PREFIX=$4
MRBKT=spot-mr-bkt-f #must match reducerCoordinator "permission" in config in setupApps.py
JOBID=job8000  #must match reducerCoordinator "job_id" in config in setupApps.py 
DATABKTPREFIX="pavlo/text/1node/uservisits/"

#update the below (must match lambda function names in configWestF.json
MAP="/aws/lambda/mapperF"
MAP_NAME=mapperF
RED_NAME=reducerF
RED="/aws/lambda/reducerF"
DRI="/aws/lambda/driverF"
RC="/aws/lambda/reducerCoordinatorF"

GRDIR=${PREFIX}/gammaRay
DYNDBDIR=${PREFIX}/tools/dynamodb
CWDIR=${PREFIX}/tools/cloudwatch
TOOLSDIR=${PREFIX}/tools/timings
MRDIR=${GRDIR}/apps/map-reduce
TS=1401861965497 #some early date

#setup environment
cd ${GRDIR}
. ./venv/bin/activate

#delete the logs
cd ${CWDIR}
python downloadLogs.py ${MAP} ${TS} -p ${PROF} --deleteOnly
python downloadLogs.py ${RED} ${TS} -p ${PROF} --deleteOnly
python downloadLogs.py ${DRI} ${TS} -p ${PROF} --deleteOnly
python downloadLogs.py ${RC} ${TS} -p ${PROF} --deleteOnly

#do the same for no spotwrap
for i in `seq 1 ${COUNT}`;
do
    #delete the bucket contents for the job
    aws s3 rm s3://${MRBKT}/${JOBID} --recursive --profile ${PROF}

    cd ${MRDIR}
    rm -f overhead.out
    #run the driver
    /usr/bin/time python driver.py ${MRBKT} ${JOBID} ${MAP_NAME} ${RED_NAME} --wait4reducers --databkt ${DATABKT} > overhead.out
    mkdir -p ${i}/F
    rm -f ${i}/F/overhead.out
    mv overhead.out ${i}/F/

    #download cloudwatch logs (and delete them)
    cd ${CWDIR}
    mkdir -p ${i}/F
    rm -f ${i}/F/*.log
    python downloadLogs.py ${MAP} ${TS} -p ${PROF} --delete  > ${i}/F/map.log
    python downloadLogs.py ${RED} ${TS} -p ${PROF} --delete  > ${i}/F/red.log
    python downloadLogs.py ${DRI} ${TS} -p ${PROF} --delete  > ${i}/F/driv.log
    python downloadLogs.py ${RC} ${TS} -p ${PROF} --delete  > ${i}/F/coord.log
    
done
deactivate
