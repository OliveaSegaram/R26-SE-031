import os
import re

lib_dir = "lib/screens"

for root, _, files in os.walk(lib_dir):
    for file in files:
        if file.endswith(".dart"):
            filepath = os.path.join(root, file)
            with open(filepath, 'r') as f:
                content = f.read()

            # Find instances of Center(child: CircularProgressIndicator(...))
            # We want to be careful and only replace ones that match Center(child: CircularProgressIndicator)
            
            pattern = r'Center\(\s*child:\s*CircularProgressIndicator\([^)]*\)\s*\)'
            
            if re.search(pattern, content):
                # We need to add the import if it's not there
                if "import" in content and "app_loading_indicator.dart" not in content:
                    depth = filepath.count('/') - 2 # subtracting "lib/screens"
                    prefix = "../" * depth if depth > 0 else ""
                    if "screens/" in filepath:
                         prefix = "../" * (filepath.split("screens/")[1].count('/'))
                    import_str = f"import '{prefix}../widgets/app_loading_indicator.dart';\n"
                    
                    content = re.sub(r"(import 'package:flutter/material\.dart';\n)", r"\1" + import_str, content)
                
                # Replace the pattern with Center(child: AppLoadingIndicator())
                content = re.sub(pattern, r'Center(child: AppLoadingIndicator())', content)
                
                # Also handle simple Center(child: CircularProgressIndicator()) without args
                pattern2 = r'Center\(\s*child:\s*CircularProgressIndicator\(\)\s*\)'
                content = re.sub(pattern2, r'Center(child: AppLoadingIndicator())', content)
                
                with open(filepath, 'w') as f:
                    f.write(content)
                print(f"Updated {filepath}")
