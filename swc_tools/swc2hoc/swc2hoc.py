import numpy as np
import sys
import code
import scipy.io as sio
import re
import os
import time
import warnings
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

def comment(hoc_path, soma_size):
	# read lines from hoc file, create dictionaries
	f = open(hoc_path, 'r')
	hoc_lines = f.readlines()
	section_kidindex = { 0 : 1, 1 : 1 }
	section_prefix = { 0 : '' }
	f.close()

	# add comment line to indicate soma
	soma_comment_index = -1
	for ii, line in enumerate(hoc_lines):
		if line == "access sections[0]\n":
			soma_comment_index = ii - 1
			break
	hoc_lines.insert(soma_comment_index, '// soma\n')

	# set some key variables, create working copy of hoc text
	comment_offset = 2
	pattern = "connect sections\[([0-9]+)\]\(0\), sections\[([0-9]+)\]\(1\)"
	hoc_lines_output = []
	for line in hoc_lines:
		hoc_lines_output.append(line)

	# add comments to the remaining branches
	for ii, line in enumerate(hoc_lines):
		if(ii > 10 + soma_size):
			results = re.search(pattern, line)
			if results:

				# write comment line for branch
				current = int(results.group(1))
				parent = int(results.group(2))
				comment = "// d" + section_prefix[parent] + str(section_kidindex[parent]) + "\n"
				hoc_lines_output.insert(ii - comment_offset, comment)

				# update dictionaries and offset
				section_prefix[current] = comment[4:-1] + ','
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

		if((current_node in bpoints) or (current_node not in id_2_children)):
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

# writes hoc code from swc
def write_hoc(swc_path, soma_path, data):
	f = open(swc_path, 'r')
	swc_lines = f.readlines()

	secs = sections(swc_path, data)
	parent_list = []
	for x in range(len(secs)):
		parent_list.append(secs[x][1])

	f.close()

	f = open(soma_path, 'r')
	soma_lines = f.readlines()
	f.close()

	f = open(swc_path[:-4] + '.hoc', 'w')
	f.write('objref soma\nsoma = new SectionList()\n')
	f.write('objref dendrite\ndendrite = new SectionList()\n\n')

	# First segment will be written as the soma section using the soma swc
	print('Writing .hoc file...')
	f.write('create sections[' + str(len(secs)) + ']\n')
	f.write('access sections[0]\n')
	f.write('soma.append()\nsections[0] {\n')

	for line in soma_lines:
		f.write('  pt3dadd(')
		f.write(line.strip().split()[2] + ', ')
		f.write(line.strip().split()[3] + ', ')
		f.write(line.strip().split()[4] + ', ')
		f.write(str(int(line.strip().split()[5])*2) + ')\n')
	f.write('}\n\n')

	# All following sections are assumed to be dendrite sections
	for i in range(1, len(secs)):
		if secs[i][0] == 1:
			parent = 0
		else:
			parent = parent_list.index(secs[i][0])
		f.write('access sections[' + str(i) + ']\n')
		f.write('dendrite.append()\n')
		f.write('connect sections[' + str(i) + '](0), sections[' + str(parent) + '](1)\n')
		f.write('sections[' + str(i) +'] {\n')

		# Create list of nodes included in current section
		included_nodes = []
		next_node = secs[i][1]
		while(next_node != secs[i][0]):
			included_nodes.append(next_node-1)
			next_node = int(swc_lines[next_node-1].split()[6])

		# Build list of parents in the current range
		current_parents = []
		for j in included_nodes:
			current_parents.append(swc_lines[j].split()[6])

		# Build map from parents to children, use -1 if no child in the current range
		parent_to_child = {}
		for j in included_nodes:
			current_parent = swc_lines[j].split()[6]
			current_child  = swc_lines[j].split()[0]
			parent_to_child[current_parent] = current_child
			if current_child not in current_parents:
				parent_to_child[current_child] = -1

			# Marks the node where we should start writing this section
			if int(current_parent) == secs[i][0]:
				start_node = int(swc_lines[j].split()[0])

		# The first node will be missed by section of length zero (1,1)
		# We will add it manually here
		if len(included_nodes) == 0:
			start_node = 1
			included_nodes.append('1')
			parent_to_child['1'] = '-1'

		# Starting from start_node, traverse and write points
		current_node = start_node
		if secs[i][0] == 1:
			radius = float(swc_lines[0].split()[5])
			diameter = radius * 2
			f.write('  pt3dadd(')
			f.write(swc_lines[0].split()[2] + ', ')
			f.write(swc_lines[0].split()[3] + ', ')
			f.write(swc_lines[0].split()[4] + ', ')
			f.write(str(diameter) + ')\n')
		while(current_node != -1):
			radius = float(swc_lines[current_node - 1].split()[5])
			diameter = radius * 2
			f.write('  pt3dadd(')
			f.write(swc_lines[current_node - 1].split()[2] + ', ')
			f.write(swc_lines[current_node - 1].split()[3] + ', ')
			f.write(swc_lines[current_node - 1].split()[4] + ', ')
			f.write(str(diameter) + ')\n')
			current_node = int(parent_to_child[str(current_node)])
		f.write('}\n\n')
	f.close()

