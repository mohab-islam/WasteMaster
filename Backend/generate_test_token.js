const mongoose = require('mongoose');
const dotenv = require('dotenv');
const { v4: uuidv4 } = require('uuid');
const Token = require('./models/Token');
const connectDB = require('./config/db');

// Load env vars
dotenv.config();

const generateTestToken = async () => {
    await connectDB();

    try {
        const tokenValue = uuidv4();

        const newToken = await Token.create({
            value: tokenValue,
            type: 'plastic',
            pointsValue: 10,
            status: 'active'
        });

        console.log('\n✅ VALID TOKEN CREATED!');
        console.log('-----------------------');
        console.log(`Token Value: ${newToken.value}`);
        console.log('-----------------------');

        // Generate a Google Chart QR code URL
        const qrUrl = `https://api.qrserver.com/v1/create-qr-code/?size=200x200&data=${newToken.value}`;

        console.log('SCAN THIS QR CODE WITH YOUR APP:');
        console.log(qrUrl);
        console.log('\n(Copy and paste the link into your browser to see the image)');

    } catch (err) {
        console.error('Error:', err);
    } finally {
        await mongoose.connection.close();
        process.exit();
    }
};

generateTestToken();
