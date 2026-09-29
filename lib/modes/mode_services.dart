import 'ambient/ambient_service.dart';
import 'breaks/breaks_service.dart';
import 'event/event_service.dart';
import 'intervals/intervals_service.dart';
import 'kitchen/kitchen_service.dart';
import 'tracker/tracker_service.dart';

/// State that must keep working while another mode is on screen (a running
/// interval workout, kitchen timers, break reminders, playing sound, an
/// activity being tracked). Loaded once at boot; [check] runs on the host's
/// one-second heartbeat, whichever mode is visible.
abstract interface class ModeService {
  /// Restore persisted state. Called once from `main()`.
  Future<void> load();

  /// Called every second by `ModeHost`. Must be cheap and must not throw.
  void check();
}

final List<ModeService> modeServices = [
  EventService.instance,
  IntervalsService.instance,
  KitchenService.instance,
  BreaksService.instance,
  AmbientService.instance,
  TrackerService.instance,
];

Future<void> loadModeServices() async {
  for (final s in modeServices) {
    await s.load();
  }
}

void checkModeServices() {
  for (final s in modeServices) {
    try {
      s.check();
    } catch (_) {}
  }
}
