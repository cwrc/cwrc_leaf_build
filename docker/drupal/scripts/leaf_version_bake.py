
import argparse
import json 

def parse_args():
    parser = argparse.ArgumentParser()
    parser.add_argument('--src', required=True, help='Source HCL file.')
    parser.add_argument('--value', required=False, help='Set the LEAF version.')
    return parser.parse_args()


#
def process(source, leaf_version):
 
    with open(source, 'r') as bake_file:
        data = json.load(bake_file)
        print(data)

    if leaf_version != "":
        print(f"Input value [{leaf_version}]")
        if 'LEAF_VERSION' in data['variable']:
            print(f"Current value [{data['variable']['LEAF_VERSION']['default']}]")
            data['variable']['LEAF_VERSION']['default'] = leaf_version
            with open(source, 'w') as bake_file:
                bake_file.write(json.dumps(data, indent=4))
    else:
        print(f"value is empty [{leaf_version}]")
        exit(30)

 
#
def main():
 
    args = parse_args()
 
    process(args.src, args.value)
 
 
if __name__ == "__main__":
    main()
