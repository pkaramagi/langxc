import 'package:flutter/material.dart';
import '../../core/services/backend_api_service.dart';
import '../../core/constants/app_constants.dart';

class NotificationSummaryScreen extends StatefulWidget {
  final String notificationType; // 'daily', 'two_day', 'weekly'
  final Map<String, dynamic>? notificationData;

  const NotificationSummaryScreen({
    super.key,
    required this.notificationType,
    this.notificationData,
  });

  @override
  State<NotificationSummaryScreen> createState() =>
      _NotificationSummaryScreenState();
}

class _NotificationSummaryScreenState extends State<NotificationSummaryScreen> {
  final BackendApiService _backendService = BackendApiService();
  Map<String, dynamic>? _summaryData;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadSummaryData();
  }

  Future<void> _loadSummaryData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      Map<String, dynamic>? summary;
      switch (widget.notificationType) {
        case 'daily':
          summary = await _backendService.getDailySummary();
          break;
        case 'two_day':
          summary = await _backendService.getTwoDaySummary();
          break;
        case 'weekly':
        default:
          summary = await _backendService.getWeeklySummary();
          break;
      }

      setState(() {
        _summaryData = summary;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  String _getTitle() {
    switch (widget.notificationType) {
      case 'daily':
        return 'Your Daily Summary';
      case 'two_day':
        return 'Your 2-Day Progress';
      case 'weekly':
      default:
        return 'Your Weekly Summary';
    }
  }

  String _getSubtitle() {
    switch (widget.notificationType) {
      case 'daily':
        return 'Here\'s what you accomplished today';
      case 'two_day':
        return 'Your progress over the last 2 days';
      case 'weekly':
      default:
        return 'Your language learning progress this week';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_getTitle()),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSummaryData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Failed to load summary',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadSummaryData,
              child: const Text('Try Again'),
            ),
          ],
        ),
      );
    }

    if (_summaryData == null) {
      return const Center(child: Text('No summary data available'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(_getSubtitle(), style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 24),

          // Summary Cards
          _buildSummaryCards(),

          const SizedBox(height: 32),

          // Most Frequent Words
          if (_summaryData!['most_frequent_words']?.isNotEmpty ?? false) ...[
            Text(
              'Most Frequent Words',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            _buildFrequentWordsList(),
          ],

          // Actions
          const SizedBox(height: 32),
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    final totalTranslations = _summaryData!['total_translations'] ?? 0;
    final uniqueWords = _summaryData!['unique_words'] ?? 0;

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            title: 'Translations',
            value: totalTranslations.toString(),
            icon: Icons.translate,
            color: Colors.blue,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            title: 'Unique Words',
            value: uniqueWords.toString(),
            icon: Icons.library_books,
            color: Colors.green,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFrequentWordsList() {
    final words = _summaryData!['most_frequent_words'] as List<dynamic>;

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: words.length,
      itemBuilder: (context, index) {
        final word = words[index] as Map<String, dynamic>;
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.blue.shade100,
              child: Text(
                (index + 1).toString(),
                style: TextStyle(
                  color: Colors.blue.shade800,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              word['word'] ?? '',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              'Used ${word['count'] ?? 0} times',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            trailing: Text(
              word['translation'] ?? '',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton.icon(
          onPressed: () {
            // Navigate to history screen
            Navigator.of(context).pushNamed(AppConstants.historyRoute);
          },
          icon: const Icon(Icons.history),
          label: const Text('View Full History'),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () {
            // Navigate to vocabulary screen
            Navigator.of(context).pushNamed(AppConstants.vocabularyRoute);
          },
          icon: const Icon(Icons.bookmark),
          label: const Text('Review Vocabulary'),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Close'),
        ),
      ],
    );
  }
}
