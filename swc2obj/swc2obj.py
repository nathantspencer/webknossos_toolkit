import sys

swc = open(sys.argv[1], 'r')
lines = swc.readlines()
lines_to_write = []
swc.close()

for line in lines:
    swc_components = line.split(' ')
    lines_to_write.append('v ' + swc_components[2] + ' ' + swc_components[3] + \
        ' ' + swc_components[4] + '\n')

obj = open(sys.argv[1][:-3] + 'obj', 'w')

for line in lines_to_write:
    obj.write(line)

obj.close()
