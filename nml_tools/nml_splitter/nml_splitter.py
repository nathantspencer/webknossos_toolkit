import re
import sys

parameters_flag = False
thing_flag = False
comments_flag = False

number_of_skeletons = 0

files_to_write = []
files_to_parse = []
nodes_in_thing = []
comment_nodes = []
comments = []
parameters_lines = ['<things>\n']

# Record arguments as files to parse
for arg in sys.argv[1:]:
    files_to_parse.append(arg)

# For each file passed as an argument...
for file_to_parse in files_to_parse:
    f_read = open(file_to_parse, 'r')
    line = '\n'

    # Until end of file is reached
    while line != '':
        line = f_read.readline()

        # Check for flag activation
        if '<parameters>' in line:
            parameters_flag = True
        elif '<thing' in line and '<things>' not in line:
            thing_flag = True
            files_to_write.append(open(file_to_parse[:-4] + str(number_of_skeletons+1) + '.nml', 'w'))
            nodes_in_thing.append(0)
            number_of_skeletons += 1
            for parameters_line in parameters_lines:
                files_to_write[number_of_skeletons-1].write(parameters_line)
        elif '<comments>' in line:
            comments_flag = True

        # Count nodes in each thing
        if '</node>' in line:
            nodes_in_thing[number_of_skeletons-1] += 1

        # Record parameter lines
        if parameters_flag:
            parameters_lines.append(line)
        if thing_flag:
            files_to_write[number_of_skeletons-1].write(line)
        if comments_flag and '<comments>' not in line and '</comments>' not in line:
            m = re.match('[ ]+<comment node="([1-9a-zA-z]+)" content="([1-9a-zA-z]+)"/>', line)
            comment_nodes.append(int(m.group(1)))
            comments.append(m.group(2))

        # Check for flag deactivation
        if '</parameters>' in line:
            parameters_flag = False
        elif '</thing>' in line:
            thing_flag = False
        elif '</comments>' in line:
            comments_flag = False
            i = 0
            node_min = 1
            node_max = 1
            for file_to_write in files_to_write:
                file_to_write.write('  <branchpoints>\n  </branchpoints>\n  <comments>\n')

                node_max += nodes_in_thing[i]
                j = 0
                for comment_node in comment_nodes:
                    if node_min < comment_node <= node_max:
                        file_to_write.write('  <comment node="' + str(comment_node) + '" content="' + \
                                            comments[j] + '"/>\n')
                    j += 1

                file_to_write.write('  </comments>\n</things>')
                file_to_write.close()
                node_min += nodes_in_thing[i]
                i += 1
