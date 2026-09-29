import 'dart:math' as math;

import 'package:enfo/ui/atoms/app_icon_button.dart';
import 'package:enfo/ui/atoms/chubby_icon.dart';
import 'package:enfo/ui/atoms/pop_in.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(Widget child) =>
    MaterialApp(home: Scaffold(body: Center(child: child)));

/// Effective scale of [target] from the Transform.scale ancestors that wrap it.
double _scaleOf(WidgetTester tester, Finder target) {
  var scale = 1.0;
  for (final t in tester.widgetList<Transform>(
    find.ancestor(of: target, matching: find.byType(Transform)),
  )) {
    final m = t.transform;
    // Length of the x axis: rotation-proof, and ignores the z axis (always 1).
    scale *= math
        .sqrt(m.entry(0, 0) * m.entry(0, 0) + m.entry(1, 0) * m.entry(1, 0));
  }
  return scale;
}

void main() {
  testWidgets('ChubbyIcon still exposes a real Icon', (tester) async {
    await tester.pumpWidget(
      _host(const ChubbyIcon(Icons.play_arrow_rounded, size: 40)),
    );
    expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
    expect(tester.getSize(find.byType(ChubbyIcon)), const Size(40, 40));
  });

  testWidgets('AppIconButton turns plain Icons into chubby ones',
      (tester) async {
    await tester.pumpWidget(_host(
      AppIconButton(icon: const Icon(Icons.tune_rounded), onPressed: () {}),
    ));
    expect(find.byType(ChubbyIcon), findsOneWidget);
    expect(find.byIcon(Icons.tune_rounded), findsOneWidget);
  });

  testWidgets('PopIn grows from nothing to full size, staggered',
      (tester) async {
    const key = Key('pop');
    await tester.pumpWidget(_host(
      const PopIn(
        delay: Duration(milliseconds: 100),
        child: SizedBox(key: key, width: 20, height: 20),
      ),
    ));
    expect(_scaleOf(tester, find.byKey(key)), closeTo(0, 0.001));

    await tester.pump(const Duration(milliseconds: 150));
    await tester.pump(const Duration(milliseconds: 150));
    final mid = _scaleOf(tester, find.byKey(key));
    expect(mid, greaterThan(0.05));

    await tester.pump(const Duration(seconds: 1));
    expect(_scaleOf(tester, find.byKey(key)), closeTo(1, 0.001));
  });

  testWidgets('tap fires the action and plays the pop, then settles',
      (tester) async {
    var taps = 0;
    await tester.pumpWidget(_host(
      AppIconButton(
        icon: const Icon(Icons.tune_rounded),
        onPressed: () => taps++,
      ),
    ));
    final icon = find.byType(ChubbyIcon);
    expect(_scaleOf(tester, icon), closeTo(1, 0.001));

    await tester.tap(icon);
    await tester.pump(); // first frame of the pop
    await tester.pump(const Duration(milliseconds: 60));
    expect(taps, 1);
    expect(_scaleOf(tester, icon), lessThan(0.95)); // squashed

    await tester.pump(const Duration(seconds: 1));
    expect(_scaleOf(tester, icon), closeTo(1, 0.01)); // back to normal
    expect(tester.takeException(), isNull);
  });

  testWidgets('flipping selected replays the pop', (tester) async {
    Widget button(bool selected) => _host(
          AppIconButton(
            icon: const Icon(Icons.push_pin_rounded),
            selected: selected,
            onPressed: () {},
          ),
        );
    await tester.pumpWidget(button(false));
    await tester.pumpWidget(button(true));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 60));
    expect(_scaleOf(tester, find.byType(ChubbyIcon)), lessThan(0.95));
    await tester.pump(const Duration(seconds: 1));
    expect(_scaleOf(tester, find.byType(ChubbyIcon)), closeTo(1, 0.01));
  });
}
