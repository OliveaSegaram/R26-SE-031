import os

directories = [
    'app/frontend/lib',
    'app/frontend/test',
    'app/frontend/pubspec.yaml',
    'app/backend'
]

replacements = {
    'AdaptedMindApp': 'SipsaraApp',
    'AdaptedMind': 'Sipsara',
    'adaptedmind': 'sipsara',
    'adapted_mind': 'sipsara'
}

def replace_in_file(filepath):
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.read()
    except UnicodeDecodeError:
        return 
    
    new_content = content
    for old, new in replacements.items():
        new_content = new_content.replace(old, new)
        
    if new_content != content:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(new_content)
        print(f"Updated {filepath}")

for d in directories:
    if os.path.isfile(d):
        replace_in_file(d)
    else:
        for root, _, files in os.walk(d):
            for file in files:
                if file.endswith('.dart') or file.endswith('.py') or file.endswith('.yaml'):
                    replace_in_file(os.path.join(root, file))
