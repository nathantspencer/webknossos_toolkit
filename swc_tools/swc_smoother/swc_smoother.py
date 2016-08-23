import sys
import numpy

def swc_smooth(swc_file, allowable_change):

    f = open(swc_file, 'r')
    lines = f.readlines()
    radii = []
    parents = []
    for line in lines:
        radii.append(float(line.split(' ')[5]))
        parents.append(int(line.split(' ')[6]))

    new_radii = []
    for i in range(len(radii)):
        if i > 0 and i < len(radii)-1:
            if radii[i] > (radii[i - 1] * allowable_change):
                new_radii.append(round(radii[i] / numpy.sqrt(allowable_change), 4))
            elif radii[i] < (radii[i - 1] / allowable_change):
                new_radii.append(round(radii[i] * numpy.sqrt(allowable_change), 4))
            else:
                new_radii.append(radii[i])
        else:
            new_radii.append(radii[i])

    f.close()
    f = open(swc_file[:-4] + '_smooth.swc', 'w')

    for i in range(len(lines)):
        f.write(lines[i].split(' ')[0] + ' ' + lines[i].split(' ')[1] + ' ' + \
            lines[i].split(' ')[2] + ' ' + lines[i].split(' ')[3] + ' ' + \
            lines[i].split(' ')[4] + ' ' + str(new_radii[i]) + ' ' + \
            str(parents[i]) + '\n')


if __name__ == "__main__":
    if len(sys.argv) != 3:
        print('SWC_SMOOTHER -- Written by Nathan Spencer 2016')
        print('Usage: python swc_smoother.py [path/to/swc/file.swc] [allowed change per node (i.e. 1.5)]')
    else:
        swc_smooth(sys.argv[1], float(sys.argv[2]))
