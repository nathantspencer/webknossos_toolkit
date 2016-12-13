import numpy as np
import sys
import code
import scipy.io as sio
import re
import time
from operator import itemgetter

def reparent(swc_path, data, id):
	cur_id = id
	newparent = -1
	while cur_id != -1:
		line = data[cur_id - 1]
		oldparent = line['parent']
		line['parent'] = newparent
		newparent = cur_id
		cur_id = oldparent
	np.savetxt(swc_path[:-4] + '_reparent.swc', data, fmt="%d %d %.3f %.3f %.3f %.3f %d")

def comment(hoc_path):
	# read lines from hoc file, create dictionaries
	f = open(hoc_path, 'r')
	hoc_lines = f.readlines()
	section_kidindex = { 1 : 1 }
	section_prefix = { 1 : 'd1,' }
	f.close()

	# add comment line to indicate soma
	soma_comment_index = -1
	for ii, line in enumerate(hoc_lines):
		if line == "access sections[0]\n":
			soma_comment_index = ii - 1
			break
	hoc_lines.insert(soma_comment_index, '// soma\n')

	# add comment line to indicate first branch
	branch1_comment_index = -1
	for ii, line in enumerate(hoc_lines):
		if line == "access sections[1]\n":
			branch1_comment_index = ii - 1
			break
	hoc_lines.insert(branch1_comment_index, '\n// d1')

	# set some key variables, create working copy of hoc text
	comment_offset = 2
	pattern = "connect sections\[([0-9]+)\]\(0\), sections\[([0-9]+)\]\(1\)"
	hoc_lines_output = []
	for line in hoc_lines:
		hoc_lines_output.append(line)

	# add comments to the remaining branches
	for ii, line in enumerate(hoc_lines):
		if(ii > branch1_comment_index + 4):
			results = re.search(pattern, line)
			if results:

				# write comment line for branch
				current = int(results.group(1))
				parent = int(results.group(2))
				comment = "// " + section_prefix[parent] + str(section_kidindex[parent]) + "\n"
				hoc_lines_output.insert(ii - comment_offset, comment)

				# update dictionaries and offset
				section_prefix[current] = comment[3:-1] + ','
				section_kidindex[parent] = section_kidindex[parent] + 1
				section_kidindex[current] = 1
				comment_offset = comment_offset - 1

	# save the updated hoc with the same path but altered name
	f = open(hoc_path[:-4] + "_commented.hoc", 'w')
	for line in hoc_lines_output:
		f.write(line)
	f.close()

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
		index_map[line.split(' ')[0]] = n
		n += 1

	for line in lines:
		new_child = index_map[line.split(' ')[0]]
		line = line[len(line.split(' ')[0]):]
		line = str(new_child) + line
		lines_to_write.append(line)

	n = 0
	for line in lines_to_write:
		new_parent = index_map[(line.split(' ')[6]).strip()]
		line = line[:-len(line.split(' ')[6])]

		# correct nodes that reference themselves as parent; make root
		if(line.split(' ')[0] == str(new_parent)):
			new_parent = -1

		line = line + str(new_parent)
		lines_to_write[n] = line
		n += 1

	f = open(filePath[:-4] + '_corrected.swc', 'w')
	for line in lines_to_write:
		f.write(line + '\n')
	f.close()

# find and returns a list of tuples (beginning node id of section, end node id of section)
def sections(swc_path, data):
	f = open(swc_path, 'r')
	swc_lines = f.readlines()

	# create dict that maps node id to list of that node's children
	id_2_children = dict()
	for line in swc_lines:
		line.strip()
		current_line_id = int(line.split()[0])
		current_line_parent = int(line.split()[6])
		if (current_line_parent in id_2_children):
			id_2_children[current_line_parent].append(current_line_id)
		else:
			id_2_children[current_line_parent] = [current_line_id]

	# depth first search, start new section when branchpoint or endpoint is encountered
	dfs_stack = [(1,1)]
	bpoints = branchpoints(swc_path, data)
	segments = []

	while(dfs_stack):
		current_tuple = dfs_stack.pop()
		current_node = current_tuple[0]
		current_first = current_tuple[1]

		if((current_node in bpoints) or (not current_node in id_2_children)):
			current_segment = (current_first, current_node)
			segments.append((current_segment))
			current_first = current_node

		if current_node in id_2_children:
			for child in id_2_children[current_node]:
				dfs_stack.append((child, current_first))

	return sorted(segments, key=itemgetter(1))


# finds and returns list of branchpoints indices (1-indexed)
def branchpoints(swc_path, data):
	f = open(swc_path, 'r')
	swc_lines = f.readlines()

	has_child = []
	bpoints = []
	id_index = dict([(rec['id'], i) for i, rec in enumerate(data)])

	for line in swc_lines:
		line.strip()
		current_line_parent = line.split()[6]

		# has_child will contain nodes with 1 or more children
		# bpoints will contain nodes with 2 or more children
		if (int(current_line_parent) in bpoints):
			continue
		elif (current_line_parent in has_child):
			bpoints.append(int(current_line_parent))
		else:
			has_child.append(current_line_parent)

	return sorted(bpoints)


