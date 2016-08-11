

# Placeholder
x_upper = 5000.0
x_lower = 3000.0

# Placeholder
y_upper = 5000.0
y_lower = 3000.0

# Placeholder
z_upper = 5000.0
z_lower = 3000.0

# Placeholder
obj_path = "D:\\nathan\webknossos_toolkit\\nml_tools\swc_corrector\swcs_to_correct\VCN_c19_Dendrite01.obj"
obj_file = open(obj_path, "r");

lines = []
for line in obj_file.readlines():
    lines.append(line)

obj_file.close()

new_lines = []
for line in lines:
    split_line = line.split(' ')
    violates_x = float(split_line[1]) > x_upper or float(split_line[1]) < x_lower
    violates_y = float(split_line[2]) > y_upper or float(split_line[2]) < y_lower
    violates_z = float(split_line[3]) > z_upper or float(split_line[3]) < z_lower
    if not violates_x and not violates_y and not violates_z:
        new_lines.append(line)

obj_file = open(obj_path, "w")

for line in new_lines:
    obj_file.write(line)

obj_file.close()

print('Success!')
