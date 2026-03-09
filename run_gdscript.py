import json

def load_data(file_path):
    with open(file_path, "r") as f:
        return json.load(f)

# we don't have python script execution needed
