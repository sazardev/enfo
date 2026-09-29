import '../../l10n/locale_controller.dart';

/// A city the world clock can show: an IANA time-zone id plus its name in
/// each language.
class WorldCity {
  const WorldCity(this.id, this.en, this.es, {String? zone})
      : zone = zone ?? id;

  /// Unique, stable identifier (what is stored). IANA-style.
  final String id;

  /// The tz-database zone that gives this city's offset and DST rules.
  /// Usually [id]; a few cities borrow a canonical zone (see below).
  final String zone;
  final String en;
  final String es;

  String name(String languageCode) => languageCode == 'es' ? es : en;
}

/// Curated cities, roughly one or two per time zone people ask about.
///
/// [WorldCity.zone] supplies the offset and daylight-saving rules, and must
/// exist in the compact bundled tz database (a test checks).
/// That database keeps only canonical zones, so a few cities point at the
/// canonical zone that shares their rules (Amsterdam uses Brussels'; Oslo
/// and Stockholm use Berlin's; Addis Ababa uses Nairobi's). Because of that
/// [WorldCity.id] (not the zone) is what identifies a city.
const worldCities = <WorldCity>[
  WorldCity('America/New_York', 'New York', 'Nueva York'),
  WorldCity('America/Los_Angeles', 'Los Angeles', 'Los Ángeles'),
  WorldCity('America/Chicago', 'Chicago', 'Chicago'),
  WorldCity('America/Denver', 'Denver', 'Denver'),
  WorldCity('America/Phoenix', 'Phoenix', 'Phoenix'),
  WorldCity('America/Anchorage', 'Anchorage', 'Anchorage'),
  WorldCity('Pacific/Honolulu', 'Honolulu', 'Honolulu'),
  WorldCity('America/Toronto', 'Toronto', 'Toronto'),
  WorldCity('America/Vancouver', 'Vancouver', 'Vancouver'),
  WorldCity('America/Mexico_City', 'Mexico City', 'Ciudad de México'),
  WorldCity('America/Guatemala', 'Guatemala City', 'Ciudad de Guatemala'),
  WorldCity('America/Costa_Rica', 'San José', 'San José'),
  WorldCity('America/Panama', 'Panama City', 'Ciudad de Panamá'),
  WorldCity('America/Havana', 'Havana', 'La Habana'),
  WorldCity('America/Santo_Domingo', 'Santo Domingo', 'Santo Domingo'),
  WorldCity('America/Bogota', 'Bogotá', 'Bogotá'),
  WorldCity('America/Lima', 'Lima', 'Lima'),
  WorldCity('America/Caracas', 'Caracas', 'Caracas'),
  WorldCity('America/Guayaquil', 'Quito', 'Quito'),
  WorldCity('America/La_Paz', 'La Paz', 'La Paz'),
  WorldCity('America/Santiago', 'Santiago', 'Santiago'),
  WorldCity('America/Argentina/Buenos_Aires', 'Buenos Aires', 'Buenos Aires'),
  WorldCity('America/Montevideo', 'Montevideo', 'Montevideo'),
  WorldCity('America/Sao_Paulo', 'São Paulo', 'São Paulo'),
  WorldCity('Europe/London', 'London', 'Londres'),
  WorldCity('Europe/Dublin', 'Dublin', 'Dublín'),
  WorldCity('Europe/Lisbon', 'Lisbon', 'Lisboa'),
  WorldCity('Europe/Madrid', 'Madrid', 'Madrid'),
  WorldCity('Europe/Paris', 'Paris', 'París'),
  WorldCity('Europe/Amsterdam', 'Amsterdam', 'Ámsterdam',
      zone: 'Europe/Brussels'),
  WorldCity('Europe/Brussels', 'Brussels', 'Bruselas'),
  WorldCity('Europe/Berlin', 'Berlin', 'Berlín'),
  WorldCity('Europe/Zurich', 'Zurich', 'Zúrich'),
  WorldCity('Europe/Rome', 'Rome', 'Roma'),
  WorldCity('Europe/Vienna', 'Vienna', 'Viena'),
  WorldCity('Europe/Prague', 'Prague', 'Praga'),
  WorldCity('Europe/Warsaw', 'Warsaw', 'Varsovia'),
  WorldCity('Europe/Stockholm', 'Stockholm', 'Estocolmo',
      zone: 'Europe/Berlin'),
  WorldCity('Europe/Oslo', 'Oslo', 'Oslo', zone: 'Europe/Berlin'),
  WorldCity('Europe/Helsinki', 'Helsinki', 'Helsinki'),
  WorldCity('Europe/Athens', 'Athens', 'Atenas'),
  WorldCity('Europe/Kyiv', 'Kyiv', 'Kiev'),
  WorldCity('Europe/Istanbul', 'Istanbul', 'Estambul'),
  WorldCity('Europe/Moscow', 'Moscow', 'Moscú'),
  WorldCity('Africa/Casablanca', 'Casablanca', 'Casablanca'),
  WorldCity('Africa/Lagos', 'Lagos', 'Lagos'),
  WorldCity('Africa/Cairo', 'Cairo', 'El Cairo'),
  WorldCity('Africa/Nairobi', 'Nairobi', 'Nairobi'),
  WorldCity('Africa/Addis_Ababa', 'Addis Ababa', 'Adís Abeba',
      zone: 'Africa/Nairobi'),
  WorldCity('Africa/Johannesburg', 'Johannesburg', 'Johannesburgo'),
  WorldCity('Asia/Jerusalem', 'Jerusalem', 'Jerusalén'),
  WorldCity('Asia/Riyadh', 'Riyadh', 'Riad'),
  WorldCity('Asia/Tehran', 'Tehran', 'Teherán'),
  WorldCity('Asia/Dubai', 'Dubai', 'Dubái'),
  WorldCity('Asia/Karachi', 'Karachi', 'Karachi'),
  WorldCity('Asia/Kolkata', 'Delhi', 'Delhi'),
  WorldCity('Asia/Colombo', 'Colombo', 'Colombo'),
  WorldCity('Asia/Kathmandu', 'Kathmandu', 'Katmandú'),
  WorldCity('Asia/Dhaka', 'Dhaka', 'Daca'),
  WorldCity('Asia/Bangkok', 'Bangkok', 'Bangkok'),
  WorldCity('Asia/Jakarta', 'Jakarta', 'Yakarta'),
  WorldCity('Asia/Singapore', 'Singapore', 'Singapur'),
  WorldCity('Asia/Hong_Kong', 'Hong Kong', 'Hong Kong'),
  WorldCity('Asia/Shanghai', 'Shanghai', 'Shanghái'),
  WorldCity('Asia/Manila', 'Manila', 'Manila'),
  WorldCity('Asia/Seoul', 'Seoul', 'Seúl'),
  WorldCity('Asia/Tokyo', 'Tokyo', 'Tokio'),
  WorldCity('Australia/Perth', 'Perth', 'Perth'),
  WorldCity('Australia/Sydney', 'Sydney', 'Sídney'),
  WorldCity('Australia/Melbourne', 'Melbourne', 'Melbourne'),
  WorldCity('Pacific/Auckland', 'Auckland', 'Auckland'),
  WorldCity('Pacific/Fiji', 'Suva', 'Suva'),
];

WorldCity? cityById(String id) {
  for (final c in worldCities) {
    if (c.id == id) return c;
  }
  return null;
}

/// City name in the app's current language.
String cityName(WorldCity city) => city.name(currentL10n().localeName);
