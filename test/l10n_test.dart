import 'dart:ui';

import 'package:enfo/l10n/gen/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('every key resolves in both languages, plurals work', () async {
    final en = await AppLocalizations.delegate.load(const Locale('en'));
    final es = await AppLocalizations.delegate.load(const Locale('es'));
    expect(en.statsStreak(1), 'Day in a row');
    expect(en.statsStreak(3), 'Days in a row');
    expect(es.statsStreak(1), 'Día seguido');
    expect(es.statsStreak(3), 'Días seguidos');
    expect(en.sessionPauses(2, '1m'), '2 pauses (1m)');
    expect(es.sessionPauses(1, '30s'), '1 pausa (30s)');
    expect(es.timersSubtitle(25, 5), '25 min enfoque · 5 min descanso');
  });
}
