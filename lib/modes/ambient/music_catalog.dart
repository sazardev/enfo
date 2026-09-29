/// One bundled song. All of them come from Wikimedia Commons, where the
/// license of every file is verified; see assets/music/CREDITS.md.
class MusicTrack {
  const MusicTrack({
    required this.asset,
    required this.title,
    required this.artist,
    required this.seconds,
    required this.license,
    required this.licenseUrl,
    required this.source,
  });

  final String asset;
  final String title;
  final String artist;
  final int seconds;

  /// Short license name, e.g. `CC0` or `CC BY 4.0`.
  final String license;
  final String licenseUrl;

  /// The file's page on Wikimedia Commons.
  final String source;

  /// CC BY needs the artist credited wherever the song is used.
  bool get needsCredit => license != 'CC0';
}

/// Lo-fi / chill songs bundled with the app (about 40 minutes, ~21 MB,
/// re-encoded to Ogg Vorbis ~96 kbps). CC0 first, then CC BY.
const List<MusicTrack> musicCatalog = [
  MusicTrack(
    asset: 'assets/music/01_chill_beat.ogg',
    title: 'Chill Beat',
    artist: 'Maddy',
    seconds: 96,
    license: 'CC0',
    licenseUrl: 'http://creativecommons.org/publicdomain/zero/1.0/deed.en',
    source: 'https://commons.wikimedia.org/wiki/File:Chill_Beat.ogg',
  ),
  MusicTrack(
    asset:
        'assets/music/02_kuromaru_ft_hereafter_laxin_lo_fi_background_music.ogg',
    title: '’laxin',
    artist: 'Kuromaru',
    seconds: 104,
    license: 'CC BY 3.0',
    licenseUrl: 'https://creativecommons.org/licenses/by/3.0',
    source:
        'https://commons.wikimedia.org/wiki/File:Kuromaru_ft_.hereafter_-_%E2%80%99laxin_(Lo_Fi_Background_Music).ogg',
  ),
  MusicTrack(
    asset: 'assets/music/03_lofi_music_001.ogg',
    title: 'Lofi 001',
    artist: 'Luisalvaz',
    seconds: 166,
    license: 'CC0',
    licenseUrl: 'http://creativecommons.org/publicdomain/zero/1.0/deed.en',
    source: 'https://commons.wikimedia.org/wiki/File:Lofi_music_001.wav',
  ),
  MusicTrack(
    asset: 'assets/music/04_loyalty_freak_music_01_sweet_you.ogg',
    title: 'Sweet You',
    artist: 'Loyalty Freak Music',
    seconds: 160,
    license: 'CC0',
    licenseUrl: 'http://creativecommons.org/publicdomain/zero/1.0/deed.en',
    source:
        'https://commons.wikimedia.org/wiki/File:Loyalty_Freak_Music_-_01_-_Sweet_You.ogg',
  ),
  MusicTrack(
    asset: 'assets/music/05_loyalty_freak_music_02_old_saga.ogg',
    title: 'Old Saga',
    artist: 'Loyalty Freak Music',
    seconds: 150,
    license: 'CC0',
    licenseUrl: 'http://creativecommons.org/publicdomain/zero/1.0/deed.en',
    source:
        'https://commons.wikimedia.org/wiki/File:Loyalty_Freak_Music_-_02_-_Old_Saga.ogg',
  ),
  MusicTrack(
    asset: 'assets/music/06_loyalty_freak_music_06_softly.ogg',
    title: 'Softly',
    artist: 'Loyalty Freak Music',
    seconds: 262,
    license: 'CC0',
    licenseUrl: 'http://creativecommons.org/publicdomain/zero/1.0/deed.en',
    source:
        'https://commons.wikimedia.org/wiki/File:Loyalty_Freak_Music_-_06_-_Softly.ogg',
  ),
  MusicTrack(
    asset: 'assets/music/07_loyalty_freak_music_08_beach.ogg',
    title: 'Beach',
    artist: 'Loyalty Freak Music',
    seconds: 161,
    license: 'CC0',
    licenseUrl: 'http://creativecommons.org/publicdomain/zero/1.0/deed.en',
    source:
        'https://commons.wikimedia.org/wiki/File:Loyalty_Freak_Music_-_08_-_Beach.ogg',
  ),
  MusicTrack(
    asset: 'assets/music/08_loyalty_freak_music_09_shoepop.ogg',
    title: 'Shoepop',
    artist: 'Loyalty Freak Music',
    seconds: 164,
    license: 'CC0',
    licenseUrl: 'http://creativecommons.org/publicdomain/zero/1.0/deed.en',
    source:
        'https://commons.wikimedia.org/wiki/File:Loyalty_Freak_Music_-_09_-_Shoepop.ogg',
  ),
  MusicTrack(
    asset: 'assets/music/09_loyalty_freak_music_10_hangover.ogg',
    title: 'Hangover',
    artist: 'Loyalty Freak Music',
    seconds: 193,
    license: 'CC0',
    licenseUrl: 'http://creativecommons.org/publicdomain/zero/1.0/deed.en',
    source:
        'https://commons.wikimedia.org/wiki/File:Loyalty_Freak_Music_-_10_-_Hangover.ogg',
  ),
  MusicTrack(
    asset: 'assets/music/10_loyalty_freak_music_11_standing.ogg',
    title: 'Standing',
    artist: 'Loyalty Freak Music',
    seconds: 161,
    license: 'CC0',
    licenseUrl: 'http://creativecommons.org/publicdomain/zero/1.0/deed.en',
    source:
        'https://commons.wikimedia.org/wiki/File:Loyalty_Freak_Music_-_11_-_Standing.ogg',
  ),
  MusicTrack(
    asset: 'assets/music/11_loyalty_freak_music_13_work.ogg',
    title: 'Work',
    artist: 'Loyalty Freak Music',
    seconds: 145,
    license: 'CC0',
    licenseUrl: 'http://creativecommons.org/publicdomain/zero/1.0/deed.en',
    source:
        'https://commons.wikimedia.org/wiki/File:Loyalty_Freak_Music_-_13_-_Work.ogg',
  ),
  MusicTrack(
    asset: 'assets/music/12_raspberrymusic_lofi_hip_hop_upbeat.ogg',
    title: 'Lofi Hip Hop Upbeat',
    artist: 'raspberrymusic',
    seconds: 134,
    license: 'CC BY 4.0',
    licenseUrl: 'https://creativecommons.org/licenses/by/4.0',
    source:
        'https://commons.wikimedia.org/wiki/File:Raspberrymusic_-_Lofi_Hip_Hop_Upbeat.ogg',
  ),
  MusicTrack(
    asset: 'assets/music/13_sappheiros_perspective_lofi_hip_hop.ogg',
    title: 'Perspective',
    artist: 'Sappheiros',
    seconds: 137,
    license: 'CC BY 3.0',
    licenseUrl: 'https://creativecommons.org/licenses/by/3.0',
    source:
        'https://commons.wikimedia.org/wiki/File:Sappheiros_-_Perspective_(Lofi_Hip_Hop).ogg',
  ),
  MusicTrack(
    asset: 'assets/music/14_study_and_relax_by_kevin_macleod.ogg',
    title: 'Study And Relax',
    artist: 'Kevin MacLeod',
    seconds: 223,
    license: 'CC BY 4.0',
    licenseUrl: 'https://creativecommons.org/licenses/by/4.0',
    source:
        'https://commons.wikimedia.org/wiki/File:Study_And_Relax_by_Kevin_MacLeod.ogg',
  ),
];
