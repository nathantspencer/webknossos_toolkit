import glob
import os
import sys
import xml.etree.ElementTree as ET

def write_swc(nmls_path, radius=0):
    nmls_path = sys.argv[1]
    node_radius = radius

    # store paths to nmls
    nmls = []
    if os.path.isdir(nmls_path):
        nmls = glob.glob(os.path.normpath(nmls_path) + '/*.nml')
    else:
        nmls.append(nmls_path)

    # create paths for resulting swcs
    swcs = []
    for nml in nmls:
        swcs.append(nml[:-4] + '.swc')
    for swc in swcs:
        if os.path.exists(swc):
            os.remove(swc)

    print('\nReading from .nml files...')
    nml_count = -1
    for nml in nmls:
        nml_count += 1
        tree = ET.parse(nml)
        things = tree.getroot()
        thing_list = tree.findall('thing')
        for thing in thing_list:
            nodes = thing.find('nodes')
            edges = thing.find('edges')

            child_parent = []
            for edge in edges.findall('edge'):
                child = edge.get('target')
                parent = edge.get('source')
                child_parent.append((child, parent))

            child_list = [pair[0] for pair in child_parent]
            node_id = ''
            node_x = ''
            node_y = ''
            node_z = ''
            node_parent = ''

            for node in nodes.findall('node'):
                node_id = node.get('id')
                node_x = node.get('x')
                node_y = node.get('y')
                node_z = float(node.get('z')) * 5.4545
                if node_radius == 0:
                    node_radius = node.get('radius')

                if node_id in child_list:
                    node_parent = child_parent[child_list.index(node_id)][1]
                else:
                    node_parent = -1

                swc = open(swcs[nml_count], 'a')
                swc.write(str(node_id) + ' 3 ' + str(node_x) + ' ' + str(node_y) + ' ' + str(node_z) + ' ' + str(node_radius) + ' ' + str(node_parent) + '\n')
                swc.close()

    # correct indexing: enforce consecutive natural numbering
    print('Writing final .swc files...')
    for swc in swcs:
        lines_to_write = []
        index_map = {'-1':-1}
        f = open(swc, 'r')
        lines = f.readlines()
        f.close()
        n = 1
        for line in lines:
            index_map[line.split(' ')[0]] = n
            n += 1

        for line in lines:
            new_child = index_map[line.split(' ')[0]]
            line = line[len(line.split(' ')[0]):]
            line = str(new_child) + line
            lines_to_write.append(line)

        n = 0
        for line in lines_to_write:
            new_parent = index_map[(line.split(' ')[6])[:-1]]
            line = line[:-len(line.split(' ')[6])]
            line = line + str(new_parent)
            lines_to_write[n] = line
            n += 1
            if node_id in child_list:
                node_parent = child_parent[child_list.index(node_id)][1]
	        else:
	            node_parent = -1

        f = open(swc, 'w')
        for line in lines_to_write:
            f.write(line + '\n')
        f.close()
        print(swc)

if __name__ == "__main__":
    if len(sys.argv) < 2 or len(sys.argv) > 3:
        print('\nNML2SWC -- Written by Nathan Spencer 2016')
        print('Usage: python nml2swc.py ["path/to/nml/file.nml" || "path/to/nml/folder"] [radius]')
        print('Note: radius argument is optional; radius from nml will be used by default')
    elif len(sys.argv) == 2:
        write_swc(sys.argv[1])
    else:
        write_swc(sys.argv[1], sys.argv[2])
