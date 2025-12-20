const mongoose = require('mongoose');

const UserSchema = new mongoose.Schema({
    name: {
        type: String,
        required: true
    },
    email: {
        type: String,
        required: true,
        unique: true
    },
    // Simple password for demo purposes. In production, hash this!
    password: {
        type: String,
        required: true
    },
    points: {
        type: Number,
        default: 0
    },
    totalRecycled: {
        type: Number,
        default: 0
    },
    joinedChallenges: [{
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Challenge'
    }],
    completedChallenges: [{
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Challenge'
    }],
    createdAt: {
        type: Date,
        default: Date.now
    }
});

module.exports = mongoose.model('User', UserSchema);
