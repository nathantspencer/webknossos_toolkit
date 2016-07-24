import code
import glob

for file in glob.glob('swcs_to_correct/*.swc'):
    lines_to_write = []
    index_map = {'-1':-1}
    f = open(file, 'r')
    lines = f.readlines()
    f.close()
    n = 1
    for line in lines:
        index_map[line.split(' ')[0]] = n
        n += 1

    for line in lines:
        new_child = index_map[line.split(' ')[0]]
        line = line[len(line.split(' ')[0]):]
        line = str(new_child) + line
        lines_to_write.append(line)

    n = 0
    for line in lines_to_write:
        new_parent = index_map[(line.split(' ')[6])[:-1]]
        line = line[:-len(line.split(' ')[6])]
        line = line + str(new_parent)
        lines_to_write[n] = line
        n += 1

    f = open(file, 'w')
    for line in lines_to_write:
        f.write(line + '\n')
    f.close()
