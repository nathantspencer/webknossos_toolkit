import xmltodict
import os
import math
import glob
from xml.etree.ElementTree import Element, SubElement, ElementTree
import sys
import lxml.etree as etree
import fnmatch

def merge_nml(skeleton_folder, file_to_write):
    skeleton_folder = sys.argv[1]
    file_to_write = sys.argv[2]
    files_to_merge = glob.glob(skeleton_folder + '/*.nml')

    files_to_merge = []
    for root, _, filenames in os.walk(skeleton_folder, followlinks=True):
        for filename in fnmatch.filter(filenames, '*.nml'):
            files_to_merge.append(os.path.join(root, filename))

    things = Element('things')

    nodeCount = 0
    thingCount = 0
    for ii, filename in enumerate(files_to_merge):
        try:
            thingCount += 1

            with open(filename) as fd:
                doc = xmltodict.parse(fd.read())

            if ii == 0:
                parameters = SubElement(things, 'parameters')
                SubElement(parameters, 'experiment', {'name ': doc['things']['parameters']['experiment']['@name']})
            print filename

            thing = SubElement(things, 'thing', {'id': str(thingCount),
                                                 'color.r': doc['things']['thing']['@color.r'],
                                                 'color.g': doc['things']['thing']['@color.g'],
                                                 'color.b': doc['things']['thing']['@color.b'],
                                                 'color.a': doc['things']['thing']['@color.a'],
                                                 'name': 'Tree' + str(thingCount)})

            nodes = SubElement(thing, 'nodes')
            lastNodeCount = nodeCount

            for node in doc['things']['thing']['nodes']['node']:

                translateX = 0
                translateY = 0

                if node.get('@rotX') == None:
                    node['@rotX'] = '0'
                    node['@rotY'] = '0'
                    node['@rotZ'] = '0'
                    node['@inMag'] = '0'
                    node['@bitDepth'] = '8'
                    node['@interpolation'] = 'false'

                    translateX = int(math.floor(float(doc['things']['parameters']['skeletonVPState'].get('@translateX'))))
                    translateY = int(math.floor(float(doc['things']['parameters']['skeletonVPState'].get('@translateY'))))

                node = SubElement(nodes, 'node', {'id': str(int(node['@id']) + lastNodeCount),
                                                  'radius': node['@radius'],
                                                  'x': str(int(node['@x']) - translateX + translateX),
                                                  'y': str(int(node['@y']) - translateY + translateY),
                                                  'z': node['@z'],
                                                  'rotX': node['@rotX'],
                                                  'rotY': node['@rotY'],
                                                  'rotZ': node['@rotZ'],
                                                  'inVp': node['@inVp'],
                                                  'inMag': node['@inMag'],
                                                  'bitDepth': node['@bitDepth'],
                                                  'interpolation': node['@interpolation'],
                                                  'time': node['@time']})

                nodeCount = int(node.attrib['id']) + lastNodeCount

            edges = SubElement(thing, 'edges')
            for edge in doc['things']['thing']['edges']['edge']:
                edge = SubElement(edges, 'edge', {'source': (str(int(edge['@source']) + lastNodeCount)),
                                                  'target': (str(int(edge['@target']) + lastNodeCount))})

        except:
            print 'ERROR -- file ' + filename + ' is malformed or empty, try redownloading it.'

    tree = ElementTree(things)
    tree.write(file_to_write)
    x = etree.parse(file_to_write)
    f = open(file_to_write, "w")
    f.write(etree.tostring(x, pretty_print=True))
    f.close()

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print('\nNML_MERGER -- Written by Nathan Spencer, Micahel Morehead, Anna Whelan 2016')
        print('Usage: python nml_merger.py ["path/to/nml/folder"] ["path/to/output/file.nml"]')
    else:
        merge_nml(sys.argv[1], sys.argv[2])
