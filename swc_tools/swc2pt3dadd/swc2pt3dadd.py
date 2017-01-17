import sys

def x_of(line):
	return line.split()[2]

def y_of(line):
    return line.split()[3]

def z_of(line):
    return line.split()[4]

def radius_of(line):
    return line.split()[5]

def pt3dadd(swc_path):
    f = open(swc_path, 'r')
    lines = f.readlines()
    lines_to_write = []
    f.close()

    for line in lines:
        line.strip()

        x = x_of(line)
        y = y_of(line)
        z = z_of(line)
        radius = radius_of(line)

        line_to_write = '  pt3dadd(' + x + ', ' + y + ', ' + z + ', ' + radius + ')\n'
        lines_to_write.append(line_to_write)

    f = open(swc_path[:-4] + '_pt3dadd.swc', 'w')
    for line in lines_to_write:
        f.write(line)
    f.close()

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print('\nSWC2PT3DADD -- Written by Nathan Spencer 2017')
        print('Usage: python swc2pt3dadd.py ["path/to/swc/file.swc"]')
    else:
        swc_file = sys.argv[1]
        pt3dadd(swc_file)
