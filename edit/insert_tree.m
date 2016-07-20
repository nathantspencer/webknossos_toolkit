% INSERT_TREE   Insert a number of points into a tree.
% (trees package)
% 
% tree = insert_tree (intree, swc,  options)
% ------------------------------------------
%
% inserts a set of points defined by a matrix swc in SWC format ([inode R X
% Y Z D idpar]) into a tree intree. This function alters the original
% morphology! 
%
% Input
% -----
% - intree::integer:index of tree in trees or structured tree
% - swc::matrix: points in swc format [inode R X Y Z D idpar]
%     inode values are not considered. If scalar, indicates number of random
%     points. {DEFAULT: adds one random point}
% - options::string: {DEFAULT: '-e'}
%     '-s' : show
%     '-e' : echo added nodes
%
% Output
% ------
% if no output is declared the tree is changed in trees
% - tree:: structured output tree
%
% Example
% -------
% insert_tree (sample_tree, [1 1 200 -140 0 4 3; 2 1 200 -60 0 4 3], '-s
% -e')
%
% See also insertp_tree
% Uses ver_tree dA
%
% the TREES toolbox: edit, visualize and analyze neuronal trees
% Copyright (C) 2009  Hermann Cuntz

function varargout = insert_tree (intree, swc, options)

% trees : contains the tree structures in the trees package
global trees

if (nargin < 1)||isempty(intree),
    intree = length (trees); % {DEFAULT tree: last tree in trees cell array}
end;

ver_tree (intree); % verify that input is a tree structure

% use full tree for this function
if ~isstruct (intree),
    tree = trees {intree};
else
    tree = intree;
end

N = size (tree.dA, 1);

if (nargin < 2)||isempty(swc),
    swc = 1; % {DEFAULT: add one random point}
end
if numel(swc)==1,
    swc = [(1:swc)' ones(swc,1) ...
        rand(swc,1)*(max(tree.X)-min(tree.X))+min(tree.X) ...
        rand(swc,1)*(max(tree.Y)-min(tree.Y))+min(tree.Y) ...
        rand(swc,1)*(max(tree.Z)-min(tree.Z))+min(tree.Z) ...
        ones(swc,1) floor(rand(swc,1)*N)+1];
end

N2 = size (swc, 1);

if (nargin < 3)||isempty(options),
    options = '-e'; % {DEFAULT: echo changes}
end

tree.dA = [[tree.dA, sparse(N, N2)]; sparse(N2, N + N2)];
tree.dA (sub2ind([N+N2, N+N2],(N+1 : N+N2)',swc(:, 7))) = 1;

if isfield (tree, 'X'),
    tree.X = [tree.X; swc(:, 3)];
end
if isfield (tree, 'Y'),
    tree.Y = [tree.Y; swc(:, 4)];
end
if isfield (tree, 'Z'),
    tree.Z = [tree.Z; swc(:, 5)];
end
if isfield (tree, 'D'),
    tree.D = [tree.D; swc(:, 6)];
end

% eliminate obsolete regions (only if everything is correct)
if isfield(tree,'R')
    if isfield (tree, 'rnames'),
        % my god! Handling regions is not easy!!!!!!
        [i1 i2 i3]  = unique ([tree.R; swc(:, 2)]);
        [i4 i5 i6]  = intersect (unique (tree.R), i1);
        rnames      = cell (1, 1);
        for ward = 1 : length(i1), rnames {ward} = num2str (i1 (ward)); end
        rnames (i6) = tree.rnames (i5);
        tree.rnames = rnames;
        tree.R      = i3;
    else
        [i1 i2 i3]  = unique([tree.R; swc(:, 2)]);
        tree.R      = i3;
    end
end

if strfind (options, '-s'), % show option
    clf; shine; hold on; HP = pointer_tree ([swc(:, 3), swc(:, 4), swc(:, 5)], (1 : N2)');
    set(HP, 'facealpha', .5);
    xplore_tree (tree); title ('insert nodes');
    xlabel ('x [\mum]'); ylabel ('y [\mum]'); zlabel ('z [\mum]');
    view(2); grid on; axis image;
end

if strfind (options, '-e'), % echo changes
    warning ('TREES:notetreechange',['added ' num2str(size (swc, 1)) ' node(s)']);
end

if (nargout == 1)||(isstruct (intree)),
    varargout {1}  = tree; % if output is defined then it becomes the tree
else
    trees {intree} = tree; % otherwise the orginal tree in trees is replaced
end
