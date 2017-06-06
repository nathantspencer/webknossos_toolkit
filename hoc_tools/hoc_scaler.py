import sys
import re

def scale(hoc_path, x_multiplier, y_multiplier, z_multiplier, d_multiplier):
	pattern = 'pt3dadd\(([-0-9\.]+), ([-0-9\.]+), ([-0-9\.]+), ([0-9\.]+)\)\n'
	f = open(hoc_path, 'r')
	lines = f.readlines()
	f.close()
	out_lines = []

	for line in lines:
		out_lines.append(line)

	for i, line in enumerate(lines):
		result = re.search(pattern, line)
		if result:
			x = str(float(result.group(1)) * float(x_multiplier))
			y = str(float(result.group(2)) * float(y_multiplier))
			z = str(float(result.group(3)) * float(z_multiplier))
			d = str(float(result.group(4)) * float(d_multiplier))
			out_lines[i] = '  pt3dadd(' + x + ', ' + y + ', ' + z + ', ' + d + ')\n'

	f = open(hoc_path[:-4] + '_scaled.hoc', 'w')
	for line in out_lines:
		f.write(line)
	f.close()

if __name__ == '__main__':
	if len(sys.argv) != 6:
	    print('\nSWC_CENTER -- Written by Nathan Spencer 2016')
	    print('Usage: python hoc_scaler.py [path/to/hoc/file.hoc] [x-multiplier] [y-multiplier] [z-multiplier] [d-multiplier]')
	else:
		scale(sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4], sys.argv[5])
