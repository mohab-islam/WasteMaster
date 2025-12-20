const mongoose = require('mongoose');

const ChallengeSchema = new mongoose.Schema({
    title: {
        type: String,
        required: true
    },
    description: {
        type: String,
        required: true
    },
    type: {
        type: String,
        required: true,
        enum: ['plastic', 'can', 'total_items', 'points']
    },
    goal: {
        type: Number,
        required: true
    },
    rewardPoints: {
        type: Number,
        required: true
    },
    icon: {
        type: String, // could be a url or an icon name string for the app
        default: 'star'
    },
    createdAt: {
        type: Date,
        default: Date.now
    }
});

module.exports = mongoose.model('Challenge', ChallengeSchema);
