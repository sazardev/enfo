import 'package:enfo/focus_quotes.dart';
import 'package:enfo/l10n/gen/app_localizations_en.dart';
import 'package:enfo/l10n/gen/app_localizations_es.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('500 consecutive days give 500 different quotes', () {
    final en = AppLocalizationsEn();
    final seen = <String>{};
    final start = DateTime(2026, 1, 1);
    for (var d = 0; d < FocusQuotes.cycle; d++) {
      final q = FocusQuotes.forDate(en, start.add(Duration(days: d)));
      expect(q.trim(), isNotEmpty, reason: 'day $d');
      expect(q.contains('  '), isFalse, reason: 'day $d');
      seen.add(q);
    }
    expect(seen.length, FocusQuotes.cycle);
  });

  test('deterministic for the day, repeats only after the cycle', () {
    final es = AppLocalizationsEs();
    final day = DateTime(2026, 5, 17);
    final morning = FocusQuotes.forDate(es, day);
    final night = FocusQuotes.forDate(es, DateTime(2026, 5, 17, 23, 59));
    expect(night, morning);
    expect(FocusQuotes.forDate(es, day.add(const Duration(days: 500))),
        morning);
  });

  test('consecutive days differ', () {
    final en = AppLocalizationsEn();
    expect(FocusQuotes.forDate(en, DateTime(2026, 3, 1)),
        isNot(FocusQuotes.forDate(en, DateTime(2026, 3, 2))));
  });

  test('every part is localized in English and Spanish', () {
    final en = AppLocalizationsEn();
    final es = AppLocalizationsEs();
    for (final l in [en, es]) {
      for (var d = 0; d < FocusQuotes.cycle; d++) {
        expect(FocusQuotes.forDate(l, DateTime(2026, 1, 1 + d)), isNotEmpty);
      }
    }
  });
}