# check to make sure there is exactly one node with parent -1
def validate(swc_path):
	f = open(swc_path, 'r')
	lines = f.readlines()
	f.close()

	numRoots = 0
	for line in lines:
		if line.strip().split()[6] == '-1':
			numRoots = numRoots + 1

	if numRoots == 0:
		print('\nWARNING: Your dendrite skeleton contains a loop and has no root. That is catastrophically bad news.\n')
	elif numRoots > 1:
		print('\nWARNING: Your dendrite skeleton has multiple roots. Results of this script are likely garbage.\n')
	return 0

# determine the true root using the node marked as "soma" type
def true_root(swc_path):
	f = open(swc_path, 'r')
	swc_lines = f.readlines()
	f.close()

	for ii, line in enumerate(swc_lines):
		if (line.split()[1] == '1'):
			return ii + 1
	return 0

# centers the swc around (0, 0, 0) in 3d space
def subtract_means(swc_path, soma_path, data, soma_data):
	f = open(swc_path, 'r')
	swc_lines = f.readlines()
	f.close()

	f = open(soma_path, 'r')
	soma_lines = f.readlines()
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

	for cur_id in range(len(soma_lines)):
		line = soma_data[cur_id]
		x_sum = x_sum + line['x']
		y_sum = y_sum + line['y']
		z_sum = z_sum + line['z']

	x_mean = x_sum / (len(swc_lines) + len(soma_lines))
	y_mean = y_sum / (len(swc_lines) + len(soma_lines))
	z_mean = z_sum / (len (swc_lines) + len(soma_lines))

	print("X MEAN: " + str(x_mean))
	print("Y MEAN: " + str(y_mean))
	print("Z MEAN: " + str(z_mean))

	# make another pass to subtract means
	for cur_id in range(len(swc_lines)):
		line = data[cur_id]
		line['x'] = line['x'] - x_mean
		line['y'] = line['y'] - y_mean
		line['z'] = line['z'] - z_mean
	for cur_id in range(len(soma_lines)):
		line = soma_data[cur_id]
		line['x'] = line['x'] - x_mean
		line['y'] = line['y'] - y_mean
		line['z'] = line['z'] - z_mean

	np.savetxt(swc_path[:-4] + '_centered.swc', data, fmt="%d %d %.3f %.3f %.3f %.3f %d")
	np.savetxt(soma_path[:-4] + '_centered.swc', soma_data, fmt="%d %d %.3f %.3f %.3f %.3f %d")

