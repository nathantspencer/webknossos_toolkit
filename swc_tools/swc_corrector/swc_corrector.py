import sys
import code

def correct(filePath):
	lines_to_write = []
	index_map = {'-1':-1}
	f = open(filePath, 'r')
	lines = f.readlines()
	f.close()
	n = 1
	for line in lines:
		line = line.strip()
		lines[n-1] = line
		index_map[line.split()[0]] = n
		n += 1

	for line in lines:
		new_child = index_map[line.split()[0]]
		line = line[len(line.split()[0]):]
		line = str(new_child) + line
		lines_to_write.append(line)

	n = 0
	for line in lines_to_write:
		new_parent = index_map[(line.split()[6]).strip()]
		line = line[:-len(line.split()[6])]

		# correct nodes that reference themselves as parent; make root
		if(line.split()[0] == str(new_parent)):
			new_parent = -1

		line = line + str(new_parent)
		lines_to_write[n] = line
		n += 1

	f = open(filePath[:-4] + '_corrected.swc', 'w')
	for line in lines_to_write:
		f.write(line + '\n')
	f.close()

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print('\nSWC_CORRECTOR -- Nathan Spencer 2016')
        print('Usage: python swc_corrector.py ["path/to/swc/file.swc"]')
    else:
        correct(sys.argv[1])
