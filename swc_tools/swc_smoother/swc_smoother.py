import sys

def swc_smooth(swc_file, allowable_change):

    f = open(swc_file, 'r')
    lines = f.readlines()
    f.close()
    radii = {}
    parents = {}
    xs = {}
    ys = {}
    zs = {}
    for line in lines:
        radii[int(line.split(' ')[0])] = float(line.split(' ')[5].strip())
        #print line.split(' ')[0]
        parents[int(line.split(' ')[0])] = int(line.split(' ')[6].strip())
        xs[int(line.split(' ')[0])] = float(line.split(' ')[2].strip())
        ys[int(line.split(' ')[0])] = float(line.split(' ')[3].strip())
        zs[int(line.split(' ')[0])] = float(line.split(' ')[4].strip())

    count = 4
    while count > 3:
        count = 0
        for each in radii.keys():
            if parents[each] == -1:
                continue

            parent = parents[each]
            radchild = radii[each]
            raddad = radii[parent]
            if raddad == 0 or radchild == 0:
                continue
            if ((radchild /raddad) > allowable_change):
                radii[each] = raddad * allowable_change
                count += 1
            if (raddad/radchild) > allowable_change:
                radii[each] = raddad / allowable_change
                count += 1
        print "count: "  + str(count)



    f = open(swc_file[:-4] + '_smooth.swc', 'w')

    for i in radii.keys():
        print i
        #code.interact(local=locals())
        f.write(str(i) + ' 3 ' + str(xs[i]) + ' ' + str(ys[i]) + ' ' + str(zs[i]) + ' ' + \
            str(radii[i]) + ' ' + str(parents[i]) + '\n')


if __name__ == "__main__":
    if len(sys.argv) != 3:
        print('SWC_SMOOTHER -- Written by Nathan Spencer 2016')
        print('Usage: python swc_smoother.py [path/to/swc/file.swc] [allowed change per node (i.e. 1.5)]')
    else:
        swc_smooth(sys.argv[1], float(sys.argv[2]))
