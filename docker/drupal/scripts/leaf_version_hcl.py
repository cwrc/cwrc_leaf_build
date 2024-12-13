
import hcl2
import argparse

def parse_args():
    parser = argparse.ArgumentParser()
    parser.add_argument('--src', required=True, help='Source HCL file.')
    parser.add_argument('--value', required=False, help='Set the LEAF version.')
    return parser.parse_args()


#
def get_leaf_version_from_hcl(data):
    leaf_version_hcl=""
    for item in data['variable']:
        if 'LEAF_VERSION' in item:
            leaf_version_hcl = item['LEAF_VERSION']['default']
    return leaf_version_hcl

# 
def process(source, leaf_version):
 
    with open(source, 'r') as hcl_file:
        data = hcl2.load(hcl_file)

    if leaf_version != "":
        print(f"value [{leaf_version}]")
        for item in data['variable']:
            if 'LEAF_VERSION' in item:
                item['LEAF_VERSION']['default'] = leaf_version
                with open(source, 'w') as hcl_file:
                    hcl_file.write(hcl2.dumps(data))
                exit(2)
                break
    else:
        print(f"value is empty [{leaf_version}]")
        exit(30)

 
#
def main():
 
    args = parse_args()
 
    process(args.src, args.value)
 
 
if __name__ == "__main__":
    main()
