import os
import re

def verify_godot_deps():
    errors = 0
    res_pattern = re.compile(r'res://([a-zA-Z0-9_\-\./]+)')

    for root, _, files in os.walk('.'):
        for file in files:
            if file.endswith('.gd') or file.endswith('.tscn'):
                filepath = os.path.join(root, file)
                with open(filepath, 'r', encoding='utf-8') as f:
                    content = f.read()

                    matches = res_pattern.findall(content)
                    for match in matches:
                        if not os.path.exists(match):
                            print(f"Error in {filepath}: Resource {match} does not exist!")
                            errors += 1

    if errors == 0:
        print("All resources verified successfully.")
    else:
        print(f"Found {errors} missing resources.")

if __name__ == "__main__":
    verify_godot_deps()
