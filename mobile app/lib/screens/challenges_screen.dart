import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class ChallengesScreen extends StatefulWidget {
  const ChallengesScreen({super.key});

  @override
  State<ChallengesScreen> createState() => _ChallengesScreenState();
}

class _ChallengesScreenState extends State<ChallengesScreen> {
  List<dynamic> _challenges = [];
  List<dynamic> _history = [];
  Map<String, dynamic>? _userData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final userId = await AuthService.getUserId();
      if (userId == null) return;

      final results = await Future.wait([
        ApiService.getChallenges(),
        ApiService.getHistory(userId),
        ApiService.getUserDetails(userId),
      ]);

      if (mounted) {
        setState(() {
          _challenges = results[0] as List<dynamic>;
          _history = results[1] as List<dynamic>;
          _userData = results[2] as Map<String, dynamic>;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading challenges: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _joinChallenge(String challengeId) async {
    try {
      final userId = await AuthService.getUserId();
      if (userId == null) return;
      
      await ApiService.joinChallenge(userId, challengeId);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Challenge Joined!'), backgroundColor: AppTheme.secondaryGreen),
        );
        _loadData(); // Refresh to update joined status
      }
    } catch (e) {
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString().replaceAll("Exception:", "")}'), backgroundColor: Colors.red),
        );
      }
    }
  }

  bool _isJoined(String challengeId) {
     if (_userData == null || _userData!['joinedChallenges'] == null) return false;
     final List joined = _userData!['joinedChallenges'];
     return joined.contains(challengeId);
  }

  bool _isCompleted(String challengeId) {
     if (_userData == null || _userData!['completedChallenges'] == null) return false;
     final List completed = _userData!['completedChallenges'];
     return completed.contains(challengeId);
  }

  // Calculate progress based on challenge type and history
  double _calculateProgress(dynamic challenge) {
    if (_isCompleted(challenge['_id'])) return 1.0;
    
    // Only show progress if joined or completed
    // if (!_isJoined(challenge['_id'])) return 0.0; 

    int current = _calculateCurrentValue(challenge);
    int goal = challenge['goal'] ?? 1;
    return (current / goal).clamp(0.0, 1.0);
  }

  int _calculateCurrentValue(dynamic challenge) {
    // If completed, return goal to show full bar
    if (_isCompleted(challenge['_id'])) return challenge['goal'] ?? 0;

    String type = challenge['type'];
    if (type == 'points') return 0; // TODO: Implement points tracking
    if (type == 'total_items') return _history.length;
    return _history.where((log) => log['wasteType'] == type).length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recycling Challenges'), centerTitle: true),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryGold))
          : RefreshIndicator(
              onRefresh: _loadData,
              color: AppTheme.primaryGold,
              child: ListView.separated(
                padding: const EdgeInsets.all(20),
                itemCount: _challenges.length,
                separatorBuilder: (ctx, i) => const SizedBox(height: 20),
                itemBuilder: (context, index) {
                  final challenge = _challenges[index];
                  return _buildChallengeCard(challenge);
                },
              ),
            ),
    );
  }

  Widget _buildChallengeCard(dynamic challenge) {
    bool isJoined = _isJoined(challenge['_id']);
    bool isCompleted = _isCompleted(challenge['_id']);
    
    double progress = _calculateProgress(challenge);
    int current = _calculateCurrentValue(challenge);
    int goal = challenge['goal'];

    // Visual State
    Color statusColor = isCompleted ? AppTheme.secondaryGreen : (isJoined ? AppTheme.primaryGold : AppTheme.textDim);
    String statusText = isCompleted ? "Completed" : (isJoined ? "In Progress" : "Available");

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: isJoined ? Border.all(color: AppTheme.primaryGold.withOpacity(0.5)) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            height: 100,
            decoration: BoxDecoration(
              color: isCompleted ? AppTheme.secondaryGreen.withOpacity(0.2) : AppTheme.primaryGold.withOpacity(0.2), 
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Center(child: Icon(Icons.emoji_events, size: 48, color: statusColor)),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: Text(challenge['title'], style: const TextStyle(color: AppTheme.textLight, fontWeight: FontWeight.bold, fontSize: 18))),
                    if (isJoined || isCompleted)
                       Container(
                         padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                         decoration: BoxDecoration(color: statusColor.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                         child: Text(statusText, style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold)),
                       )
                  ],
                ),
                const SizedBox(height: 4),
                Text(challenge['description'], style: const TextStyle(color: AppTheme.textDim, fontSize: 14)),
                const SizedBox(height: 16),
                
                // Progress Bar (Only show if joined or completed)
                if (isJoined || isCompleted) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: AppTheme.background,
                      color: isCompleted ? AppTheme.secondaryGreen : AppTheme.primaryGold,
                      minHeight: 8,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('$current/$goal items', style: const TextStyle(color: AppTheme.textLight)),
                      Text(
                        isCompleted ? 'Recycled!' : 'Earn ${challenge['rewardPoints']} pts',
                         style: TextStyle(color: isCompleted ? AppTheme.secondaryGreen : AppTheme.primaryGold, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ] else ...[
                   // Not Joined State
                   Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Goal: $goal items', style: const TextStyle(color: AppTheme.textLight)),
                      Text('Reward: ${challenge['rewardPoints']} pts', style: const TextStyle(color: AppTheme.primaryGold, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],

                if (!isJoined && !isCompleted) ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _joinChallenge(challenge['_id']),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.cardColor,
                        side: const BorderSide(color: AppTheme.primaryGold), 
                      ),
                      child: const Text('Join Challenge'),
                    ),
                  )
                ] else if (isJoined && !isCompleted) ...[
                   const SizedBox(height: 16),
                   SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: null, // Disabled
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: AppTheme.primaryGold.withOpacity(0.3)), 
                      ),
                      child: const Text('Joined', style: TextStyle(color: AppTheme.primaryGold)),
                    ),
                  )
                ]
              ],
            ),
          )
        ],
      ),
    );
  }
}
