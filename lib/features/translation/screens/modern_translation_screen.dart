import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../providers/translation_provider.dart';

class ModernTranslationScreen extends StatefulWidget {
  const ModernTranslationScreen({super.key});

  @override
  State<ModernTranslationScreen> createState() =>
      _ModernTranslationScreenState();
}

class _ModernTranslationScreenState extends State<ModernTranslationScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _sourceController = TextEditingController();
  late AnimationController _swapAnimationController;
  late Animation<double> _swapAnimation;

  @override
  void initState() {
    super.initState();
    _swapAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _swapAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _swapAnimationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _sourceController.dispose();
    _swapAnimationController.dispose();
    super.dispose();
  }

  void _onSwapLanguages() {
    final provider = Provider.of<TranslationProvider>(context, listen: false);

    _swapAnimationController.forward().then((_) {
      provider.swapLanguages();
      _sourceController.text = provider.sourceText;
      _swapAnimationController.reverse();
    });
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Copied to clipboard'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _shareTranslation(String text) {
    final provider = context.read<TranslationProvider>();
    final sourceText = provider.sourceText;
    final translatedText = text;
    
    // Create a formatted message with both source and translation
    final shareText = '''
🌏 Translation

📝 Original (${provider.sourceLangName}):
$sourceText

✅ Translation (${provider.targetLangName}):
$translatedText

Translated with LangXC 🚀
''';

    Share.share(shareText);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildLanguageSelector(),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildSourceSection(),
                    _buildDivider(),
                    _buildTranslationSection(),
                    const SizedBox(height: 16),
                    _buildFooter(),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            Icons.translate_rounded,
            size: 28,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Text(
            'Translate',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.of(context).pushNamed('/settings');
            },
            tooltip: 'Settings',
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageSelector() {
    return Consumer<TranslationProvider>(
      builder: (context, provider, _) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Expanded(
                child: _buildLanguageButton(
                  provider.sourceLangName,
                  true,
                  provider.sourceLang,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: AnimatedBuilder(
                  animation: _swapAnimation,
                  builder: (context, child) {
                    return Transform.rotate(
                      angle: _swapAnimation.value * 3.14159,
                      child: IconButton(
                        onPressed: _onSwapLanguages,
                        icon: const Icon(Icons.swap_horiz_rounded),
                        iconSize: 32,
                        style: IconButton.styleFrom(
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.primaryContainer,
                          foregroundColor: Theme.of(
                            context,
                          ).colorScheme.onPrimaryContainer,
                        ),
                      ),
                    );
                  },
                ),
              ),
              Expanded(
                child: _buildLanguageButton(
                  provider.targetLangName,
                  false,
                  provider.targetLang,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLanguageButton(String text, bool isSource, String langCode) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            langCode == 'ko' ? '🇰🇷' : '🇬🇧',
            style: const TextStyle(fontSize: 20),
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildSourceSection() {
    return Consumer<TranslationProvider>(
      builder: (context, provider, _) {
        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(
              context,
            ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _sourceController,
                decoration: InputDecoration(
                  hintText: provider.sourceLang == 'ko'
                      ? '번역할 텍스트를 입력하세요'
                      : 'Enter text to translate',
                  hintStyle: TextStyle(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.5),
                    fontSize: 18,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(fontSize: 18, height: 1.5),
                maxLines: null,
                onChanged: (value) {
                  provider.setSourceText(value);
                },
              ),
              if (provider.sourceText.isNotEmpty) ...[
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${provider.sourceText.length} characters',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          onPressed: () {
                            provider.clearText();
                            _sourceController.clear();
                          },
                          icon: const Icon(Icons.close_rounded),
                          iconSize: 20,
                          style: IconButton.styleFrom(
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.errorContainer.withValues(alpha: 0.5),
                            foregroundColor: Theme.of(
                              context,
                            ).colorScheme.onErrorContainer,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 1,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.outline.withValues(alpha: 0.0),
            Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
            Theme.of(context).colorScheme.outline.withValues(alpha: 0.0),
          ],
        ),
      ),
    );
  }

  Widget _buildTranslationSection() {
    return Consumer<TranslationProvider>(
      builder: (context, provider, _) {
        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(20),
          constraints: const BoxConstraints(minHeight: 120),
          decoration: BoxDecoration(
            color: Theme.of(
              context,
            ).colorScheme.primaryContainer.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (provider.isLoading)
                _buildLoadingIndicator()
              else if (provider.errorMessage != null)
                _buildErrorMessage(provider.errorMessage!)
              else if (provider.translatedText.isNotEmpty)
                _buildTranslatedText(provider.translatedText)
              else
                _buildEmptyState(),
              if (provider.translatedText.isNotEmpty) ...[
                const SizedBox(height: 16),
                _buildTranslationActions(provider.translatedText),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildLoadingIndicator() {
    return Column(
      children: [
        const SizedBox(
          height: 40,
          child: Center(child: CircularProgressIndicator()),
        ),
        const SizedBox(height: 8),
        Text(
          'Translating...',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorMessage(String error) {
    return Row(
      children: [
        Icon(
          Icons.error_outline_rounded,
          color: Theme.of(context).colorScheme.error,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            error,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.error,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTranslatedText(String text) {
    return SelectableText(
      text,
      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
        fontSize: 18,
        height: 1.5,
        color: Theme.of(context).colorScheme.onSurface,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        children: [
          Icon(
            Icons.translate_rounded,
            size: 48,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 12),
          Text(
            'Translation will appear here',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTranslationActions(String text) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        FilledButton.tonalIcon(
          onPressed: () => _copyToClipboard(text),
          icon: const Icon(Icons.copy_rounded, size: 18),
          label: const Text('Copy'),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
        ),
        const SizedBox(width: 8),
        FilledButton.icon(
          onPressed: () => _shareTranslation(text),
          icon: const Icon(Icons.share_rounded, size: 18),
          label: const Text('Share'),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Powered by',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF00C73C),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text(
              'PAPAGO',
              style: TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
