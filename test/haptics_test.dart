import 'package:enfo/haptics/haptic_events.dart';
import 'package:enfo/haptics/haptics.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final phone = FakePhone();

  setUp(() async {
    await resetTestState();
    phone.system.clear();
    phone.patterns.clear();
    phone.cancels = 0;
    phone.attach();
    Haptics.debugAvailable = true;
    Haptics.debugAmplitude = true;
    Haptics.resetCapabilities();
  });
  tearDown(() {
    Haptics.debugAvailable = null;
    Haptics.debugAmplitude = null;
    phone.detach();
  });

  Future<void> flush() =>
      Future<void>.delayed(const Duration(milliseconds: 30));

  group('gating', () {
    test('does nothing where there is no vibration motor', () async {
      Haptics.debugAvailable = false;
      Haptics.tap();
      Haptics.success();
      await flush();
      expect(phone.system, isEmpty);
      expect(phone.patterns, isEmpty);
    });

    test('master switch silences everything', () async {
      await Haptics.setEnabled(false);
      Haptics.tap();
      Haptics.tick();
      Haptics.success();
      Haptics.ringCycle();
      await flush();
      expect(phone.system, isEmpty);
      expect(phone.patterns, isEmpty);
    });

    test('each category can be switched off on its own', () async {
      await Haptics.setTouch(false);
      Haptics.tap();
      Haptics.confirm();
      await flush();
      expect(phone.system, isEmpty);

      Haptics.transition(); // motion still on
      await flush();
      expect(phone.system, isNotEmpty);
      phone.system.clear();

      await Haptics.setMotion(false);
      Haptics.tick();
      await flush();
      expect(phone.system, isEmpty);

      await Haptics.setAlerts(false);
      Haptics.success();
      Haptics.phaseComplete(toRest: true);
      await flush();
      expect(phone.patterns, isEmpty);
    });

    test('preview ignores category switches but not the master', () async {
      await Haptics.setTouch(false);
      Haptics.preview(HapticEvents.tap);
      await flush();
      expect(phone.system, isNotEmpty);

      phone.system.clear();
      await Haptics.setEnabled(false);
      Haptics.preview(HapticEvents.tap);
      await flush();
      expect(phone.system, isEmpty);
    });
  });

  group('strength keeps the vocabulary in proportion', () {
    Future<String> tapWith(HapticStrength s) async {
      phone.system.clear();
      Haptics.resetCapabilities();
      await Haptics.setStrength(s);
      await Future<void>.delayed(const Duration(milliseconds: 30)); // debounce
      Haptics.tap();
      await flush();
      return phone.system.single;
    }

    test('a tap gets firmer as strength rises', () async {
      final soft = await tapWith(HapticStrength.soft);
      final medium = await tapWith(HapticStrength.medium);
      final strong = await tapWith(HapticStrength.strong);
      const order = [
        'HapticFeedbackType.selectionClick',
        'HapticFeedbackType.lightImpact',
        'HapticFeedbackType.mediumImpact',
        'HapticFeedbackType.heavyImpact',
      ];
      expect(order.indexOf(soft) <= order.indexOf(medium), true);
      expect(order.indexOf(medium) <= order.indexOf(strong), true);
      expect(soft, isNot(strong));
    });

    test('a confirm is always firmer than a tap at every strength', () async {
      const order = [
        'HapticFeedbackType.selectionClick',
        'HapticFeedbackType.lightImpact',
        'HapticFeedbackType.mediumImpact',
        'HapticFeedbackType.heavyImpact',
      ];
      for (final s in HapticStrength.values) {
        await Haptics.setStrength(s);
        phone.system.clear();
        await Future<void>.delayed(const Duration(milliseconds: 30));
        Haptics.tap();
        await Future<void>.delayed(const Duration(milliseconds: 30));
        Haptics.confirm();
        await flush();
        expect(phone.system, hasLength(2));
        expect(order.indexOf(phone.system[1]) >= order.indexOf(phone.system[0]),
            true,
            reason: s.name);
      }
    });

    test('composed amplitudes scale with strength and stay in 1..255',
        () async {
      int peak(HapticStrength s) {
        final intens = (phone.patterns.last['intensities'] as List).cast<int>();
        return intens.reduce((a, b) => a > b ? a : b);
      }

      final peaks = <HapticStrength, int>{};
      for (final s in HapticStrength.values) {
        await Haptics.setStrength(s);
        Haptics.success();
        await flush();
        peaks[s] = peak(s);
      }
      expect(
          peaks[HapticStrength.soft]!, lessThan(peaks[HapticStrength.medium]!));
      expect(peaks[HapticStrength.medium]!,
          lessThanOrEqualTo(peaks[HapticStrength.strong]!));
      for (final v in peaks.values) {
        expect(v, inInclusiveRange(1, 255));
      }
    });
  });

  group('composed events', () {
    test('phase change: rest fades away, work builds up', () async {
      Haptics.phaseComplete(toRest: true);
      await flush();
      Haptics.phaseComplete(toRest: false);
      await flush();

      List<int> amps(Map<Object?, Object?> p) =>
          (p['intensities'] as List).cast<int>().where((a) => a > 0).toList();
      final rest = amps(phone.patterns[0]);
      final work = amps(phone.patterns[1]);
      // Rest: each pulse softer than the last. Work: each firmer.
      expect(rest, orderedEquals([...rest]..sort((a, b) => b.compareTo(a))));
      expect(work, orderedEquals([...work]..sort()));
      expect(rest.first, greaterThan(rest.last));
      expect(work.last, greaterThan(work.first));
    });

    test('a pattern is [wait, on, wait, on...] matched by its intensities',
        () async {
      Haptics.ringCycle(); // heartbeat by default
      await flush();
      final call = phone.patterns.single;
      final pattern = (call['pattern'] as List).cast<int>();
      final intens = (call['intensities'] as List).cast<int>();
      expect(pattern.length, intens.length);
      expect(pattern.length.isEven, true);
      // Heartbeat: lub ... dub -> two buzzes, the gaps carry zero intensity.
      expect(pattern.length, 4);
      expect(intens[0], 0);
      expect(intens[1], greaterThan(0));
      expect(intens[2], 0);
      expect(intens[3], greaterThan(0));
      expect(intens[1], greaterThan(intens[3])); // lub firmer than dub
      expect(call['sharpness'], isNotNull);
    });

    test('without amplitude control it falls back to system impacts, in order',
        () async {
      Haptics.debugAmplitude = false;
      Haptics.resetCapabilities();
      Haptics.phaseComplete(toRest: false); // ascending charge
      await Future<void>.delayed(const Duration(milliseconds: 400));
      expect(phone.patterns, isEmpty);
      expect(phone.system, hasLength(3));
      const order = [
        'HapticFeedbackType.lightImpact',
        'HapticFeedbackType.mediumImpact',
        'HapticFeedbackType.heavyImpact',
      ];
      final ranks = phone.system.map(order.indexOf).toList();
      expect(ranks, orderedEquals([...ranks]..sort()));
      expect(ranks.first, lessThan(ranks.last));
    });

    test('cancel cuts a running vibration and pending beats', () async {
      Haptics.debugAmplitude = false;
      Haptics.resetCapabilities();
      Haptics.timerDone();
      await Future<void>.delayed(const Duration(milliseconds: 20));
      await Haptics.cancel();
      final before = phone.system.length;
      await Future<void>.delayed(const Duration(milliseconds: 500));
      expect(phone.system.length, before, reason: 'later beats were cancelled');
      expect(phone.cancels, 1);
    });
  });

  group('alarm patterns', () {
    test('every pattern is well-formed and ends before it repeats', () {
      for (final p in AlarmPattern.values) {
        final e = p.event;
        expect(e.period, isNotNull, reason: p.name);
        expect(e.pulses, isNotEmpty);
        expect(e.duration, lessThanOrEqualTo(p.period), reason: p.name);
        var cursor = 0;
        for (final pulse in e.pulses) {
          expect(pulse.at, greaterThanOrEqualTo(cursor),
              reason: '${p.name}: pulses must not overlap');
          expect(pulse.strength, inInclusiveRange(0.01, 1.0));
          expect(pulse.length, greaterThan(0));
          cursor = pulse.end;
        }
      }
    });

    test('the chosen pattern is what rings, and its period drives the ringer',
        () async {
      for (final p in AlarmPattern.values) {
        await Haptics.setAlarmPattern(p);
        expect(Haptics.ringPeriod(), p.period);
        phone.patterns.clear();
        Haptics.ringCycle();
        await flush();
        final pattern = (phone.patterns.single['pattern'] as List).cast<int>();
        expect(pattern.length, p.event.pulses.length * 2, reason: p.name);
      }
      // A finished timer has its own triple beat, whatever the alarm is.
      expect(Haptics.ringPeriod(timer: true), HapticEvents.timerDone.period);
    });

    test('notification pattern mirrors the ringer and follows strength',
        () async {
      await Haptics.setAlarmPattern(AlarmPattern.ripple);
      await Haptics.setStrength(HapticStrength.medium);
      final medium = Haptics.notificationPattern();
      expect(medium.length, AlarmPattern.ripple.event.pulses.length * 2);
      expect(medium.first, 0);

      await Haptics.setStrength(HapticStrength.soft);
      final soft = Haptics.notificationPattern();
      expect(soft[1], lessThan(medium[1])); // shorter buzz when soft
    });
  });

  test('a burst of ticks is thinned so the motor is not smeared', () async {
    for (var i = 0; i < 20; i++) {
      Haptics.tick();
    }
    await flush();
    expect(phone.system.length, lessThan(20));
    expect(phone.system, isNotEmpty);
  });

  test('settings persist', () async {
    await Haptics.setEnabled(false);
    await Haptics.setStrength(HapticStrength.strong);
    await Haptics.setMotion(false);
    await Haptics.setAlarmPattern(AlarmPattern.beacon);
    await Haptics.load();
    expect(Haptics.enabled.value, false);
    expect(Haptics.strength.value, HapticStrength.strong);
    expect(Haptics.motion.value, false);
    expect(Haptics.alarmPattern.value, AlarmPattern.beacon);
  });
}
