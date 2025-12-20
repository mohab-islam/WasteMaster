const mqtt = require('mqtt');
const axios = require('axios'); // We need to assume axios is installed or use fetch if Node 18+
const { v4: uuidv4 } = require('uuid');

// Config
const API_URL = 'http://localhost:5000/api';
const MQTT_URL = 'mqtt://test.mosquitto.org';

async function runTest() {
    console.log('--- Starting WasteMaster System Verification ---');

    // 1. Setup MQTT Client (Simulating Pi and Listener)
    const client = mqtt.connect(MQTT_URL);

    let simulatedToken = null;

    client.on('connect', () => {
        console.log('[MQTT] Connected');
        client.subscribe('wastemaster/display');

        // Simulating the Pi detecting Trash
        setTimeout(() => {
            console.log('[MQTT] Simulating Trash Detection...');
            client.publish('wastemaster/sorted', 'plastic');
        }, 1000);
    });

    client.on('message', async (topic, message) => {
        if (topic === 'wastemaster/display') {
            simulatedToken = message.toString();
            console.log(`[MQTT] Received Token from Server: ${simulatedToken}`);

            // Now we proceed to Phase 2: Simulating Mobile App
            await testMobileAppFlow(simulatedToken);

            client.end(); // Cleanup
        }
    });
}

async function testMobileAppFlow(token) {
    console.log('\n--- Simulating Mobile App ---');

    try {
        // 1. Register User
        const email = `testuser_${Date.now()}@example.com`;
        console.log(`[API] Registering User: ${email}`);

        let user;
        try {
            const regRes = await fetch(`${API_URL}/auth/register`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({
                    name: "Automated Tester",
                    email: email,
                    password: "password123"
                })
            });
            user = await regRes.json();

            if (!user._id) throw new Error('Registration failed');
            console.log(`[API] User Created. ID: ${user._id}`);
        } catch (e) {
            console.error('[API] Register Error:', e.message);
            return;
        }

        // 2. Claim Points
        console.log(`[API] Claiming Points with Token...`);
        const claimRes = await fetch(`${API_URL}/recycle/claim`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                userId: user._id,
                tokenValue: token
            })
        });

        const claimData = await claimRes.json();

        if (claimData.success) {
            console.log('✅ SUCCESS! Points claimed.');
            console.log(`   New Balance: ${claimData.newTotalPoints}`);
            console.log(`   Trash Type: ${claimData.trashType}`);
        } else {
            console.log('❌ FAILED to claim points:', claimData.message);
        }

    } catch (error) {
        console.error('❌ Error during API test:', error.message);
    }
}

// Check for fetch (Node 18+)
if (!global.fetch) {
    console.error('This script requires Node.js v18+ (for native fetch).');
    process.exit(1);
}

runTest();
