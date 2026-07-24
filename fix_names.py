import re

# 1. Android Manifest
android_manifest_path = 'app/frontend/android/app/src/main/AndroidManifest.xml'
with open(android_manifest_path, 'r') as f:
    content = f.read()
content = content.replace('android:label="AdaptedMind"', 'android:label="Sipsara"')
content = content.replace('android:label="adapted_mind_app"', 'android:label="Sipsara"')
with open(android_manifest_path, 'w') as f:
    f.write(content)
print("Updated AndroidManifest.xml")

# 2. iOS Info.plist
ios_plist_path = 'app/frontend/ios/Runner/Info.plist'
with open(ios_plist_path, 'r') as f:
    content = f.read()
content = content.replace('<string>AdaptedMind</string>', '<string>Sipsara</string>')
content = content.replace('<string>adapted_mind_app</string>', '<string>Sipsara</string>')
with open(ios_plist_path, 'w') as f:
    f.write(content)
print("Updated iOS Info.plist")

