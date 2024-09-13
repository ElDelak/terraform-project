import paho.mqtt.client as mqtt
import time
import json

# The callback for when the client receives a CONNACK response from the server.
def on_connect(client, userdata, flags, rc):
    print("Connected with result code "+str(rc))

    # Subscribing in on_connect() means that if we lose the connection and
    # reconnect then subscriptions will be renewed.
    client.subscribe("aws/cpg/data")

# The callback for when a PUBLISH message is received from the server.
def on_message(client, userdata, msg):
    m_decode=str(msg.payload.decode("utf-8","ignore"))
    print("data Received type",type(m_decode))
    print("data Received",m_decode)
    print("Converting from Json to Object")
    m_in=json.loads(m_decode.replace("\'", "\"")) #decode json data
    print(type(m_in))
    print("broker 2 address = ",m_in["d"])

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
#client.username_pw_set("admin", password="admin")
client.on_connect = on_connect
client.on_message = on_message

client.connect("test.mosquitto.org", 1883, 60)
client.loop_forever()