# reorders hoc sections by the parent they belong to
def reorder_hoc(hoc_path, soma_size):
	f = open(hoc_path, 'r')
	hoc_lines = f.readlines()
	output_lines = []
	f.close()

	capture_flag = False
	current_section_lines = []
	current_section_number = 0
	section_list = []

	for ii, line in enumerate(hoc_lines):
		if ii > 10 + soma_size:
			# if we're in 'capture mode', keep capturing lines until the end of the section
			if capture_flag:
				current_section_lines.append(line)
				if str(line[0]) == '}':
					capture_flag = False

					# we add a tuple that links the section number to the lines
					# it contains and also to the section index of its parent
					pattern = "connect sections\[([0-9]+)\]\(0\), sections\[([0-9]+)\]\(1\)"
					results = re.search(pattern, current_section_lines[2])
					section_list.append((current_section_number, current_section_lines, int(results.group(2))))
					current_section_lines = []

			# when we find the start of the next section, start capturing lines
			elif line[0:6] == 'access':
				current_section_lines.append(line)
				current_section_number = current_section_number + 1
				capture_flag = True

	section_list = sorted(section_list, key=lambda item: item[2])

	# set the output lines for writing to new file
	for i in range(10 + soma_size):
		output_lines.append(hoc_lines[i])
	for section in section_list:
		output_lines.append('\n')
		for line in section[1]:
			output_lines.append(line)

	f = open(hoc_path[:-4] + '_reordered.hoc', 'w')
	for line in output_lines:
		f.write(line)
	f.close()

def main():
	# argument check
	if len(sys.argv) != 3:
		print('\nSWC2HOC.PY 2016');
		print('Usage: $ python swc2hoc.py [dendriteSkeleton.swc] [somaSkeleton.swc]')
	else:
		start = time.time()
		swc_path = sys.argv[1]
		soma_path = sys.argv[2]
		dtype = [('id', int), ('type', int), ('x', float), ('y', float), ('z', float), ('r', float), ('parent', int)]
		data = np.loadtxt(swc_path, dtype=dtype)
		soma_data = np.loadtxt(soma_path, dtype=dtype)

		f = open(soma_path, 'r')
		linus = f.readlines()
		soma_size = len(linus)

		# subtract means
		subtract_means(swc_path, soma_path, data, soma_data)
		new_path = swc_path[:-4] + '_centered.swc'
		new_soma_path = soma_path[:-4] + '_centered.swc'

		# correct order
		correct(new_path)
		correct(new_soma_path)
		new_path = new_path[:-4] + '_corrected.swc'
		new_soma_path = new_soma_path[:-4] + '_corrected.swc'

		# determine true root
		reparent_root = true_root(new_path)
		soma_reparent_root = true_root(new_soma_path)
		if(reparent_root == 0):
			print('\nWARNING: The root of your dendrite must have type soma (1). This might go poorly.\n')
		else:
			print('\nDendrite true root found at index ' + str(reparent_root) + '!')
		if(soma_reparent_root == 0):
			print('\nWARNING: The root of your soma must have type soma (1). This might go poorly.\n')
		else:
			print('\nSoma true root found at index ' + str(soma_reparent_root) + '!')

		# reparent
		data = np.loadtxt(new_path, dtype=dtype)
		reparent(new_path, data, reparent_root)
		new_path = new_path[:-4] + '_reparent.swc'

		soma_data = np.loadtxt(new_soma_path, dtype=dtype)
		reparent(new_soma_path, soma_data, soma_reparent_root)
		new_soma_path = new_soma_path[:-4] + '_reparent.swc'

		# make sure things look kosher with the swc file
		validate(new_path)

		# make hoc code
		write_hoc(new_path, new_soma_path, data)

		# reorder
		reorder_hoc(new_path[:-4] + '.hoc', soma_size)
		new_path = new_path[:-4]  + '_reordered.hoc'

		# comment
		comment(new_path[:-4] + '_saved.hoc', soma_size)

		# delete temporary intermediate files
		os.remove(soma_path[:-4] + '_centered.swc')
		os.remove(soma_path[:-4] + '_centered_corrected.swc')
		os.remove(soma_path[:-4] + '_centered_corrected_reparent.swc')
		os.remove(swc_path[:-4] + '_centered.swc')
		os.remove(swc_path[:-4] + '_centered_corrected.swc')
		os.remove(swc_path[:-4] + '_centered_corrected_reparent.swc')
		os.remove(swc_path[:-4] + '_centered_corrected_reparent.hoc')
		os.rename(swc_path[:-4] + '_centered_corrected_reparent_reordered_saved.hoc', swc_path[:-4] + '.hoc')
		os.rename(swc_path[:-4] + '_centered_corrected_reparent_reordered_saved_commented.hoc', swc_path[:-4] + '_commented.hoc')

		end = time.time()
		print("Finished in " + str(end - start) + " seconds.\n")

if __name__ == "__main__":
	main()
