import code
import sys
import re
import scipy.io as sio
import numpy

# Read lines from file
swc_to_segment = sys.argv[1]
f = open(swc_to_segment, 'r')
lines = f.readlines()
f.close()

data = sio.loadmat('segments')

code.interact(local=locals())

depth = dict()

f = open(swc_to_segment[:-4] + '_segmented', 'a')
start_node = str(data['new_sect'][0,0])
end_node = str(data['new_sect'][0,1])
lines_to_write = []
current_node = end_node
while(current_node != start_node):
    lines_to_write.insert(0, lines[current_node])
    parent = str((lines[current_node].split(' ')[6])[:-1])
    current_node = parent
lines_to_write.insert(0, '# Connection to cell body')
lines_to_write.append('\n')
first_end_node = end_node
f.write(lines_to_write)
lines_to_write = []
while(end_node in data['new_sect'][:,0]):
    iterator_count = 0
    starts_at_current_endpoint = []
    for x in data['new_sect'][:,0]:
        if x == current_endpoint:
            starts_at_current_endpoint.append(x)

    # for each branchpoint that starts at the current endpoint (keep iterator count)
    for sub_branch in starts_at_current_endpoint:
        iterator_count += 1

    # write the body of the segment and then write a header


    # to write the header, check to see if the startpoint is the firstendpoint
    # if so, then write d and then the iterator count
    # if not, grab startpoint from dictionary, append iteratorcount
    # add appended iterator to dictionary under current endpoint
