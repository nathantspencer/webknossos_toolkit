import sys
import code

def redraw(swc_path, adjacency_list, new_root):
	f = open(swc_path, 'r')
	lines = f.readlines()
	f.close()

	child_to_parent = {}
	child_to_parent[new_root] = '-1'
	discovered = []
	discovered.append(new_root)
	dfs_stack = []
	dfs_stack.append(new_root)

	while(dfs_stack):
		current_index = dfs_stack.pop()
		for i in adjacency_list[ current_index ]:
			if i not in discovered:
				discovered.append(i)
				dfs_stack.append(i)
				child_to_parent[i] = current_index

	f = open(swc_path[:-4] + '_cyclebroken.swc', 'w')

	code.interact(local=locals())

	for line in lines:
		f.write(index(line) + ' ' + line.split()[1] + ' ' + line.split()[2] + \
			' ' + line.split()[3] + ' ' + line.split()[4] + ' ' + line.split()[5] + \
			' ' + child_to_parent[index(line)] + '\n')

	f.close()

def adjacency_list(swc_path):
	f = open(swc_path, 'r')
	lines = f.readlines()
	f.close()

	adjacency_list = {}
	for line in lines:
		adjacency_list[index(line)] = []

	for line in lines:
		if (parent(line) != -1):
			adjacency_list[ parent(line) ].append( index(line) )
			adjacency_list[ index(line) ].append( parent(line) )

	return adjacency_list

def new_root(swc_path):
	f = open(swc_path, 'r')
	lines = f.readlines()
	f.close()

	# node with type 1 becomes new root
	for line in lines:
		if type_of(line) == '1':
			return index(line)

	# case where no root indicated by type
	return '-1'

def parent(line):
	return line.split()[6].strip()

def index(line):
	return line.split()[0]

def type_of(line):
	return line.split()[1]

if __name__ == "__main__":
	if len(sys.argv) != 2:
		print('\nSWC_CYCLEBREAKER -- Nathan Spencer 2017')
		print('Usage: python swc_cyclebreaker.py ["path/to/swc/file.swc"]')
	else:
		swc_path = sys.argv[1]
		root = new_root(swc_path)
		adj = adjacency_list(swc_path)
		redraw(swc_path, adj, root)
