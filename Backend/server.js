const express = require('express');
const dotenv = require('dotenv');
const cors = require('cors');
const { v4: uuidv4 } = require('uuid');
const connectDB = require('./config/db');
const connectMQTT = require('./config/mqtt');
const User = require('./models/User');
const Token = require('./models/Token');

// Load env vars
dotenv.config();

// Connect to Database
connectDB();

// Connect to MQTT
const mqttClient = connectMQTT();

const app = express();

// Middleware
app.use(express.json());
app.use(cors());

// --- MQTT Logic ---
mqttClient.on('message', async (topic, message) => {
    if (topic === 'wastemaster/sorted') {
        const trashType = message.toString(); // e.g., "plastic", "can"
        console.log(`Trash sorted detected: ${trashType}`);

        try {
            // 1. Generate unique token
            const tokenValue = uuidv4();

            // 2. Save to DB
            const newToken = await Token.create({
                value: tokenValue,
                type: trashType, // you might want to validate this against "plastic", "can" etc.
                pointsValue: 10 // Logic to vary points based on type could go here
            });

            console.log(`Token created in DB: ${newToken.value}`);

            // 3. Send to Display (Pi)
            // The Pi will generate a QR code from this string
            mqttClient.publish('wastemaster/display', newToken.value);
            console.log(`Token sent to Display: ${newToken.value}`);

        } catch (err) {
            console.error('Error generating token:', err);
        }
    }
});

// --- API Routes ---

// Health Check
app.get('/', (req, res) => {
    res.send('WasteMaster API is running...');
});

// 1. Register User (Simple)
// 1. Register User
app.post('/api/auth/register', async (req, res) => {
    try {
        const { name, email, password } = req.body;

        const userExists = await User.findOne({ email });
        if (userExists) {
            return res.status(400).json({ message: 'User already exists' });
        }

        const user = await User.create({
            name,
            email,
            password
        });

        res.status(201).json({
            _id: user._id,
            name: user.name,
            email: user.email,
            points: user.points
        });
    } catch (error) {
        res.status(500).json({ message: 'Server Error' });
    }
});

// 1.5 Login User
app.post('/api/auth/login', async (req, res) => {
    try {
        const { email, password } = req.body;

        const user = await User.findOne({ email });

        // Simple password check (In production use bcrypt)
        if (user && user.password === password) {
            res.json({
                _id: user._id,
                name: user.name,
                email: user.email,
                points: user.points
            });
        } else {
            res.status(401).json({ message: 'Invalid email or password' });
        }
    } catch (error) {
        res.status(500).json({ message: 'Server Error' });
    }
});

// 2. Get User Details
app.get('/api/user/:id', async (req, res) => {
    try {
        const user = await User.findById(req.params.id);
        if (!user) {
            return res.status(404).json({ message: 'User not found' });
        }
        res.json({
            _id: user._id,
            name: user.name,
            email: user.email,
            points: user.points,
            totalRecycled: user.totalRecycled,
            joinedChallenges: user.joinedChallenges,
            completedChallenges: user.completedChallenges
        });
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Server Error' });
    }
});

const Challenge = require('./models/Challenge');
const RecycleLog = require('./models/RecycleLog');

// ... (existing imports)

// ... (existing code)

// 2. Claim Points (Scanned QR)
app.post('/api/recycle/claim', async (req, res) => {
    try {
        const { userId, tokenValue } = req.body;

        if (!userId || !tokenValue) {
            return res.status(400).json({ message: 'Missing userId or tokenValue' });
        }

        const token = await Token.findOne({ value: tokenValue });

        if (!token) {
            return res.status(404).json({ message: 'Invalid Token' });
        }

        if (token.status !== 'active') {
            return res.status(400).json({ message: 'Token already claimed or expired' });
        }

        const user = await User.findById(userId);
        if (!user) {
            return res.status(404).json({ message: 'User not found' });
        }

        // Update Token status
        token.status = 'claimed';
        token.claimedBy = user._id;
        await token.save();

        // Add Points to User
        user.points += token.pointsValue;
        user.totalRecycled += 1;
        await user.save();

        // --- NEW: Create Permanent History Log ---
        await RecycleLog.create({
            userId: user._id,
            wasteType: token.type,
            pointsEarned: token.pointsValue
        });

        // --- Challenge Completion Logic ---
        let challengeMessage = '';
        if (user.joinedChallenges && user.joinedChallenges.length > 0) {
            // Fetch full challenge objects
            const challenges = await Challenge.find({ _id: { $in: user.joinedChallenges } });

            for (const challenge of challenges) {
                let currentProgress = 0;

                // Calculate progress based on type
                if (challenge.type === 'total_items') {
                    currentProgress = user.totalRecycled;
                } else {
                    // Get count of specific waste type from logs
                    currentProgress = await RecycleLog.countDocuments({
                        userId: user._id,
                        wasteType: challenge.type
                    });
                }

                if (currentProgress >= challenge.goal) {
                    // Challenge Completed!
                    user.points += challenge.rewardPoints;
                    user.completedChallenges.push(challenge._id);
                    user.joinedChallenges = user.joinedChallenges.filter(id => !id.equals(challenge._id));

                    challengeMessage += ` | Completed ${challenge.title} (+${challenge.rewardPoints} pts!)`;
                    console.log(`User ${user.name} completed challenge: ${challenge.title}`);
                }
            }
            await user.save();
        }

        console.log(`User ${user.name} claimed ${token.pointsValue} points for ${token.type}`);

        res.json({
            success: true,
            message: `Successfully claimed ${token.pointsValue} points!${challengeMessage}`,
            newTotalPoints: user.points,
            trashType: token.type
        });

    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Server Error' });
    }
});

// --- V2 Features ---

// 3. Leaderboard (Top 10)
app.get('/api/leaderboard', async (req, res) => {
    try {
        // Sort by points descending, limit 10
        const leaderboard = await User.find()
            .select('name points totalRecycled') // only return needed fields
            .sort({ points: -1 })
            .limit(10);
        res.json(leaderboard);
    } catch (error) {
        res.status(500).json({ message: 'Server Error' });
    }
});

// 4. User History
app.get('/api/history/:userId', async (req, res) => {
    try {
        const history = await RecycleLog.find({ userId: req.params.userId })
            .sort({ scannedAt: -1 }) // newest first
            .limit(50); // limit to last 50
        res.json(history);
    } catch (error) {
        res.status(500).json({ message: 'Server Error' });
    }
});

// 5. Challenges
app.get('/api/challenges', async (req, res) => {
    try {
        const challenges = await Challenge.find();
        res.json(challenges);
    } catch (error) {
        res.status(500).json({ message: 'Server Error' });
    }
});

// 6. Join Challenge
app.post('/api/challenges/join', async (req, res) => {
    try {
        const { userId, challengeId } = req.body;

        const user = await User.findById(userId);
        if (!user) return res.status(404).json({ message: 'User not found' });

        // Check if already joined
        if (user.joinedChallenges.includes(challengeId)) {
            return res.status(400).json({ message: 'Already joined this challenge' });
        }

        user.joinedChallenges.push(challengeId);
        await user.save();

        res.json({ message: 'Challenge Joined Successfully!', joinedChallenges: user.joinedChallenges });
    } catch (error) {
        res.status(500).json({ message: 'Server Error' });
    }
});

const PORT = process.env.PORT || 5000;

app.listen(PORT, '0.0.0.0', () => {
    console.log(`Server running on port ${PORT}`);
});
