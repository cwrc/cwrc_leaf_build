import argparse
import os
import sys
import yaml

def parse_args():
    parser = argparse.ArgumentParser()
    parser.add_argument('--input', action="append", required=True, nargs="+", help='Input Files.')
    parser.add_argument('--output', required=False, nargs="?", type=argparse.FileType('w'), default=sys.stdout, help='Limit to a given resource.')
    return parser.parse_args()


#
def merge_yaml(input_arg):
    merged_data = {}
    for input_files in input_arg:
        for file in input_files:
            with open(file, 'r') as stream:
                print(file)
                data = yaml.safe_load(stream)
                merge_dicts(merged_data, data)
    return merged_data


#
def merge_dicts(a, b):
    for key, value in b.items():
        if key in a and isinstance(a[key], dict) and isinstance(value, dict):
            merge_dicts(a[key], value)
        else:
            a[key] = value


#
def process(inputs, output):

    merged_data = merge_yaml(inputs)
    #with open(output, 'w') as outfile:
    yaml.safe_dump(merged_data, output, default_flow_style=False, sort_keys=False)


#
def main():

    args = parse_args()

    #if not os.path.exists(args.output):
    #    os.makedirs(args.output)

    process(args.input, args.output)


if __name__ == "__main__":
    main()
