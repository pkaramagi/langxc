import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/providers/history_provider.dart';
import '../../../core/models/vocabulary_item.dart';

class WeeklySummaryScreen extends StatefulWidget {
  const WeeklySummaryScreen({super.key});

  @override
  State<WeeklySummaryScreen> createState() => _WeeklySummaryScreenState();
}

class _WeeklySummaryScreenState extends State<WeeklySummaryScreen> {
  DateTime _selectedWeek = _getWeekStart(DateTime.now());
  List<VocabularyItem> _weeklyVocabulary = [];
  bool _isLoading = false;

  static DateTime _getWeekStart(DateTime date) {
    final weekday = date.weekday;
    return date.subtract(Duration(days: weekday - 1));
  }

  @override
  void initState() {
    super.initState();
    _loadWeeklyVocabulary();
  }

  Future<void> _loadWeeklyVocabulary() async {
    setState(() => _isLoading = true);
    final historyProvider = Provider.of<HistoryProvider>(
      context,
      listen: false,
    );
    final vocabulary = await historyProvider.getWeeklyVocabulary(_selectedWeek);
    setState(() {
      _weeklyVocabulary = vocabulary;
      _isLoading = false;
    });
  }

  void _previousWeek() {
    setState(() {
      _selectedWeek = _selectedWeek.subtract(const Duration(days: 7));
    });
    _loadWeeklyVocabulary();
  }

  void _nextWeek() {
    setState(() {
      _selectedWeek = _selectedWeek.add(const Duration(days: 7));
    });
    _loadWeeklyVocabulary();
  }

  void _goToCurrentWeek() {
    setState(() {
      _selectedWeek = _getWeekStart(DateTime.now());
    });
    _loadWeeklyVocabulary();
  }

  @override
  Widget build(BuildContext context) {
    final weekEnd = _selectedWeek.add(const Duration(days: 6));
    final dateFormat = DateFormat('MMM dd');
    final isCurrentWeek = _getWeekStart(DateTime.now()) == _selectedWeek;

    return Scaffold(
      appBar: AppBar(title: const Text('Weekly Vocabulary Summary')),
      body: Column(
        children: [
          // Week Selector
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: _previousWeek,
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        '${dateFormat.format(_selectedWeek)} - ${dateFormat.format(weekEnd)}',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (isCurrentWeek)
                        Text(
                          'This Week',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                              ),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: _nextWeek,
                ),
                if (!isCurrentWeek)
                  TextButton(
                    onPressed: _goToCurrentWeek,
                    child: const Text('Today'),
                  ),
              ],
            ),
          ),

          // Statistics
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: _StatCard(
                    icon: Icons.book,
                    label: 'New Words',
                    value: _weeklyVocabulary.length.toString(),
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _StatCard(
                    icon: Icons.check_circle,
                    label: 'Mastered',
                    value: _weeklyVocabulary
                        .where((v) => v.isMastered)
                        .length
                        .toString(),
                    color: Colors.green,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _StatCard(
                    icon: Icons.repeat,
                    label: 'Reviews',
                    value: _weeklyVocabulary
                        .fold<int>(0, (sum, v) => sum + v.reviewCount)
                        .toString(),
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
          ),

          // Vocabulary List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _weeklyVocabulary.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.book_outlined,
                          size: 64,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No vocabulary for this week',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withOpacity(0.7),
                              ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _weeklyVocabulary.length,
                    itemBuilder: (context, index) {
                      final item = _weeklyVocabulary[index];
                      return _VocabularyCard(item: item);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _VocabularyCard extends StatelessWidget {
  final VocabularyItem item;

  const _VocabularyCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Text(
          item.word,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text(
              item.translation,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Chip(
                  label: Text(
                    '${item.sourceLanguage.toUpperCase()} → ${item.targetLanguage.toUpperCase()}',
                    style: const TextStyle(fontSize: 10),
                  ),
                  padding: EdgeInsets.zero,
                ),
                const SizedBox(width: 8),
                if (item.reviewCount > 0)
                  Chip(
                    label: Text(
                      '${item.reviewCount}x reviewed',
                      style: const TextStyle(fontSize: 10),
                    ),
                    padding: EdgeInsets.zero,
                  ),
              ],
            ),
          ],
        ),
        trailing: item.isMastered
            ? Icon(Icons.check_circle, color: Colors.green)
            : IconButton(
                icon: const Icon(Icons.check_circle_outline),
                onPressed: () {
                  final historyProvider = Provider.of<HistoryProvider>(
                    context,
                    listen: false,
                  );
                  final updatedItem = item.copyWith(isMastered: true);
                  historyProvider.updateVocabularyItem(updatedItem);
                },
              ),
      ),
    );
  }
}
