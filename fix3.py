with open("scenes/buildings/house.gd", "r") as f:
    lines = f.readlines()

new_lines = []
for i, l in enumerate(lines):
    new_lines.append(l)
    if "var unit = unit_type.instantiate()" in l:
        new_lines.append(l.replace("var unit = unit_type.instantiate()", "unit.scene_file_path = unit_type.resource_path"))

with open("scenes/buildings/house.gd", "w") as f:
    f.writelines(new_lines)
