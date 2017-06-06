import sys

def index_of(line):
	return line.split()[0]

def type_of(line):
	return line.split()[1]

def x_of(line):
	return line.split()[2]

def y_of(line):
    return line.split()[3]

def z_of(line):
    return line.split()[4]

def radius_of(line):
    return line.split()[5]

def parent_of(line):
    return line.split()[6]

def offset(swc_path, x_offset, y_offset, z_offset):
    f = open(swc_path, 'r')
    lines = f.readlines()
    lines_to_write = []
    f.close()

    for line in lines:
        line.strip()

        new_index = index_of(line) + ' '
        new_type = type_of(line) + ' '
        new_radius = radius_of(line) + ' '
        new_parent = parent_of(line) + '\n'

        new_x = str(float(x_of(line)) + x_offset) + ' '
        new_y = str(float(y_of(line)) + y_offset) + ' '
        new_z = str(float(z_of(line)) + z_offset) + ' '

        line_to_write = new_index + new_type + new_x + new_y + new_z + new_radius + new_parent
        lines_to_write.append(line_to_write)

    f = open(swc_path[:-4] + '_offset.swc', 'w')
    for line in lines_to_write:
        f.write(line)
    f.close()

if __name__ == "__main__":
    if len(sys.argv) != 5:
        print('\nSWC_OFFSET -- Written by Nathan Spencer 2017')
        print('Usage: python swc_offset.py ["path/to/swc/file.swc"] [float x-offset] [float y-offset] [float z-offset]')
    else:
        swc_file = sys.argv[1]
        x_offset = float(sys.argv[2])
        y_offset = float(sys.argv[3])
        z_offset = float(sys.argv[4])
        offset(swc_file, x_offset, y_offset, z_offset)
