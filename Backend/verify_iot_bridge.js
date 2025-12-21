const axios = require('axios');
const fs = require('fs');
const path = require('path');

const LOG_FILE = path.join(__dirname, 'verify_log.txt');
// Clear log file on start
fs.writeFileSync(LOG_FILE, '');

// Check for --prod flag
const isProd = process.argv.includes('--prod');
const BASE_URL = isProd
    ? 'https://wastemaster.onrender.com'
    : 'http://localhost:5000';

if (isProd) {
    console.log("🌍 RUNNING IN PRODUCTION MODE");
    console.log(`Target: ${BASE_URL}`);
}

// Colors for console output
const colors = {
    reset: "\x1b[0m",
    green: "\x1b[32m",
    red: "\x1b[31m",
    blue: "\x1b[34m",
    yellow: "\x1b[33m"
};

const log = (msg, color = colors.reset) => {
    console.log(`${color}${msg}${colors.reset}`);
    // Strip ANSI codes for file
    const cleanMsg = msg.replace(/\x1b\[[0-9;]*m/g, '') + '\n';
    fs.appendFileSync(LOG_FILE, cleanMsg);
};

async function runVerification() {
    log('\n🚀 Starting IoT Bridge Verification...', colors.blue);

    let tokenValue = null;
    let userId = null;

    // 1. Generate Token (IoT Simulation)
    try {
        log('\n1. Testing POST /api/token/generate...', colors.yellow);
        const res = await axios.post(`${BASE_URL}/api/token/generate`, {
            wasteType: 'plastic'
        });

        if (res.data.success && res.data.token) {
            tokenValue = res.data.token;
            log(`✅ Token Generated: ${tokenValue}`, colors.green);
            log(`   Points: ${res.data.points}`);
        } else {
            throw new Error('Token generation failed');
        }
    } catch (err) {
        log(`❌ Error in Step 1: ${err.message}`, colors.red);
        console.error(err); // Print full error to console
        if (err.response) {
            log(`Status: ${err.response.status}`);
            log(`Data: ${JSON.stringify(err.response.data, null, 2)}`);
        } else if (err.request) {
            log('No response received (Server might be down)');
        }
        return;
    }

    // 2. Register/Login Test User (Mobile App Simulation)
    try {
        log('\n2. Creating/Logging in Test User...', colors.yellow);
        const uniqueEmail = `testuser_${Date.now()}@example.com`;
        const res = await axios.post(`${BASE_URL}/api/auth/register`, {
            name: 'IoT Tester',
            email: uniqueEmail,
            password: 'password123'
        });

        if (res.data._id) {
            userId = res.data._id;
            log(`✅ User Authenticated: ${res.data.name} (${userId})`, colors.green);
            log(`   Initial Points: ${res.data.points || 0}`);
        } else {
            throw new Error('User registration failed');
        }
    } catch (err) {
        log(`❌ Error in Step 2: ${err.message}`, colors.red);
        if (err.response) log(JSON.stringify(err.response.data, null, 2));
        return;
    }

    // 3. Claim Token (Mobile App Simulation)
    try {
        log(`\n3. Claiming Token ${tokenValue} for User ${userId}...`, colors.yellow);
        const res = await axios.post(`${BASE_URL}/api/recycle/claim`, {
            userId: userId,
            tokenValue: tokenValue
        });

        if (res.data.success) {
            log(`✅ Token Claimed Successfully!`, colors.green);
            log(`   Message: ${res.data.message}`);
            log(`   New Balance: ${res.data.newTotalPoints}`);
        } else {
            throw new Error('Claim failed');
        }
    } catch (err) {
        log(`❌ Error in Step 3: ${err.message}`, colors.red);
        if (err.response) log(JSON.stringify(err.response.data, null, 2));
        return;
    }

    // 4. Verify Double Claim Prevention
    try {
        log(`\n4. Verifying Double Spend Protection...`, colors.yellow);
        await axios.post(`${BASE_URL}/api/recycle/claim`, {
            userId: userId,
            tokenValue: tokenValue
        });
        log(`❌ Test Failed: Should have rejected double claim`, colors.red);
    } catch (err) {
        if (err.response && err.response.status === 400) {
            log(`✅ Double Claim Prevented (Got 400 as expected)`, colors.green);
        } else {
            log(`❌ Unexpected Error: ${err.message}`, colors.red);
        }
    }

    log('\n🎉 Verification Complete!', colors.blue);
}

runVerification();
