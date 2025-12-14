import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  List<dynamic> _leaderboard = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLeaderboard();
  }

  Future<void> _loadLeaderboard() async {
    try {
      final data = await ApiService.getLeaderboard();
      if (mounted) {
        setState(() {
          _leaderboard = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading leaderboard: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  int _currentTab = 0; // 0: Overall, 1: Weekly, 2: Friends

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Leaderboard'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryGold))
          : Column(
              children: [
                // Custom Tab Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround, // Better spacing
                    children: [
                      _buildTab('Overall', 0),
                      _buildTab('Weekly', 1),
                      _buildTab('Friends', 2),
                    ],
                  ),
                ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _loadLeaderboard,
                    color: AppTheme.primaryGold,
                    child: ListView.separated(
                      padding: const EdgeInsets.all(20),
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: _leaderboard.length,
                      separatorBuilder: (ctx, i) => const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        final user = _leaderboard[index];
                        return _buildLeaderboardItem(user, index + 1);
                      },
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildTab(String text, int index) {
    bool isSelected = _currentTab == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentTab = index;
          // TODO: Fetch filtered data based on tab.
          // For now, we keep the list same or shuffle demo
          if (index == 1) {
             // Mock Weekly: Reverse sort or shuffle for demo visual change
             // _leaderboard.shuffle(); // Valid for demo
          } else if (index == 0) {
             // _loadLeaderboard(); // Reset
          }
        });
      },
      child: Column(
        children: [
          Text(
            text,
            style: TextStyle(
              color: isSelected ? AppTheme.textLight : AppTheme.textDim,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          if (isSelected)
            Container(
              margin: const EdgeInsets.only(top: 4),
              height: 2,
              width: 40,
              color: AppTheme.textLight,
            )
        ],
      ),
    );
  }

  Widget _buildLeaderboardItem(dynamic user, int rank) {
    return Row(
      children: [
        // Rank & Avatar
        SizedBox(
          width: 60, 
          child: CircleAvatar(
            radius: 24,
            backgroundColor: AppTheme.primaryGold.withOpacity(0.2),
             // Show first letter as Avatar if no image
            child: Text(
               user['name'].toString().substring(0, 1).toUpperCase(),
               style: const TextStyle(color: AppTheme.primaryGold, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Name & Points
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$rank. ${user['name']}',
                style: const TextStyle(
                  color: AppTheme.textLight,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Text(
                'Eco-Points: ${user['points']}',
                style: const TextStyle(
                  color: AppTheme.textDim,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        // Points Badge
        Text(
          '${user['points']}',
          style: const TextStyle(
            color: AppTheme.textLight,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ],
    );
  }
}
