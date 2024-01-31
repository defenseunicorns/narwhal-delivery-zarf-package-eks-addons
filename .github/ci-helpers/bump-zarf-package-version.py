import yaml
import sys

def load_yaml(file_path):
    with open(file_path) as file:
        return yaml.safe_load(file)

def save_yaml(data, file_path):
    with open(file_path, 'w') as file:
        yaml.safe_dump(data, file)

def bump_version(version_str):
    major, minor, patch = map(int, version_str.split('.'))
    return f"{major}.{minor}.{patch + 1}"

def main(yaml_file_path):
    data = load_yaml(yaml_file_path)

    data['package']['create']['set']['package_version'] = bump_version(data['package']['create']['set']['package_version'])

    save_yaml(data, yaml_file_path)

if __name__ == "__main__":
    main(sys.argv[1])