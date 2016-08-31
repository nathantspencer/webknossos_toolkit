function success = trees_analysis(file_path)

addpath(genpath('./TREES1.15'))
success = false;
start_trees();
load_tree(file_path);
branchpoints = B_tree();
[sect, vect] = dissect_tree();

success = true;
save('vars');

