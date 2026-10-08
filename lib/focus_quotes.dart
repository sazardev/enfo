import 'l10n/gen/app_localizations.dart';

/// The daily focus-quote bank: 20 leads x 25 thoughts = 500 combinations,
/// so the sequence only repeats after 500 days. The parts live in the ARBs
/// (quoteLeadN / quoteThoughtN) and are combined deterministically by date.
abstract final class FocusQuotes {
  static const leads = 20;
  static const thoughts = 25;
  static const cycle = leads * thoughts;

  /// The quote for [date] (local calendar day).
  static String forDate(AppLocalizations l10n, DateTime date) {
    // UTC so a daylight-saving shift cannot make two days share an index.
    final day = DateTime.utc(date.year, date.month, date.day)
        .difference(DateTime.utc(2024, 1, 1))
        .inDays;
    final i = ((day % cycle) + cycle) % cycle;
    return '${_lead(l10n, i % leads)} ${_thought(l10n, i ~/ leads)}';
  }

  static String _lead(AppLocalizations l10n, int i) => switch (i) {
        0 => l10n.quoteLead1,
        1 => l10n.quoteLead2,
        2 => l10n.quoteLead3,
        3 => l10n.quoteLead4,
        4 => l10n.quoteLead5,
        5 => l10n.quoteLead6,
        6 => l10n.quoteLead7,
        7 => l10n.quoteLead8,
        8 => l10n.quoteLead9,
        9 => l10n.quoteLead10,
        10 => l10n.quoteLead11,
        11 => l10n.quoteLead12,
        12 => l10n.quoteLead13,
        13 => l10n.quoteLead14,
        14 => l10n.quoteLead15,
        15 => l10n.quoteLead16,
        16 => l10n.quoteLead17,
        17 => l10n.quoteLead18,
        18 => l10n.quoteLead19,
        19 => l10n.quoteLead20,
        _ => '',
      };

  static String _thought(AppLocalizations l10n, int i) => switch (i) {
        0 => l10n.quoteThought1,
        1 => l10n.quoteThought2,
        2 => l10n.quoteThought3,
        3 => l10n.quoteThought4,
        4 => l10n.quoteThought5,
        5 => l10n.quoteThought6,
        6 => l10n.quoteThought7,
        7 => l10n.quoteThought8,
        8 => l10n.quoteThought9,
        9 => l10n.quoteThought10,
        10 => l10n.quoteThought11,
        11 => l10n.quoteThought12,
        12 => l10n.quoteThought13,
        13 => l10n.quoteThought14,
        14 => l10n.quoteThought15,
        15 => l10n.quoteThought16,
        16 => l10n.quoteThought17,
        17 => l10n.quoteThought18,
        18 => l10n.quoteThought19,
        19 => l10n.quoteThought20,
        20 => l10n.quoteThought21,
        21 => l10n.quoteThought22,
        22 => l10n.quoteThought23,
        23 => l10n.quoteThought24,
        24 => l10n.quoteThought25,
        _ => '',
      };
}
