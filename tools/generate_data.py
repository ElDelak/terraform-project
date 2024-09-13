import paho.mqtt.client as mqtt
import time
import random

# MQTT settings
broker = 'test.mosquitto.org'  # Replace with your MQTT broker address
port = 1883  # Typically 1883 for non-secure MQTT connections
topic = 'aws/cpg/data'  # Replace with your topic

# Initialize a dictionary to store the previous mt values for each id
previous_mt_values = {i: 0 for i in range(1, 6)}

# Function to generate the values
def generate_values(unique_id):
    global previous_mt_values
    
    v = random.choice([0, 2])
    d = random.uniform(180, 200) if v == 2 else 0  # d is closer to 200 if v = 2, otherwise 0
    mt_increment = random.uniform(8, 10) if d > 100 else random.uniform(0, 2)
    
    # Get the previous mt for the current id and calculate the new mt
    mt = previous_mt_values[unique_id] + mt_increment
    previous_mt_values[unique_id] = mt  # Update the previous mt value for the current id
    
    return {"v": v, "d": d, "mt": mt, "id": unique_id}

# Function to send the message to the broker
def send_message(client, message):
    client.publish(topic, str(message))
    print(f"Sent: {message}")

# Set up MQTT client
client = mqtt.Client()
client.connect(broker, port, 60)

# Main loop to generate and send messages
try:
    while True:
        for unique_id in range(1, 6):  # Generate messages with ids from 1 to 5
            message = generate_values(unique_id)
            send_message(client, message)
        time.sleep(60)  # Wait for 1 minute
except KeyboardInterrupt:
    print("Stopped by user")

client.disconnect()