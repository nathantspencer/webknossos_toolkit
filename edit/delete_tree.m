% DELETE_TREE   Delete nodes from a tree.
% (trees package)
%
% tree = delete_tree (intree, inodes, options)
% --------------------------------------------
%
% deletes a node in a tree. Trifurcation occurs when deleting any branching
% point following directly another branch point. Region numbers are changed
% and region name array is trimmed.
% Alters the topology! Root deletion can lead to unexpected results!
%
% Input
% -----
% - intree::integer: index of tree in trees or structured tree
% - inodes::vector: node indices {DEFAULT: last node}
% - options::string: {DEFAULT: ''}
%     '-s' : show
%     '-w' : waitbar
%     '-r' : do not trim regions array
%
% Output
% ------
% if no output is declared the tree is changed in trees
% - tree:: structured output tree
%
% Example
% -------
% delete_tree (sample_tree, 5:2:8, '-s')
%
% See also insert_tree cat_tree
% Uses idpar_tree dA
%
% the TREES toolbox: edit, visualize and analyze neuronal trees
% Copyright (C) 2009  Hermann Cuntz

function varargout = delete_tree (intree, inodes, options)

% trees : contains the tree structures in the trees package
global trees

if (nargin < 1)||isempty(intree),
    intree = length (trees); % {DEFAULT tree: last tree in trees cell array}
end;

ver_tree (intree); % verify that input is a tree structure

% use full tree for this function
if ~isstruct(intree),
    tree = trees {intree};
else
    tree = intree;
end

dA = tree.dA;      % directed adjacency matrix of tree
N  = size (dA, 1); % number of nodes in tree

if (nargin < 2)||isempty(inodes),
    inodes = N; % {DEFAULT: delete last node}
end
if size(inodes,1) == N,
    % all nodes are deleted, return empty vector:
    if (nargout == 1)||(isstruct(intree)),
        varargout{1} = [];
    else
        trees{intree} = [];
    end
    return
end

if (nargin < 3)||isempty(options),
    options = ''; % {DEFAULT: no option}
end

% nodes get deleted one by one, therefore new index has to be calculated
% each time, using sindex:
sindex = 1 : N;

if strfind (options, '-w'), % waitbar option: initialization
    HW = waitbar (0, 'deleting nodes...');
    set (HW, 'Name', '..PLEASE..WAIT..YEAH..');
end
for ward = 1 : length (inodes)
    if strfind (options, '-w'), % waitbar option: update
        if mod(ward,500) == 0,
            waitbar (ward/length(inodes), HW);
        end
    end
    % find the node index corresponding to the pruned tree:
    inode = find (inodes (ward) == sindex);
    % delete this node from the index list
    sindex (inode) = [];
    % find the column in dA corresponding to this node
    ydA = dA (:, inode);
    % this column contains ones at the node's child indices
    % find the parent index to inode
    idpar = find (dA (inode, :));
    if ~isempty (idpar),
        % if it is not root then add inode's children to inode's parent
        dA (:,idpar) = dA (:,idpar) + ydA;
    end
    % get rid of the node in the adjacency matrix by eliminating row and
    % column inode.
    dA (:, inode) = [];
    dA (inode, :) = [];
end
if strfind (options, '-w'), % waitbar option: close
    close(HW);
end
tree.dA = dA;

% shorten all vectors of form Nx1
S = fieldnames (tree);
for ward = 1 : length(S),
    if ~strcmp(S{ward},'dA'),
        vec = tree.(S{ward});
        if isvector(vec) && (numel(vec) == N),
            tree.(S{ward})(inodes) = [];
        end
    end
end

% eliminate obsolete regions
if isempty (strfind (options, '-r')),
    if isfield (tree, 'R'),
        [i1 i2 i3] = unique (tree.R);
        tree.R = i3;
        if isfield (tree, 'rnames'),
            tree.rnames = {tree.rnames{i3(i2)}};
        end
    end
end

if strfind (options, '-s'),
    clf; shine; hold on; plot_tree (intree);
    plot_tree (tree, [0 1 0], 100);
    HP(1) = plot (1, 1, 'k-'); HP(2) = plot (1, 1, 'g-');
    legend (HP, {'original tree', 'trimmed tree'}); set (HP, 'visible', 'off');
    title ('find the differences: delete nodes in tree');
    xlabel ('x [\mum]'); ylabel ('y [\mum]'); zlabel ('z [\mum]');
    view(2); grid on; axis image;
    HP = pointer_tree (intree, inodes); set (HP, 'facealpha', .5);
end

if (nargout == 1)||(isstruct(intree)),
    varargout {1}  = tree;
else
    trees {intree} = tree;
end
