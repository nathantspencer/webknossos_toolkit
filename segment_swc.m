function [] = segment_swc(filePath)

start_trees();
swc_path = filePath;
swc_tree = load_tree(swc_path);
[sect, vec] = dissect_tree(swc_tree);
new_sect = sect(3:end,1:2);
bo = BO_tree(swc_tree)
save('segments.mat', 'new_sect', 'bo');