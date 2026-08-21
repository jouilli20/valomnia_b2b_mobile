import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import '../l10n/language_controller.dart';

class LanguageSelector extends ConsumerWidget {
  const LanguageSelector({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLocale =
        ref.watch(languageControllerProvider).value ??
        Localizations.localeOf(context);
    final currentLanguage = appLanguages.firstWhere(
      (language) => language.locale.languageCode == currentLocale.languageCode,
      orElse: () => appLanguages.first,
    );

    return PopupMenuButton<Locale>(
      tooltip: context.l10n.text('languageSelectorTooltip'),
      initialValue: currentLanguage.locale,
      onSelected: (locale) {
        ref.read(languageControllerProvider.notifier).setLocale(locale);
      },
      itemBuilder: (context) {
        return [
          for (final language in appLanguages)
            PopupMenuItem(
              value: language.locale,
              child: Row(
                children: [
                  SizedBox(
                    width: 24,
                    child:
                        language.locale.languageCode ==
                            currentLanguage.locale.languageCode
                        ? const Icon(Icons.check_rounded, size: 18)
                        : null,
                  ),
                  const SizedBox(width: 8),
                  Text(language.label),
                ],
              ),
            ),
        ];
      },
      child: Padding(
        padding: compact
            ? const EdgeInsets.symmetric(horizontal: 8, vertical: 6)
            : const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.translate_rounded,
              size: compact ? 18 : 20,
              color: compact ? const Color(0xFF64748B) : Colors.white,
            ),
            const SizedBox(width: 6),
            Text(
              currentLanguage.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: compact ? const Color(0xFF475569) : Colors.white,
                fontSize: compact ? 13 : 14,
                fontWeight: FontWeight.w800,
              ),
            ),
            Icon(
              Icons.expand_more_rounded,
              size: compact ? 18 : 20,
              color: compact ? const Color(0xFF64748B) : Colors.white,
            ),
          ],
        ),
      ),
    );
  }
}
