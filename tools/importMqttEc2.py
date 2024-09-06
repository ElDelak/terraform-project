import paho.mqtt.client as mqtt
import boto3
import time
from botocore.exceptions import ClientError
import queue_wrapper

session = boto3.Session(profile_name='aws')
dev_s3_client = session.resource('sqs')

# The callback for when the client receives a CONNACK response from the server.
def on_connect(client, userdata, flags, rc):
    print("Connected with result code "+str(rc))

    # Subscribing in on_connect() means that if we lose the connection and
    # reconnect then subscriptions will be renewed.
    client.subscribe("cpgbiProd")

# The callback for when a PUBLISH message is received from the server.
def on_message(client, userdata, msg):
    print(msg.topic+" "+str(msg.payload))
    timestamp = round(time.time())
    data = str(msg.payload).split('|')
    send_messages(queue, str(msg.payload))

def send_messages(queue, messages):
    try:      
        message = {"key": "value"}
        response = queue.send_message(MessageBody = messages)
        if 'Successful' in response:
            for msg_meta in response['Successful']:
                print(
                    "Message sent: %s: %s",
                    msg_meta['MessageId'],
                    messages[int(msg_meta['Id'])]['body']
                )
        if 'Failed' in response:
            for msg_meta in response['Failed']:
                print(
                    "Failed to send: %s: %s",
                    msg_meta['MessageId'],
                    messages[int(msg_meta['Id'])]['body']
                )
    except ClientError as error:
        print("Send messages failed to queue: %s", queue)
        raise error
    else:
        return response

# mqtt 
client = mqtt.Client()
client.username_pw_set("admin", password="admin")
client.on_connect = on_connect
client.on_message = on_message

client.connect("196.203.63.59", 1883, 60)
queue = queue_wrapper.get_queue('BasculeDataQueue')
client.loop_forever()