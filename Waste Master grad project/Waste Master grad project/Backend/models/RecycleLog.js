const mongoose = require('mongoose');

const RecycleLogSchema = new mongoose.Schema({
    userId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        required: true
    },
    wasteType: {
        type: String,
        required: true
    },
    pointsEarned: {
        type: Number,
        required: true
    },
    scannedAt: {
        type: Date,
        default: Date.now
    }
});

module.exports = mongoose.model('RecycleLog', RecycleLogSchema);
