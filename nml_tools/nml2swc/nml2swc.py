import glob
import code
import os
import sys
import xml.etree.ElementTree as ET


# Parse command line arguments
nmls_path = sys.argv[1]
nmls = glob.glob(os.path.normpath(nmls_path) + '/*.nml')

node_radius = sys.argv[2]


# Create directory for SWC output
output_folder_name = 'SWCs'
output_folder_path = './' + output_folder_name

if not os.path.exists(output_folder_path):
    os.makedirs(output_folder_path)


# Parse NMLs and write SWCs
rootFlag = True
for nml in nmls:
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

            if node_id in child_list:
                node_parent = child_parent[child_list.index(node_id)][1]
            elif rootFlag:
                node_parent = -1
		rootFlag = False
	    else:
		continue

            output_swc_path = output_folder_path + '/' + os.path.basename(os.path.normpath(nml))[:-4] + '.swc'
            swc = open(output_swc_path, 'a')
            swc.write(str(node_id) + ' 3 ' + str(node_x) + ' ' + str(node_y) + ' ' + str(node_z) + ' ' + str(node_radius) + ' ' + str(node_parent) + '\n')
            swc.close()

print('All finished!')
