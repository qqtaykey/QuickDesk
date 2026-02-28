import dmgbuild
import os
import json
import sys

current_file_path = os.path.dirname(os.path.realpath(__file__))
script_root = os.path.normpath(os.path.join(current_file_path, '..', '..'))

app_name = 'QuickDesk'

build_mode = sys.argv[1] if len(sys.argv) > 1 else 'Release'
publish_path = os.path.normpath(os.path.join(script_root, 'publish', build_mode))
app_path = os.path.join(publish_path, f'{app_name}.app')
dmg_path = os.path.join(publish_path, f'{app_name}.dmg')
settings_path = os.path.join(current_file_path, 'dmg-settings.json')

bg_path = os.path.join(current_file_path, 'dmg-background.jpg')
icon_path = os.path.join(app_path, 'Contents', 'Resources', f'{app_name}.icns')


def generate_settings():
    settings = {
        'title': app_name,
        'icon-size': 120,
        'format': 'UDZO',
        'compression-level': 9,
        'window': {
            'position': {'x': 400, 'y': 200},
            'size': {'width': 660, 'height': 400}
        },
        'contents': [
            {'x': 180, 'y': 190, 'type': 'file', 'path': app_path},
            {'x': 480, 'y': 190, 'type': 'link', 'path': '/Applications'}
        ]
    }
    if os.path.exists(bg_path):
        settings['background'] = bg_path
    if os.path.exists(icon_path):
        settings['icon'] = icon_path
    with open(settings_path, 'w') as f:
        json.dump(settings, f, indent=2)


if __name__ == '__main__':
    if not os.path.exists(app_path):
        print(f'Error: {app_path} not found')
        print(f'Please run publish_qd_mac.sh {build_mode} first')
        sys.exit(1)

    print(f'Generating DMG settings...')
    generate_settings()

    print(f'Building DMG: {dmg_path}')
    dmgbuild.build_dmg(dmg_path, app_name, settings_path)

    if not os.path.exists(dmg_path):
        print(f'Failed to create {dmg_path}')
        sys.exit(1)

    print(f'DMG created: {dmg_path}')
    sys.exit(0)
