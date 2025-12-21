import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'profile_screen.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _userName = 'User';
  int _points = 0;
  List<dynamic> _recentHistory = [];
  List<dynamic> _activeChallenges = [];
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
            
            // Logic: Show ALL joined challenges
            List joinedIds = userDetails['joinedChallenges'] ?? [];
            // helper to safe compare
            bool isJoined(String id) => joinedIds.any((j) => j.toString() == id);

            _activeChallenges = challenges.where((c) => isJoined(c['_id'].toString())).toList();
            
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
      drawer: Drawer(
        backgroundColor: AppTheme.background,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: AppTheme.primaryGold),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                   const CircleAvatar(
                    backgroundColor: AppTheme.background,
                    radius: 30,
                    child: Icon(Icons.person, color: AppTheme.primaryGold, size: 35),
                   ),
                   const SizedBox(height: 12),
                   Text(_userName, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                   const Text('Eco-Warrior', style: TextStyle(color: Colors.white70)),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.person, color: AppTheme.textLight),
              title: const Text('Profile', style: TextStyle(color: AppTheme.textLight)),
              onTap: () {
                Navigator.pop(context); // Close drawer
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.redAccent),
              title: const Text('Sign Out', style: TextStyle(color: Colors.redAccent)),
              onTap: () async {
                 Navigator.pop(context);
                 await AuthService.logout();
                 if (mounted) {
                   Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (r) => false);
                 }
              },
            ),
          ],
        ),
      ),
      appBar: AppBar(
        title: const Text('My Dashboard'),
        centerTitle: true,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
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

                  // Active Challenges Section
                  _sectionHeader('Active Challenges'),
                  const SizedBox(height: 12),
                  if (_activeChallenges.isNotEmpty)
                    ..._activeChallenges.map((c) => _buildChallengeCard(c))
                  else
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppTheme.cardColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.primaryGold.withOpacity(0.3), style: BorderStyle.solid)
                      ),
                      child: Column(
                        children: [
                           const Icon(Icons.emoji_events_outlined, size: 40, color: AppTheme.primaryGold),
                           const SizedBox(height: 10),
                           const Text('No active challenges', style: TextStyle(color: AppTheme.textLight, fontWeight: FontWeight.bold)),
                           const SizedBox(height: 4),
                           const Text('Join a challenge to earn badges!', style: TextStyle(color: AppTheme.textDim)),
                        ],
                      ),
                    ),
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
    // We can use a simpler card or an ExpansionTile. 
    // User asked for "drop down". ExpansionTile is perfect.
    // Calculate progress if we had the data. For now, assume 0 or from backend if linked.
    // The previous implementation was a container. Let's make it an expandable card.
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primaryGold.withOpacity(0.3)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.primaryGold.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.emoji_events, size: 24, color: AppTheme.primaryGold),
          ),
          title: Text(
             challenge['title'],
             style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textLight),
          ),
          subtitle: Text(
             'Goal: ${challenge['goal']} items',
             style: const TextStyle(color: AppTheme.textDim, fontSize: 12),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Current Progress', style: TextStyle(color: AppTheme.textDim, fontSize: 12)),
                  const SizedBox(height: 8),
                  // TODO: Bind actual progress from userDetails if available.
                  // For now, static or 0.
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: 0.1, // Demo value
                      backgroundColor: Colors.grey[200],
                      color: AppTheme.primaryGold,
                      minHeight: 8,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Align(
                    alignment: Alignment.centerRight,
                    child: Text('10%', style: TextStyle(color: AppTheme.primaryGold, fontWeight: FontWeight.bold)),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
