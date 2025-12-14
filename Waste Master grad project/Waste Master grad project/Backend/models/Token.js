const mongoose = require('mongoose');

const TokenSchema = new mongoose.Schema({
    value: {
        type: String,
        required: true,
        unique: true
    },
    type: {
        type: String, // 'plastic', 'can', 'paper'
        required: true
    },
    pointsValue: {
        type: Number,
        default: 10
    },
    status: {
        type: String,
        enum: ['active', 'claimed', 'expired'],
        default: 'active'
    },
    claimedBy: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        default: null
    },
    createdAt: {
        type: Date,
        default: Date.now,
        expires: 600 // TTL: Document automatically deleted after 10 minutes (600 seconds) if not claimed/handled
    }
});

module.exports = mongoose.model('Token', TokenSchema);
