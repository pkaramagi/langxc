import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/translation_provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/history_provider.dart';
import '../../../core/models/translation.dart';
import '../../../core/constants/app_constants.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _textController = TextEditingController();
  TranslationDirection _selectedDirection = TranslationDirection.koToEn;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _translate() {
    final translationProvider = Provider.of<TranslationProvider>(
      context,
      listen: false,
    );
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    translationProvider.translate(
      text: _textController.text,
      direction: _selectedDirection,
      userId: authProvider.user?.id,
    );
  }

  void _addToVocabulary() {
    final translationProvider = Provider.of<TranslationProvider>(
      context,
      listen: false,
    );
    final historyProvider = Provider.of<HistoryProvider>(
      context,
      listen: false,
    );

    if (translationProvider.currentTranslation != null) {
      historyProvider.addToVocabulary(translationProvider.currentTranslation!);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Added to vocabulary')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('LangXC'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => context.push(AppConstants.historyRoute),
            tooltip: 'History',
          ),
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () => context.push(AppConstants.weeklySummaryRoute),
            tooltip: 'Weekly Summary',
          ),
          Consumer<AuthProvider>(
            builder: (context, authProvider, _) {
              return PopupMenuButton(
                icon: CircleAvatar(
                  backgroundImage: authProvider.user?.photoUrl != null
                      ? NetworkImage(authProvider.user!.photoUrl!)
                      : null,
                  child: authProvider.user?.photoUrl == null
                      ? Text(
                          authProvider.user?.displayName?[0].toUpperCase() ??
                              'U',
                        )
                      : null,
                ),
                itemBuilder: (context) => <PopupMenuEntry>[
                  PopupMenuItem(
                    enabled: false,
                    child: Text(
                      'Signed in as ${authProvider.user?.email ?? "User"}',
                    ),
                  ),
                  const PopupMenuDivider(),
                  PopupMenuItem(
                    child: const Text('Sign Out'),
                    onTap: () async {
                      await authProvider.signOut();
                      if (mounted) {
                        context.go(AppConstants.loginRoute);
                      }
                    },
                  ),
                ],
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Direction Selector
            SegmentedButton<TranslationDirection>(
              segments: const [
                ButtonSegment(
                  value: TranslationDirection.koToEn,
                  label: Text('한국어 → English'),
                ),
                ButtonSegment(
                  value: TranslationDirection.enToKo,
                  label: Text('English → 한국어'),
                ),
              ],
              selected: {_selectedDirection},
              onSelectionChanged: (Set<TranslationDirection> newSelection) {
                setState(() {
                  _selectedDirection = newSelection.first;
                });
                final translationProvider = Provider.of<TranslationProvider>(
                  context,
                  listen: false,
                );
                translationProvider.setDirection(_selectedDirection);
              },
            ),
            const SizedBox(height: 24),

            // Input Card
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _selectedDirection == TranslationDirection.koToEn
                          ? '한국어 입력'
                          : 'Enter English',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _textController,
                      maxLines: 5,
                      decoration: InputDecoration(
                        hintText:
                            _selectedDirection == TranslationDirection.koToEn
                            ? '번역할 한국어를 입력하세요'
                            : 'Enter text to translate',
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Consumer<TranslationProvider>(
                      builder: (context, translationProvider, _) {
                        return SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: translationProvider.isTranslating
                                ? null
                                : _translate,
                            icon: translationProvider.isTranslating
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.translate),
                            label: Text(
                              translationProvider.isTranslating
                                  ? 'Translating...'
                                  : 'Translate',
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Translation Result Card
            Consumer<TranslationProvider>(
              builder: (context, translationProvider, _) {
                if (translationProvider.errorMessage != null) {
                  return Card(
                    color: Theme.of(context).colorScheme.errorContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        translationProvider.errorMessage!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onErrorContainer,
                        ),
                      ),
                    ),
                  );
                }

                if (translationProvider.currentTranslation == null) {
                  return const SizedBox.shrink();
                }

                final translation = translationProvider.currentTranslation!;
                return Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _selectedDirection == TranslationDirection.koToEn
                                  ? 'English Translation'
                                  : '한국어 번역',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            IconButton(
                              icon: const Icon(Icons.bookmark_add),
                              onPressed: _addToVocabulary,
                              tooltip: 'Add to vocabulary',
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            translation.targetText,
                            style: Theme.of(
                              context,
                            ).textTheme.bodyLarge?.copyWith(fontSize: 18),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
