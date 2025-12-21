import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import 'login_screen.dart';
import 'history_screen.dart';
import '../theme/app_theme.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _name = 'User';
  String _email = 'loading...';
  int _points = 0;
  int _totalRecycled = 0;
  List<dynamic> _badges = [];

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final userId = await AuthService.getUserId();
    if (userId != null) {
      try {
        final userData = await ApiService.getUserDetails(userId);
        if (mounted) {
          setState(() {
            _name = userData['name'];
            _email = userData['email'];
            _points = userData['points'];
            _totalRecycled = userData['totalRecycled'] ?? 0;
            _badges = userData['completedChallenges'] ?? [];
          });
        }
      } catch (e) {
        debugPrint('Error loading profile: $e');
      }
    }
  }

  Future<void> _logout() async {
    await AuthService.logout();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: _loadProfile,
        color: AppTheme.primaryGold,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Avatar Section
              const CircleAvatar(
                radius: 60,
                backgroundColor: AppTheme.cardColor,
                child: Icon(Icons.person, size: 60, color: AppTheme.primaryGold),
              ),
              const SizedBox(height: 16),
              Text(
                _name,
                style: const TextStyle(
                  color: AppTheme.textLight,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                _email,
                style: const TextStyle(color: AppTheme.textDim, fontSize: 16),
              ),
              const SizedBox(height: 32),
  
              // Stats Row
              Row(
                children: [
                  _buildStatCard('Eco-Points', '$_points', Icons.bolt),
                  const SizedBox(width: 16),
                  _buildStatCard('Recycled', '$_totalRecycled', Icons.recycling),
                ],
              ),
  
              const SizedBox(height: 32),
  
              // Settings List
              _buildSettingsItem(Icons.history, 'Recycling History', () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const HistoryScreen()));
              }),
              _buildSettingsItem(Icons.badge, 'Badges', () {
                 _showBadges(context);
              }),
              _buildSettingsItem(Icons.settings, 'Account Settings', () {
                 ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Settings Coming Soon!'), duration: Duration(seconds: 1)));
              }),
              _buildSettingsItem(Icons.help_outline, 'Help & FAQ', () {
                 ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('FAQ Coming Soon!'), duration: Duration(seconds: 1)));
              }),
              
              const SizedBox(height: 20),
              
              // Logout
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _logout,
                  icon: const Icon(Icons.logout, color: Colors.redAccent),
                  label: const Text('Log Out', style: TextStyle(color: Colors.redAccent)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.redAccent),
                    padding: const EdgeInsets.all(16),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppTheme.primaryGold, size: 32),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(
                color: AppTheme.textLight,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: const TextStyle(color: AppTheme.textDim),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsItem(IconData icon, String title, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon, color: AppTheme.textLight),
        title: Text(title, style: const TextStyle(color: AppTheme.textLight)),
        trailing: const Icon(Icons.chevron_right, color: AppTheme.textDim),
        onTap: onTap,
      ),
    );
  }

  void _showBadges(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.background,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('My Badges', style: Theme.of(context).textTheme.titleLarge),
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close))
                ],
              ),
              const SizedBox(height: 16),
              if (_badges.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: Text('No badges yet. Complete challenges to earn them!', style: TextStyle(color: AppTheme.textDim)),
                  ),
                )
              else
                Expanded(
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3, childAspectRatio: 0.8),
                    itemCount: _badges.length,
                    itemBuilder: (ctx, i) {
                      final badge = _badges[i];
                      return Column(children: [
                        Container(
                           padding: const EdgeInsets.all(12),
                           decoration: BoxDecoration(
                               color: AppTheme.primaryGold.withOpacity(0.1),
                               shape: BoxShape.circle
                           ),
                           child: const Icon(Icons.verified, color: AppTheme.primaryGold, size: 40)
                        ),
                        const SizedBox(height: 8),
                        Text(
                            badge['title'] ?? 'Badge', 
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: AppTheme.textLight, fontWeight: FontWeight.bold)
                        )
                      ]);
                    },
                  ),
                )
            ],
          ),
        );
      },
    );
  }
}