def write_hoc(swc_path, data):
	f = open(swc_path, 'r')
	swc_lines = f.readlines()

	secs = sections(swc_path, data)
	parent_list = []
	for x in range(len(secs)):
		parent_list.append(secs[x][1])

	f = open(swc_path[:-4] + '.hoc', 'w')
	f.write('objref soma\nsoma = new SectionList()\n')
	f.write('objref dendrite\ndendrite = new SectionList()\n\n')

	# First segment will be written as the soma section
	print('Writing .hoc file...')
	f.write('create sections[' + str(len(secs)) + ']\n')
	f.write('access sections[0]\n')
	f.write('soma.append()\nsections[0] {\n')

	r = range(secs[0][0], secs[0][1])

	f.write('  pt3dadd(')
	f.write(swc_lines[0].split(' ')[2] + ', ')
	f.write(swc_lines[0].split(' ')[3] + ', ')
	f.write(swc_lines[0].split(' ')[4] + ', ')
	f.write(swc_lines[0].split(' ')[5] + ')\n')
	f.write('}\n\n')

	print(secs)

	# All following sections are assumed to be dendrite sections
	for i in range(1, len(secs)):
		parent = parent_list.index(secs[i][0])
		f.write('access sections[' + str(i) + ']\n')
		f.write('dendrite.append()\n')
		f.write('connect sections[' + str(i) + '](0), sections[' + str(parent) + '](1)\n')
		f.write('sections[' + str(i) +'] {\n')

		for j in range(secs[i-1][1], secs[i][1]):
			f.write('  pt3dadd(')
			f.write(swc_lines[j].split(' ')[2] + ', ')
			f.write(swc_lines[j].split(' ')[3] + ', ')
			f.write(swc_lines[j].split(' ')[4] + ', ')
			f.write(swc_lines[j].split(' ')[5] + ')\n')
		f.write('}\n\n')

		# UNCOMMENT TO DEBUG JUMPS IN HOC
		#x_last = float(swc_lines[secs[i][0]].split(' ')[2])
		#y_last = float(swc_lines[secs[i][0]].split(' ')[3])
		#z_last = float(swc_lines[secs[i][0]].split(' ')[4])

		#x_next = float(swc_lines[secs[i-1][1]+1].split(' ')[2])
		#y_next = float(swc_lines[secs[i-1][1]+1].split(' ')[3])
		#z_next = float(swc_lines[secs[i-1][1]+1].split(' ')[4])

    	#distance = pow(pow(x_last-x_next, 2)+pow(y_last-y_next,2)+pow(z_last-z_next,2) , 0.5)
    	#if distance > 1:
    	#	print(str(i) + ': ' + str(distance))

	print(swc_path[:-4] + '.hoc')

def true_root(swc_path):
	f = open(swc_path, 'r')
	swc_lines = f.readlines()
	f.close()

	for ii, line in enumerate(swc_lines):
		if (line.split()[1] == '1'):
			return ii + 1
	return 0

# centers the swc around (0, 0, 0) in 3d space
def subtract_means(swc_path, data):
	f = open(swc_path, 'r')
	swc_lines = f.readlines()
	f.close()

	x_sum = 0
	y_sum = 0
	z_sum = 0

	# sum values of x, y, z to calculate mean
	for cur_id in range(len(swc_lines)):
		line = data[cur_id]
		x_sum = x_sum + line['x']
		y_sum = y_sum + line['y']
		z_sum = z_sum + line['z']

	x_mean = x_sum / len(swc_lines)
	y_mean = y_sum / len(swc_lines)
	z_mean = z_sum / len (swc_lines)

	# make another pass to subtract means
	for cur_id in range(len(swc_lines)):
		line = data[cur_id]
		line['x'] = line['x'] - x_mean
		line['y'] = line['y'] - y_mean
		line['z'] = line['z'] - z_mean

	np.savetxt(swc_path[:-4] + '_centered.swc', data, fmt="%d %d %.3f %.3f %.3f %.3f %d")

def main():
	# argument check
	if len(sys.argv) != 2:
		print('\nSWC2HOC.PY 2016');
		print('Usage: $ python swc2hoc.py [path/to/swc/file.swc]')
	else:
		start = time.time()
		swc_path = sys.argv[1]
		dtype = [('id', int), ('type', int), ('x', float), ('y', float), ('z', float), ('r', float), ('parent', int)]
		data = np.loadtxt(swc_path, dtype=dtype)

		# subtract means
		subtract_means(swc_path, data)
		swc_path = swc_path[:-4] + '_centered.swc'

		# correct order
		correct(swc_path)
		new_path = swc_path[:-4] + '_corrected.swc'

		# determine true root
		reparent_root = true_root(new_path)
		if(reparent_root == 0):
			print('ERROR: No soma found in swc')
		else:
			print('\nTrue root found at index ' + str(reparent_root))

		# reparent
		data = np.loadtxt(new_path, dtype=dtype)
		reparent(new_path, data, reparent_root)
		new_path = new_path[:-4] + '_reparent.swc'

		# make hoc code
		write_hoc(new_path, data)

		end = time.time()
		print("Finished in " + str(end - start) + " seconds\n")

if __name__ == "__main__":
	main()
