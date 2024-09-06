from datetime import datetime
import time  
import json
import os
import boto3
from boto3.dynamodb.conditions import Key

dynamodb = boto3.resource('dynamodb')
ssm = boto3.client('ssm')
table_name = os.environ.get('table_name')

def lambda_handler(event, context):
    for message in event['Records']:
        table = dynamodb.Table('basculedata')
        data = message['body'].split('|')
        LastSavedValue = getLastSavedValue(data[4])
        debit = data[0][2:]
        if LastSavedValue:
            first_matching_item = LastSavedValue[0]
            if (int(data[2]) < int(first_matching_item['mt'])) or (int(data[1]) == -1 and  int(debit) == -1):
                data[2] = first_matching_item['mt']
            timestamp_value = int(time.time())
            # Assuming you want to return the first matching item
            print('Found item:', first_matching_item)
            deltaMT = int(data[2]) - int(first_matching_item['mt']) if int(data[2]) - int(first_matching_item['mt']) >=0 else 0
            deltats = timestamp_value - int(first_matching_item['timestamp'])
            # check if new Day
            isNewDay = checkNewDays(data[4], first_matching_item['timestamp'])
            idPoste = str(getCurrentPoste(data[4]))
            item = {}
            table = dynamodb.Table(table_name)
            if isNewDay == True:
                item = {
                'idBascule': data[4],
                'timestamp': timestamp_value,
                'debit': debit,
                'vitesse': data[1],
                'mt': int(data[2]),
                'cumulMT' : deltaMT,
                'mtP1' : 0,'mtP2' : 0,'mtP3' : 0,
                'tf': 0, 'tfP1': 0, 'tfP2': 0, 'tfP3': 0, 
                'ta': 0, 'taP1': 0, 'taP2': 0, 'taP3': 0, 
                'tmav': 0, 'tmavP1': 0, 'tmavP2': 0, 'tmavP3': 0, 
                'tndf': 0, 'tndfP1': 0, 'tndfP2': 0, 'tndfP3': 0, 
                }
                if int(debit != 0):
                    item['tf'] = deltats
                    item['tfP'+idPoste] = deltats
                if int(data[1] == 0):
                    item['ta'] = deltats
                    item['taP'+idPoste] = deltats
                if int(debit) == 0 and int(data[1]) != 0:
                    item['tmav'] = deltats
                    item['tmavP'+idPoste] = deltats
                if int(debit) == -1  and int(data[1]) == -1 :
                    item['tndf'] = deltats
                    item['tndfP'+idPoste] = deltats
            else:    
                item = {
                'idBascule': data[4],
                'timestamp': timestamp_value,
                'debit': debit,
                'vitesse': data[1],
                'mt': int(data[2]),
                'cumulMT' : int(first_matching_item['cumulMT']) + deltaMT,
                'mtP1' : int(first_matching_item['mtP1']),'mtP2' : int(first_matching_item['mtP2']),'mtP3' : int(first_matching_item['mtP3']),
                'tf': int(first_matching_item['tf']), 'tfP1': int(first_matching_item['tfP1']), 'tfP2': int(first_matching_item['tfP2']), 'tfP3': int(first_matching_item['tfP3']), 
                'ta': int(first_matching_item['ta']), 'taP1': int(first_matching_item['taP1']), 'taP2': int(first_matching_item['taP2']), 'taP3': int(first_matching_item['taP3']), 
                'tmav': int(first_matching_item['tmav']), 'tmavP1': int(first_matching_item['tmavP1']), 'tmavP2': int(first_matching_item['tmavP2']), 'tmavP3': int(first_matching_item['tmavP3']), 
                'tndf': int(first_matching_item['tndf']), 'tndfP1': int(first_matching_item['tndfP1']), 'tndfP2': int(first_matching_item['tndfP2']), 'tndfP3': int(first_matching_item['tndfP3']), 
                }
                if int(debit != 0):
                    item['tf'] +=  deltats
                    item['tfP'+idPoste] += deltats
                if int(data[1] == 0):
                    item['ta'] += deltats
                    item['taP'+idPoste] += deltats
                if int(debit) == 0 and int(data[1]) != 0:
                    item['tmav'] += deltats
                    item['tmavP'+idPoste] += deltats
                if int(debit) == -1  and int(data[1]) == -1 :
                    item['tndf'] += deltats
                    item['tndfP'+idPoste] += deltats
            table.put_item(Item=item)
            return {'statusCode': 200, 'body': first_matching_item}
        else:
            # add new line in dynamodb without check LastValue
            table = dynamodb.Table(table_name)
            timestamp_value = int(time.time())
            item = {
            'idBascule': data[4],
            'timestamp': timestamp_value,
            'debit': debit,
            'vitesse': data[1],
            'mt': data[2],
            'cumulMT' : '0',
            'mtP1' : 0,'mtP2' : 0,'mtP3' : 0,
            'tf': 0, 'tfP1': 0, 'tfP2': 0, 'tfP3': 0, 
            'ta': 0, 'taP1': 0, 'taP2': 0, 'taP3': 0, 
            'tmav': 0, 'tmavP1': 0, 'tmavP2': 0, 'tmavP3': 0, 
            'tndf': 0, 'tndfP1': 0, 'tndfP2': 0, 'tndfP3': 0
            }
            table.put_item(Item=item)
            
    print("done")

def getStartHour(idBascule):
    return  os.environ.get(idBascule)

def getLastSavedValue(idBascule):
    table = dynamodb.Table(table_name)
    response = table.query(
        KeyConditionExpression=Key('idBascule').eq(idBascule)  & Key('timestamp').gt(0),
        ScanIndexForward=False, 
        Limit=1 
    )
    items = response.get('Items', [])
    return items
def checkNewDays(idBascule, lastTimestamps):
    currentTimestamps = int(time.time())
    currentDatetime_object = datetime.utcfromtimestamp(currentTimestamps)
    currentHour = currentDatetime_object.hour
    startHour = getStartHour(idBascule)
    lastDatetime_object = datetime.utcfromtimestamp(int(lastTimestamps))
    lastHour = lastDatetime_object.hour
    
    if (int(currentHour) == int(startHour) and int(lastHour) < int(currentHour)) or (int(startHour) < int(currentHour) and int(lastHour) < int(startHour)):
        return True
    return False
def getCurrentPoste(idBascule):
    now = datetime.now()
    currentHour = now.strftime("%H") 
    startHour = getStartHour(idBascule)
    print('startHour : ', startHour)
    print('currentHour : ', currentHour)
    if int(currentHour) < int(startHour) + 8 and int(startHour) <=  int(currentHour):
        return 1
    elif int(currentHour) < int(startHour) + 16 and  int(startHour) + 8 <=  int(currentHour) :
        return 2
    elif int(currentHour) < int(startHour)  or int(startHour) + 16 <=  int(currentHour):
        return 3    