import boto3, json, logging, argparse, time, os, shutil, importlib,uuid, requests

def handler(event, context):
    entry = time.time() * 1000
    logger = logging.getLogger()

    if context:
        logger.info('dbMod::handler: context: {}'.format(context))
        if event:
            reg = 'us-west-2'
            if 'region' in event:
                reg = event['region']
            logger.info('dbMod::handler: event: {}'.format(event))
        dynamodb = boto3.resource('dynamodb', region_name=reg)
    else: #calling from main (testing)
        if event:
            reg = 'us-west-2'
            if 'region' in event:
                reg = event['region']
        session = boto3.Session(profile_name='cjk1') #replace with your profile
        dynamodb = session.resource('dynamodb', region_name=reg)

    tablename = None
    keyname = 'name'
    valname = 'age'
    key = str(uuid.uuid4())[:4]
    val = 17
    if event:
        if 'keyname' in event:
            keyname = event['keyname']
        if 'valname' in event:
            valname = event['valname']
        if 'mykey' in event:
            key = event['mykey']
        if 'myval' in event:
            val = event['myval']
        if 'functionName' in event:
            caller = event['functionName']
        if 'tableName' in event:
            tablename = event['tableName']

    table = dynamodb.Table(tablename) # we assume key is name of type String
    #write it
    table.put_item( Item={
        keyname : key,
        valname : val,
        }
    )
    logger.warn('completed table update')

    delta = (time.time() * 1000) - entry
    me_str = 'TIMER:CALL:{}'.format(delta)
    logger.warn(me_str)
    return me_str

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='dbMod Test')
    # for this table, we assume key is name of type String
    parser.add_argument('tablename',action='store',help='dynamodb table name')
    parser.add_argument('mykey',action='store',help='key')
    parser.add_argument('myval',action='store',help='value')
    parser.add_argument('keyname',action='store',help='keyname')
    parser.add_argument('valname',action='store',help='valname')
    parser.add_argument('--region',action='store',default='us-west-2',help='AWS Region')
    args = parser.parse_args()
    event = {'tableName':args.tablename,'mykey':args.mykey,'myval':args.myval,'region':args.region,'keyname':args.keyname,'valname':args.valname}
    handler(event,None)
