const mongoose = require('mongoose');
const dotenv = require('dotenv');
const Challenge = require('./models/Challenge');
const connectDB = require('./config/db');

dotenv.config();

const challenges = [
    {
        title: "Eco Starter",
        description: "Recycle your first item",
        type: "total_items",
        goal: 1,
        rewardPoints: 50,
        icon: "leaf"
    },
    {
        title: "Plastic Pro",
        description: "Recycle 5 plastic items",
        type: "plastic",
        goal: 5,
        rewardPoints: 100,
        icon: "water_drop"
    },
    {
        title: "Aluminum Ace",
        description: "Recycle 3 cans",
        type: "can",
        goal: 3,
        rewardPoints: 75,
        icon: "local_drink"
    },
    {
        title: "Century Club",
        description: "Earn 100 total points",
        type: "points",
        goal: 100,
        rewardPoints: 200,
        icon: "emoji_events"
    }
];

const seedChallenges = async () => {
    await connectDB();

    try {
        await Challenge.deleteMany(); // Clear existing
        await Challenge.insertMany(challenges);
        console.log('✅ Challenges Seeded Successfully!');
    } catch (error) {
        console.error('Error seeding challenges:', error);
    } finally {
        mongoose.connection.close();
        process.exit();
    }
};

seedChallenges();
