import 'package:flutter/material.dart';

import 'home.dart';
import 'presets.dart';
import 'ui/design/layout.dart';
import 'ui/design/page_transition.dart';
import 'ui/organisms/live_clock_bar.dart';
import 'ui/organisms/preset_picker.dart';

class Onboarding extends StatefulWidget {
  const Onboarding({super.key});

  @override
  State<Onboarding> createState() => _OnboardingState();
}

class _OnboardingState extends State<Onboarding> {
  int _workMinutes = Presets.classic.workMinutes;
  int _restMinutes = Presets.classic.restMinutes;

  Future<void> _start() async {
    await Presets.save(workMinutes: _workMinutes, restMinutes: _restMinutes);

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      appPageRoute((context) => const Home()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints:
                const BoxConstraints(maxWidth: AppLayout.maxContentWidth),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const LiveClockBar(fontSize: 15),
                  const SizedBox(height: 4),
                  Text(
                    'Enfo',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'Ritmo de enfoque',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 12),
                  PresetPicker(
                    initialWorkMinutes: _workMinutes,
                    initialRestMinutes: _restMinutes,
                    onChanged: (selection) {
                      setState(() {
                        _workMinutes = selection.workMinutes;
                        _restMinutes = selection.restMinutes;
                      });
                    },
                  ),
                  const SizedBox(height: 28),
                  FilledButton(
                    onPressed: _start,
                    child: const Text('Comenzar'),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
