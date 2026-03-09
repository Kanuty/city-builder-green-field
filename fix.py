with open("scenes/game.gd", "r") as f:
    lines = f.readlines()

new_lines = []
skip = False
for i, l in enumerate(lines):
    if l.strip() == "load_state()" and i > 80 and i < 100:
        continue
    elif l.strip() == "placement_preview.visible = false" and i > 80 and i < 100:
        new_lines.append("\tload_state()\n")
        new_lines.append(l)
    else:
        new_lines.append(l)

with open("scenes/game.gd", "w") as f:
    f.writelines(new_lines)
