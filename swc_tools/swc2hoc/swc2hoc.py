import matlab.engine
import scipy.io as sio
import sys

def write_hoc(swc_path):

    f = open(swc_path, 'r')
    swc_lines = f.readlines()

    print('\nFiring up the MATLAB engine...')
    eng = matlab.engine.start_matlab()

    print('Performing TREES Toolbox analysis...\n')
    success = eng.trees_analysis(swc_path)
    mat = sio.loadmat('vars.mat')

    sections = mat['sect'].tolist()
    parent_list = []
    for x in range(len(sections)):
        parent_list.append(sections[x][1])
    branchpoints = mat['branchpoints'].tolist()

    f = open(swc_path[:-4] + '.hoc', 'w')
    f.write('objref soma\nsoma = new SectionList()\n')
    f.write('objref dendrite\ndendrite = new SectionList()\n\n')

    # First segment will be written as the soma section
    print('\nWriting .hoc file...')
    f.write('create sections[' + str(len(sections)) + ']\n')
    f.write('access sections[0]\n')
    f.write('soma.append()\nsections[0] {\n')

    for i in range(sections[0][0], sections[0][1]):
        f.write('  pt3dadd(')
        f.write(swc_lines[i].split(' ')[2] + ', ')
        f.write(swc_lines[i].split(' ')[3] + ', ')
        f.write(swc_lines[i].split(' ')[4] + ', ')
        f.write(swc_lines[i].split(' ')[5] + ')\n')
    f.write('}\n\n')

    # All following sections are assumed to be dendrite sections
    for i in range(1, len(sections)):
        parent = parent_list.index(sections[i][0])
        f.write('access sections[' + str(i) + ']\n')
        f.write('dendrite.append()\n')
        f.write('connect sections[' + str(i) + '](0), sections[' + str(parent) + '](1)\n')
        f.write('sections[' + str(i) +'] {\n')
        for j in range(sections[i-1][1], sections[i][1]):
            f.write('  pt3dadd(')
            f.write(swc_lines[j].split(' ')[2] + ', ')
            f.write(swc_lines[j].split(' ')[3] + ', ')
            f.write(swc_lines[j].split(' ')[4] + ', ')
            f.write(swc_lines[j].split(' ')[5] + ')\n')
        f.write('}\n\n')

    print(swc_path[:-4] + '.hoc')


if __name__ == "__main__":
    if len(sys.argv) != 2:
        print('\nSWC2HOC -- Written by Nathan Spencer 2016')
        print('Usage: python swc2hoc.py "path/to/swc/file.swc"')
    else:
        write_hoc(sys.argv[1])
