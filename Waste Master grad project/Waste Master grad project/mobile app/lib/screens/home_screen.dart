import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _userName = 'User';
  int _points = 0;
  List<dynamic> _recentHistory = [];
  dynamic _activeChallenge;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    try {
      final name = await AuthService.getUserName();
      final userId = await AuthService.getUserId();

      if (name != null) setState(() => _userName = name);

      if (userId != null) {
        // Parallel requests for speed
        final results = await Future.wait([
          ApiService.getUserDetails(userId),
          ApiService.getHistory(userId),
          ApiService.getChallenges()
        ]);

        final userDetails = results[0] as Map<String, dynamic>;
        final history = results[1] as List<dynamic>;
        final challenges = results[2] as List<dynamic>;

        if (mounted) {
          setState(() {
            _points = userDetails['points'] ?? 0;
            // Take top 2 history items
            _recentHistory = history.take(2).toList();
            
            // Logic: Show first JOINED challenge. If none, show first available.
            // But UI design assumes "Active", so let's try to find a joined one.
            List joinedIds = userDetails['joinedChallenges'] ?? [];
            var active = challenges.firstWhere(
                (c) => joinedIds.contains(c['_id']), 
                orElse: () => null
            );
            
            // If no active challenge found, maybe don't show any, or show "Start a Challenge!"?
            // User requested removing Join button "as it is already active".
            // So if we show one here, it implies it IS active.
            // If user hasn't joined any, we shouldn't show "Active Challenge" section or show a "Join One" prompt.
            // For now, if no joined challenge, we hide the section or pick one? 
            // Let's pick one but make sure the UI handles it. 
            // Actually, simplest is: Only show if joined.
            _activeChallenge = active;
            
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading dashboard: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Dashboard'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () {}, // Drawer placeholder
        ),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryGold))
        : RefreshIndicator(
            onRefresh: _loadDashboardData,
            color: AppTheme.primaryGold,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                   // Avatar & Name
                  const CircleAvatar(
                    radius: 50,
                    // Placeholder image or icon
                    backgroundColor: AppTheme.cardColor,
                    child: Icon(Icons.person, size: 50, color: AppTheme.primaryGold), 
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _userName,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  Text(
                    'Eco-Warrior',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 24),

                  // Points Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppTheme.cardColor,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Eco-Points', style: Theme.of(context).textTheme.bodyMedium),
                        const SizedBox(height: 8),
                        Text(
                          '$_points',
                          style: GoogleFonts.outfit(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textLight,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Recent Activity Section
                  _sectionHeader('Recent Activity'),
                  const SizedBox(height: 12),
                  if (_recentHistory.isEmpty)
                     Text('No recent activity', style: Theme.of(context).textTheme.bodyMedium),
                  ..._recentHistory.map((item) => _buildActivityItem(item)),

                  const SizedBox(height: 24),

                  // Community Goals
                  _sectionHeader('Community Goals'),
                  const SizedBox(height: 12),
                  Text('Neighborhood Recycling Goal', style: Theme.of(context).textTheme.bodyLarge),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: 0.75,
                    backgroundColor: AppTheme.cardColor,
                    color: AppTheme.primaryGold,
                    minHeight: 10,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  const SizedBox(height: 4),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text('75% Complete', style: Theme.of(context).textTheme.bodyMedium),
                  ),

                  const SizedBox(height: 24),
                  
                  // Active Challenge
                  _sectionHeader('Active Challenges'),
                  const SizedBox(height: 12),
                  if (_activeChallenge != null)
                    _buildChallengeCard(_activeChallenge!)
                ],
              ),
            ),
          ),
    );
  }

  Widget _sectionHeader(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 18)),
    );
  }

  Widget _buildActivityItem(dynamic item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.background,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.recycling, color: AppTheme.secondaryGreen),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['wasteType'].toString().toUpperCase(), 
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textLight)
                ),
                Text(
                  '+${item['pointsEarned']} pts', 
                  style: const TextStyle(color: AppTheme.primaryGold)
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChallengeCard(dynamic challenge) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primaryGold.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Active Challenge', style: TextStyle(color: AppTheme.secondaryGreen, fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(
                  challenge['title'],
                  style: const TextStyle(
                      color: AppTheme.textLight, fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  'Goal: ${challenge['goal']} items',
                   style: const TextStyle(color: AppTheme.textDim, fontSize: 12),
                ),
                const SizedBox(height: 8),
                // Tiny progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: 0.0, // TODO: Calculate actual progress if possible, or leave 0 for now as "Start"
                    backgroundColor: AppTheme.background,
                    color: AppTheme.primaryGold,
                    minHeight: 4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Icon
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppTheme.primaryGold.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.emoji_events, size: 30, color: AppTheme.primaryGold),
          )
        ],
      ),
    );
  }
}
