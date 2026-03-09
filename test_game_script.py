with open("scenes/game.gd", "r") as f:
    lines = f.readlines()

# check where load_state is called
for i, l in enumerate(lines):
    if "load_state()" in l:
        print(f"line {i}: {l.strip()}")
