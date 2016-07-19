import code
import sys
import re

# Read lines from file
swc_to_segment = sys.argv[1]
f = open(swc_to_segment, 'r')
lines = f.readlines()
f.close()

code.interact(local=locals())

# Start from -1, use depth first search
endReached = False
currentParent = -1
branch_stack = []
current_segment = []


while not endReached:
    childCount = 0
    for line in lines:
        if re.search(r"( [0-9]+\n)").group(0) == str(currentParent):
            branch_stack.append(line.split(' ')[0])
            childCount += 1

    if len(branch_stack) == 0:
        endReached = True
    elif childCount == 1:
        current_segment.append(line.split(' ')[0])
    elif childCount > 1
