# Android TV store assets

| File | Use |
| --- | --- |
| `banner-320x180.png` | TV banner bundled as `drawable-xhdpi/tv_banner.png` and used by the TV launcher |
| `banner-1280x720.png` | The TV banner Play Console asks for (1280×720) |
| `screenshots/en/` | 5 English TV screenshots, 1920×1080, RGB |
| `screenshots/es/` | 5 Spanish TV screenshots, 1920×1080, RGB |

The default Play listing is es-419; its TV assets currently use the Spanish
set. Keep both language sets in sync when a screen changes.

The banner is language-neutral: the “enfo” wordmark is the text; the tagline
is “reloj · timer”. If a localized banner is ever needed, keep the 320×180
size and put the localized words inside the same safe area.

## Play Console TV flow

1. Upload an AAB containing the TV manifest (`LEANBACK_LAUNCHER`, optional
   leanback/touchscreen features, `android:banner`).
2. Add a TV screenshot and mention “Android TV” in the listing.
3. Setup → Advanced Settings → Form Factors → Add release type → Android TV.
4. Publish the TV track and follow the review state under
   Pricing and distribution → Android TV.
