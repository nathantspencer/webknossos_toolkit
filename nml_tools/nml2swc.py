import glob
import os
import re
import sys
import defusedxml.ElementTree as ET

def write_swc(nmls_path, radius=0):
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
        thing_list = tree.findall('thing')
        for thing in thing_list:
            nodes = thing.find('nodes')
            edges = thing.find('edges')
            comments = thing.find('comments')

            child_parent = []
            for edge in edges.findall('edge'):
                child = edge.get('target')
                parent = edge.get('source')
                child_parent.append((child, parent))

            child_list = [pair[0] for pair in child_parent]
            node_id, node_x, node_y, node_z, node_parent = ['']*5

            # parse comments to give special type to some swc nodes later
            id_to_type = {}
            for comment in comments.findall('comment'):
                comment_text = comment.get('content')
                if re.search('[Ii][Nn][Pp][Uu][Tt]', comment_text):
                    id_to_type[comment.get('node')] = 7
                elif re.search('[Ll][Oo][Ss][Tt]', comment_text):
                    id_to_type[comment.get('node')] = 6
                elif re.search('[Mm][Yy][Ee][Ll][Ii][Nn]', comment_text):
                    id_to_type[comment.get('node')] = 0

            for node in nodes.findall('node'):
                node_id = node.get('id')
                node_x = float(node.get('x'))
                node_y = float(node.get('y'))
                node_z = float(node.get('z')) * 5.4545
                if node_radius == 0:
                    node_radius = node.get('radius')

                if node_id in child_list:
                    node_parent = child_parent[child_list.index(node_id)][1]
                else:
                    node_parent = -1

                swc = open(swcs[nml_count], 'a')
                if node_id in id_to_type:
                    node_type = id_to_type[node_id]
                else:
                    node_type = 3
                swc.write(str(node_id) + ' ' + str(node_type) + ' ' + str(node_x) + ' ' + str(node_y) + ' ' + str(node_z) + ' ' + str(node_radius) + ' ' + str(node_parent) + '\n')
                swc.close()

    # correct indexing: enforce consecutive natural numbering
    print('Writing final .swc files...')
    for swc in swcs:
        lines_to_write = correct(swc, child_list, child_parent, node_id)
        f = open(swc, 'w')
        for line in lines_to_write:
            f.write(line + '\n')
        f.close()
        print(swc)

def correct(swc, child_list, child_parent, node_id):
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
        line = str(index_map[line.split(' ')[0]]) + line[len(line.split(' ')[0]):]
        lines_to_write.append(line)

    n = 0
    for line in lines_to_write:
        line = line[:-len(line.split(' ')[6])] + str(index_map[(line.split(' ')[6])[:-1]])
        lines_to_write[n] = line
        n += 1
    return lines_to_write

if __name__ == "__main__":
    if len(sys.argv) < 2 or len(sys.argv) > 3:
        print('\nNML2SWC -- Written by Nathan Spencer 2016')
        print('Usage: python nml2swc.py ["path/to/nml/file.nml" || "path/to/nml/folder"] [radius]')
        print('Note: radius argument is optional; radius from nml will be used by default')
    elif len(sys.argv) == 2:
        write_swc(sys.argv[1])
    else:
        write_swc(sys.argv[1], sys.argv[2])
