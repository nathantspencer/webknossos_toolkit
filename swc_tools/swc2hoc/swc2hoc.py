import matlab.engine
import scipy.io as sio
import sys
import numpy
import code

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

    code.interact(local=locals())

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

        # UNCOMMENT CODE BELOW TO HELP IDENTIFY PROBLEM SECTIONS
        # IF THERE ARE LARGE JUMPS IN YOUR RESULTING HOCCODE --
        # SOMETIMES THE TREES TOOLBOX FAILS TO FIND A BRANCH

        # x_last = float(swc_lines[sections[i][0]].split(' ')[2])
        # y_last = float(swc_lines[sections[i][0]].split(' ')[3])
        # z_last = float(swc_lines[sections[i][0]].split(' ')[4])

        # x_next = float(swc_lines[sections[i-1][1]+1].split(' ')[2])
        # y_next = float(swc_lines[sections[i-1][1]+1].split(' ')[3])
        # z_next = float(swc_lines[sections[i-1][1]+1].split(' ')[4])

        # distance = pow(pow(x_last-x_next, 2)+pow(y_last-y_next,2)+pow(z_last-z_next,2) , 0.5)
        # if distance > 400:
        #     print(str(i) + ': ' + str(distance))

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
