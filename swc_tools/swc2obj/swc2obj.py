import sys
import glob
import os

def write_obj(swc_path):
    swcs = []
    if os.path.isdir(swc_path):
        swcs = glob.glob(os.path.normpath(swc_path) + '/*.swc')
    else:
        swcs.append(swc_path)

    for swc in swcs:
        current_swc = open(swc, 'r')
        lines = current_swc.readlines()
        lines_to_write = []
        current_swc.close()

        for line in lines:
            swc_components = line.split(' ')
            lines_to_write.append('v ' + swc_components[2] + ' ' + swc_components[3] + \
                ' ' + swc_components[4] + '\n')

        obj = open(swc[:-3] + 'obj', 'w')

        for line in lines_to_write:
            obj.write(line)

        obj.close()
        print(swc[:-3] + 'obj')

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print('\nNML_MERGER -- Written by Nathan Spencer 2016')
        print('Usage: python swc2obj.py ["path/to/nml/folder" || "path/tp/nml/file.nml"]')
    else:
        write_obj(sys.argv[1])
