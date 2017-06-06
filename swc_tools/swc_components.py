import sys

def components(swc_path):

	f = open(swc_path, 'r')
	lines = f.readlines()
	f.close()

	# make a map from parent to child, determine number of components
	root_indices = []
	parent_to_child = {}
	index_to_type = {}

	for line in lines:
		parent = line.split()[0]

		# check for a root node
		if line.split()[6].strip() == '-1':
			root_indices.append( line.split()[0] )

		# look for some children
		for sub_line in lines:
			if sub_line.split()[6].strip() == parent:
				if parent not in parent_to_child:
					parent_to_child[ parent ] = []
				parent_to_child[ parent ].append( sub_line.split()[0].strip() )

	# dfs to set color of each connected component
	for ii, _ in enumerate(root_indices):
		dfs(ii, root_indices, index_to_type, parent_to_child)

	f = open(swc_path[:-4] + '_components.swc', 'w')

	for line in lines:
		if line.split()[0] in index_to_type:
			f.write(str(line.split()[0]) + ' ' + str(index_to_type[ line.split()[0] ]) + ' ' + str(line.split()[2]) + \
				' ' + str(line.split()[3]) + ' ' + str(line.split()[4]) + ' ' + str(line.split()[5]) + \
				' ' + str(line.split()[6].strip()) + '\n')
	f.close()


def dfs(index, root_indices, index_to_type, parent_to_child):
	dfs_stack = []
	current_index = root_indices[index]
	dfs_stack.append(current_index)

	while dfs_stack:
		current_index = dfs_stack.pop()
		index_to_type[current_index] = index;
		if current_index in parent_to_child:
			for j in parent_to_child[current_index]:
				dfs_stack.append(j)


if __name__ == "__main__":
	if len(sys.argv) != 2:
		print('\nSWC_COMPONENTS -- Nathan Spencer 2017')
		print('Usage: python swc_components.py ["path/to/swc/file.swc"]')
	else:
		components(sys.argv[1])
