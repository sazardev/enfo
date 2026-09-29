/* Single source of truth for links and identifiers used across the site.
   NOTE: the repo slug is defined ONCE here. The user wrote "sazarcode/enfo"
   but `git remote` says "sazardev/enfo"; the git remote value is used.
   Change GITHUB_SLUG below and every link on the site follows. */
window.SITE = (function () {
  var GITHUB_SLUG = 'sazardev/enfo';
  var PACKAGE_ID = 'com.sazarcode.enfo';
  var GH = 'https://github.com/' + GITHUB_SLUG;
  return {
    name: 'Enfo',
    version: '1.2.0',
    githubSlug: GITHUB_SLUG,
    packageId: PACKAGE_ID,
    urls: {
      repo: GH,
      releases: GH + '/releases/latest',
      allReleases: GH + '/releases',
      issues: GH + '/issues',
      changelog: GH + '/blob/master/CHANGELOG.md',
      credits: GH + '/blob/master/assets/music/CREDITS.md',
      play: 'https://play.google.com/store/apps/details?id=' + PACKAGE_ID,
      coffee: 'https://www.buymeacoffee.com/sazarcode',
      fontLicense: 'assets/fonts/OFL.txt'
    },
    /* Where the sync script drops the manifest describing screenshots/videos. */
    mediaManifest: 'assets/media.json'
  };
})();
