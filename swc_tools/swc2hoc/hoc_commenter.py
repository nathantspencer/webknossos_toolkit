import code
import sys
import re

def comment(swc_path):
	f = open(swc_path, 'r')
	swc_lines = f.readlines()
	section_kidindex = { 1 : 1 }
	section_prefix = { 1 : 'd1,' }
	f.close()

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

	# set some key variables, create working copy of hoc text
	comment_offset = 2
	pattern = "connect sections\[([0-9]+)\]\(0\), sections\[([0-9]+)\]\(1\)"
	swc_lines_output = []
	for line in swc_lines:
		swc_lines_output.append(line)

	# add comments to the remaining branches
	for ii, line in enumerate(swc_lines):
		if(ii > branch1_comment_index + 4):
			results = re.search(pattern, line)
			if results:

				# write comment line for branch
				current = int(results.group(1))
				parent = int(results.group(2))
				comment = "// " + section_prefix[parent] + str(section_kidindex[parent]) + "\n"
				swc_lines_output.insert(ii - comment_offset, comment)

				# update dictionaries and offset
				section_prefix[current] = comment[3:-1] + ','
				section_kidindex[parent] = section_kidindex[parent] + 1
				section_kidindex[current] = 1
				comment_offset = comment_offset - 1

	# save the updated hoc with the same path but altered name
	f = open(swc_path[:-4] + "_commented.hoc", 'w')
	for line in swc_lines_output:
		f.write(line)
	f.close()

if __name__ == "__main__":
	if len(sys.argv) != 2:
		print('\nhoc_commenter -- Written by Nathan Spencer 2016')
		print('Usage: python hoc_commenter.py "path/to/swc/file.swc"')
	else:
		comment(sys.argv[1])
