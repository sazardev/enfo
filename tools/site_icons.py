# Regenerates docs/assets/js/icons.js glyphs: needs fonttools (python venv). Output json -> icons.js embed done by hand in session; see icons.js header.
import json
from fontTools.ttLib import TTFont
from fontTools.pens.svgPathPen import SVGPathPen
from fontTools.pens.transformPen import TransformPen
F='/home/omar/development/flutter/bin/cache/artifacts/material_fonts/'
font=TTFont(F+'MaterialIcons-Regular.otf'); gs=font.getGlyphSet(); cmap=font.getBestCmap()
cp={}
for l in open(F+'codepoints'):
    a=l.split()
    if len(a)==2: cp[a[0]]=int(a[1],16)
upm=font['head'].unitsPerEm
print('upm',upm,font['hhea'].ascent,font['hhea'].descent)
want={
 'pomodoro':'hourglass_bottom_rounded','clock':'schedule_rounded','timer':'timer_outlined','stopwatch':'av_timer_rounded','alarm':'alarm_rounded','world':'public_rounded',
 'event':'event_rounded','intervals':'fitness_center_rounded','breathe':'air_rounded','tracker':'track_changes_rounded','kitchen':'restaurant_rounded','sleep':'bedtime_rounded',
 'versus':'swap_horiz_rounded','breaks':'self_improvement_rounded','ambient':'graphic_eq_rounded','music':'library_music_rounded',
 'up':'keyboard_arrow_up_rounded','down':'keyboard_arrow_down_rounded','repeat':'repeat_rounded','eye':'remove_red_eye_rounded','prev':'skip_previous_rounded','next':'skip_next_rounded',
 'download':'download_rounded','android':'android','desktop':'desktop_windows_rounded','light':'light_mode_rounded','dark':'dark_mode_rounded','auto':'brightness_auto_rounded','check':'check_rounded',
 'external':'open_in_new_rounded','language':'language_rounded','keyboard':'keyboard_rounded','lock':'lock_rounded','offline':'cloud_off_rounded','devices':'devices_rounded','palette':'palette_rounded',
 'watch':'watch_rounded','tv':'tv_rounded','tablet':'tablet_rounded','phone':'smartphone_rounded','laptop':'laptop_rounded','code':'code_rounded','coffee':'coffee_rounded','menu':'menu_rounded','close':'close_rounded',
 'shuffle':'shuffle_rounded','note':'music_note_rounded','terminal':'terminal_rounded','store':'store_rounded','history':'history_rounded','chart':'bar_chart_rounded','anim':'animation_rounded','translate':'translate_rounded',
 'heart':'favorite_rounded','contrast':'contrast_rounded','more':'expand_more_rounded','bell':'notifications_rounded','noaccount':'no_accounts_rounded','shield':'verified_user_rounded','play':'play_arrow_rounded','pause':'pause_rounded',
 'refresh':'refresh_rounded','touch':'touch_app_rounded','dashboard':'dashboard_rounded','tune':'tune_rounded','fullscreen':'fullscreen_rounded','memory':'memory_rounded','ads':'ads_click_rounded','usage':'data_usage_rounded','widgets':'widgets_rounded','flat':'contrast_rounded','down2':'arrow_downward_rounded','moon':'nightlight_rounded'
}
out={}
for k,n in want.items():
    c=cp.get(n)
    if c is None: print('MISSING',n); continue
    g=cmap.get(c)
    if g is None: print('NOGLYPH',n,hex(c)); continue
    pen=SVGPathPen(gs, ntos=lambda v: ('%.1f'%v).rstrip('0').rstrip('.'))
    tp=TransformPen(pen,(1,0,0,-1,0,font['hhea'].ascent))
    gs[g].draw(tp)
    out[k]=pen.getCommands()
json.dump({'upm':upm,'ascent':font['hhea'].ascent,'icons':out},open('/tmp/icons.json','w'))
print(len(out), sum(len(v) for v in out.values()))
