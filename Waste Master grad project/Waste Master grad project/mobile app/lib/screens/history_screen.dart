import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'package:intl/intl.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<dynamic> _history = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    try {
      final userId = await AuthService.getUserId();
      if (userId != null) {
        final data = await ApiService.getHistory(userId);
        if (mounted) {
          setState(() {
            _history = data;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading history: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recycling History'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryGold))
          : _history.isEmpty 
              ? Center(child: Text('No history yet. Start recycling!', style: Theme.of(context).textTheme.bodyMedium))
              : ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: _history.length,
                  separatorBuilder: (ctx, i) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final item = _history[index];
                    return _buildHistoryItem(item);
                  },
                ),
    );
  }

  Widget _buildHistoryItem(dynamic item) {
    final date = DateTime.parse(item['scannedAt']);
    final formattedDate = DateFormat('MMM d, y h:mm a').format(date);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
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
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textLight, fontSize: 16)
                ),
                Text(
                  formattedDate, 
                  style: const TextStyle(color: AppTheme.textDim, fontSize: 13)
                ),
              ],
            ),
          ),
          Text(
             '+${item['pointsEarned']}',
             style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryGold, fontSize: 18),
          )
        ],
      ),
    );
  }
}
