import sys
import glob
import os
import numpy as np
#import pymesh

def write_obj(swc_path):
    # if input is a directory, glob all swcs
    swcs = []
    if os.path.isdir(swc_path):
        swcs = glob.glob(os.path.normpath(swc_path) + '/*.swc')
    else:
        swcs.append(swc_path)

    for swc in swcs:
        current_swc = open(swc, 'r')
        lines = current_swc.readlines()
        current_swc.close()

        vertices = []
        mesh = None

        # first pass, mesh vertices and build vertex map
        for line in lines:
            if not line.strip() or line.strip()[0] == '#':
                continue

            swc_components = line.split(' ')
            vertex = (
                float(swc_components[2]),      # x
                float(swc_components[3]),      # y
                float(swc_components[4]),      # z
                float(swc_components[5]),      # radius
                int(swc_components[6].strip()) # parent ID
            )
            vertices.append(vertex)

            position = np.array(vertex[0:3])
            radius = vertex[3]

            if mesh is None:
                mesh = pymesh.generate_icosphere(position, radius)
            else:
                temp_mesh = pymesh.generate_icosphere(position, radius)
                mesh = pymesh.boolean(temp_mesh, mesh, 'symmetric_difference')

        # second pass, mesh edges using vertex map
        for vertex in vertices:

            parent_ID = vertex[4]
            if parent_ID != -1:

               child_position = np.array(vertex[0:3])
               child_radius = vertex[3]

               parent = vertices[parent_ID]
               parent_position = np.array(parent[0:3])
               parent_radius = parent[3]

               temp_mesh = pymesh.generate_cylinder(
                   child_position, parent_position,
                   child_radius, parent_radius
                )
               mesh = pymesh.boolean(temp_mesh, mesh, 'symmetric_difference')

        pymesh.save_mesh(swc[:-3] + 'obj', mesh)


if __name__ == "__main__":
    if len(sys.argv) != 2:
        print('\nSWC2OBJ -- Written by Nathan Spencer 2019')
        print('Usage: python swc2obj.py ["path/to/swc/folder" || "path/to/swc/file.swc"]')
    else:
        write_obj(sys.argv[1])
