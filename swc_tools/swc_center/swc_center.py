import sys

def center(swc_path):

    f = open(swc_path, 'r')
    lines = f.readlines()
    f.close()
    radii = {}
    parents = {}
    xs = {}
    ys = {}
    zs = {}
    x_avg = 0
    y_avg = 0
    z_avg = 0

    for line in lines:
        radii[int(line.split(' ')[0])] = float(line.split(' ')[5].strip())
        parents[int(line.split(' ')[0])] = int(line.split(' ')[6].strip())
        xs[int(line.split(' ')[0])] = float(line.split(' ')[2].strip())
        ys[int(line.split(' ')[0])] = float(line.split(' ')[3].strip())
        zs[int(line.split(' ')[0])] = float(line.split(' ')[4].strip())
        x_avg += xs[int(line.split(' ')[0])]
        y_avg += ys[int(line.split(' ')[0])]
        z_avg += zs[int(line.split(' ')[0])]
    x_avg /= len(xs)
    y_avg /= len(ys)
    z_avg /= len(zs)

    f = open(swc_path[:-4] + '_centered.swc', 'w')

    for i in radii.keys():
        print i
        f.write(str(i) + ' 3 ' + str(xs[i] - x_avg) + ' ' + str(ys[i] - y_avg) + ' ' + str(zs[i]-z_avg) + ' ' + \
            str(radii[i]) + ' ' + str(parents[i]) + '\n')


if __name__ == "__main__":
    if len(sys.argv) != 2:
        print('\nSWC_CENTER -- Written by Nathan Spencer 2016')
        print('Usage: python swc_center.py "path/to/swc/file.swc"')
    else:
        center(sys.argv[1])
