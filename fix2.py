with open("scripts/Global.gd", "r") as f:
    lines = f.readlines()

new_lines = []
for i, l in enumerate(lines):
    new_lines.append(l)
    if "var inst = scene.instantiate()" in l:
        new_lines.append(l.replace("var inst = scene.instantiate()", "inst.scene_file_path = b_data[\"scene_path\"]"))
    if "var inst = unit_scene.instantiate()" in l:
        new_lines.append(l.replace("var inst = unit_scene.instantiate()", "inst.scene_file_path = scene_path"))

with open("scripts/Global.gd", "w") as f:
    f.writelines(new_lines)
