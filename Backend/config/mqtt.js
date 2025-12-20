const mqtt = require('mqtt');

const connectMQTT = () => {
    const client = mqtt.connect(process.env.MQTT_BROKER_URL);

    client.on('connect', () => {
        console.log('Connected to MQTT Broker');

        // Subscribe to relevant topics here
        client.subscribe('wastemaster/sorted', (err) => {
            if (!err) {
                console.log("Subscribed to 'wastemaster/sorted'");
            }
        });
    });

    client.on('error', (err) => {
        console.error('MQTT Error:', err);
    });

    return client;
};

module.exports = connectMQTT;
