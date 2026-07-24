with open('app/frontend/lib/screens/welcome_screen.dart', 'r') as f:
    content = f.read()

import re

# We want to replace the row of two texts with a single text widget "Sipsara"
pattern = r"Text\(\s*'Adapted',\s*style:\s*AppTypography\.heading\(\s*fontSize:\s*44,\s*fontWeight:\s*FontWeight\.w800,\s*color:\s*AppColors\.textPrimary,\s*height:\s*1\.0,\s*\),\s*\),\s*Text\(\s*'Mind',\s*style:\s*AppTypography\.heading\(\s*fontSize:\s*44,\s*fontWeight:\s*FontWeight\.w800,\s*color:\s*AppColors\.calmBlue,\s*height:\s*1\.0,\s*\),\s*\),"
replacement = r"Text(\n                          'Sipsara',\n                          style: AppTypography.heading(\n                            fontSize: 44,\n                            fontWeight: FontWeight.w800,\n                            color: AppColors.calmBlue,\n                            height: 1.0,\n                          ),\n                        ),"
new_content = re.sub(pattern, replacement, content)

if new_content != content:
    with open('app/frontend/lib/screens/welcome_screen.dart', 'w') as f:
        f.write(new_content)
    print("Fixed welcome_screen.dart")
else:
    print("welcome_screen.dart not changed")

