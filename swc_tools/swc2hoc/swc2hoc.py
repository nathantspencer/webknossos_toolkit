import matlab.engine
import numpy as np
import sys
import code
import scipy.io as sio
import re

def reparent(data, id):

	id_index = dict([(rec['id'], i) for i, rec in enumerate(data)])
	newparent = -1
	while id != -1:
		rec = data[id_index[id]]
		oldparent = rec['parent']
		rec['parent'] = newparent
		newparent = id
		id = oldparent

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

def correct(file):
	lines_to_write = []
	index_map = {'-1':-1}
	f = open(file, 'r')
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
		line = line + str(new_parent)
		lines_to_write[n] = line
		n += 1

	f = open(file, 'w')
	for line in lines_to_write:
		f.write(line + '\n')
	f.close()

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
		#	 print(str(i) + ': ' + str(distance))

		for j in range(sections[i-1][1], sections[i][1]):
			f.write('  pt3dadd(')
			f.write(swc_lines[j].split(' ')[2] + ', ')
			f.write(swc_lines[j].split(' ')[3] + ', ')
			f.write(swc_lines[j].split(' ')[4] + ', ')
			f.write(swc_lines[j].split(' ')[5] + ')\n')
		f.write('}\n\n')

	print(swc_path[:-4] + '.hoc')

def true_root(swc_path):

	f = open(swc_path, 'r')
	swc_lines = f.readlines()

	for ii, line in enumerate(swc_lines):
		if (line.split()[1] == '1'):
			return ii + 1
	return 0

if __name__ == "__main__":
	# argument check
	if len(sys.argv) != 2:
		print('\nSWC2HOC.PY 2016');
		print('Usage: $ python swc2hoc.py "path/to/swc/file.swc"')
	else:
		swc_path = sys.argv[1]

		# correct order
		correct(swc_path)

		# determine true root
		reparent_root = true_root(swc_path)
		if(reparent_root == 0):
			print('ERROR: No soma found in swc')
		else:
			print('True root found at index ' + str(reparent_root))

		# reparent
		dtype = [('id', int), ('type', int), ('x', float), ('y', float), ('z', float), ('r', float), ('parent', int)]
		data = np.loadtxt(swc_path, dtype=dtype)
		reparent(data, reparent_root)
		np.savetxt(swc_path, data, fmt="%d %d %.3f %.3f %.3f %.3f %d")

		code.interact(local=locals())

		# make hoc code
		write_hoc(swc_path)

		code.interact(local=locals())

		# comment
		comment(swc_path[:-4] + '.hoc')
