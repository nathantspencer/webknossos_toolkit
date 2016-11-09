import sys
import code

def comment(swc_path):
	f = open(swc_path, 'r')
	swc_lines = f.readlines()

	# add comment line to indicate soma
	soma_comment_index = -1
	for ii, line in enumerate(swc_lines):
		if line == "access sections[0]\n":
			soma_comment_index = ii - 1
			break
	swc_lines.insert(soma_comment_index, '// soma\n')

	# add comment line to indicate first branch
	branch1_comment_index = -1
	for ii, line in enumerate(swc_lines):
		if line == "access sections[1]\n":
			branch1_comment_index = ii - 1
			break
	swc_lines.insert(branch1_comment_index, '\n// d1')

	# save the updated hoc with the same path but altered name
	f = open(swc_path[:-4] + "_commented.hoc", 'w')
	for line in swc_lines:
		f.write(line)
	f.close()

if __name__ == "__main__":
	if len(sys.argv) != 2:
		print('\nhoc_commenter -- Written by Nathan Spencer 2016')
		print('Usage: python hoc_commenter.py "path/to/swc/file.swc"')
	else:
		comment(sys.argv[1])
