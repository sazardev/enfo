import 'package:enfo/daily_quote.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    DailyQuote.debugReset();
  });

  test('the switch and the time persist', () async {
    await DailyQuote.load();
    expect(DailyQuote.enabled, isFalse);
    expect(DailyQuote.hour, DailyQuote.defaultHour);
    await DailyQuote.setEnabled(true);
    await DailyQuote.setTime(7, 30);
    DailyQuote.debugReset();
    await DailyQuote.load();
    expect(DailyQuote.enabled, isTrue);
    expect(DailyQuote.hour, 7);
    expect(DailyQuote.minute, 30);
  });

  test('plan covers 30 future days with distinct quotes and slots', () {
    DailyQuote.enabled = true;
    DailyQuote.hour = 9;
    DailyQuote.minute = 0;
    final p = DailyQuote.plan(DateTime(2026, 6, 1, 8));
    expect(p.length, DailyQuote.horizonDays);
    expect(p.first.at, DateTime(2026, 6, 1, 9));
    expect(p.first.id, DailyQuote.firstId);
    expect(p[1].at, DateTime(2026, 6, 2, 9));
    expect(p[1].id, DailyQuote.firstId + 1);
    expect(p.map((s) => s.quote).toSet().length, DailyQuote.horizonDays);
  });

  test('plan skips today once its time passed', () {
    DailyQuote.enabled = true;
    DailyQuote.hour = 9;
    DailyQuote.minute = 0;
    final p = DailyQuote.plan(DateTime(2026, 6, 1, 10));
    expect(p.length, DailyQuote.horizonDays);
    expect(p.first.at, DateTime(2026, 6, 2, 9));
    expect(p.first.id, DailyQuote.firstId + 1);
    expect(p.last.at, DateTime(2026, 7, 1, 9));
  });
}
