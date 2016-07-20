% INSERTP_TREE   Insert nodes along a path in a tree.
% (trees package)
%
% [tree indx] = insertp_tree (intree, inode, plens, options)
% ----------------------------------------------------------
%
% inserts points at path-lengths plens on the path from the root to point
% inode. All Nx1 vectors are interpolated linearly but regions are taken
% from child nodes. This function alters the original morphology!
%
% Input
% -----
% - intree::integer/tree:index of tree in trees or structured tree
% - inode::index: position of path-defining node {DEFAULT: last node}
% - plens::horiz vector: path length values where points are being added
%     {DEFAULT: is every 10 um on the path up to inode}
% - options::string: {DEFAULT: '-e'}
%     '-s' : show
%     '-e' : echo changes - message added nodes
%     '-p' : plen to direct parent node
%     '-pr': + relative position between 0..1
%
% Output
% ------
% if no output is declared the tree is changed in the trees structure
% - tree::tree: altered tree structure
% - indx::(new N)x1 vector: one where new nodes were inserted
%
% Example
% -------
% insertp_tree (sample_tree, 43, 50:10:100, '-s')
%
% See also insert_tree, delete_tree, cat_tree, recon_tree, resample_tree
% Uses ipar_tree Pvec_tree ver_tree dA
%
% the TREES toolbox: edit, visualize and analyze neuronal trees
% Copyright (C) 2009  Hermann Cuntz

function varargout = insertp_tree (intree, inode, plens,  options)

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

N = size (tree.dA, 1); % number of nodes in tree

if (nargin < 2)||isempty(inode),
    inode = N; % {DEFAULT: last node defines the path}
end

Plen = Pvec_tree (intree); % path length from the root [um]

if (nargin < 3)||isempty(plens),
    if Plen(inode) > 10, % {DEFAULT: every 10 um from the root to inode}
        plens = (0 : 10 : Plen(inode));
    else
        plens = Plen(inode) ./ 2; % {DEFAULT: halfway to root if inode too close}
    end
end

if (nargin < 4)||isempty(options),
    options = '-e'; % {DEFAULT: echo changes}
end

% pathi: node indices of path from inode to root
ipar  = ipar_tree (intree);
pathi = fliplr (ipar (inode, ipar(inode, :) > 0));

% plen: path lengths from root to nodes on the path
plen  = Plen';   plen = plen (pathi);
plens = setdiff (plens, plen); % don't add points where points are already
plens = plens   (plens < max(plen)); % otherwise the branch would explode
N2    = length  (plens); % number of points to be added

% expand adjacency matrix:
tree.dA = [[tree.dA, sparse(N, N2)];sparse(N2, N + N2)];

for ward = 1 : N2
    iplen = find(plen >= plens(ward)); ilen2     = min (plen (iplen)); % child
    iplen = find(plen < plens(ward)); [ilen1 i2] = max (plen (iplen)); % parent
    pos = iplen (i2);
    % parent node and relative position between both
    rpos  = (plens (ward) - ilen1) ./ (ilen2 - ilen1);
    ipos  = pathi (pos + 1);
    idpar = pathi (pos);
    % update path-lengths and path-indices:
    plen  = [ plen(1 : pos) plens(ward)  plen(pos+1 : end)];
    pathi = [pathi(1 : pos) N+ward      pathi(pos+1 : end)];
    tree.dA (ipos,     idpar) = 0;
    tree.dA (ipos,  N + ward) = 1;
    tree.dA (N + ward, idpar) = 1;
    % expand vectors of form Nx1
    S = fieldnames (tree);
    for te = 1 : length (S)
        if ~strcmp (S{te}, 'dA'),
            vec = tree.(S{te});
            if isvector(vec) && (numel(vec) == N + ward - 1),
                if strcmp (S{te}, 'R'),
                    tree.R (N + ward) = tree.R (ipos);
                else
                    tree.(S{te})(N + ward)  = tree.(S{te})(idpar) + ...
                        (tree.(S{te})(ipos) - tree.(S{te})(idpar)) .* rpos;
                end
            end
        end
    end
end

if strfind (options, '-s'),
    HP = plot3 (tree.X (N + 1 : N + N2), ...
        tree.Y (N + 1 : N + N2), ...
        tree.Z (N + 1 : N + N2), 'r.');
    set (HP, 'markersize', 48);
end

[tree indx] = sort_tree (tree, '-LO'); indx = indx > N;

if strfind (options, '-s'),
    clf; shine; hold on; xplore_tree (tree);
    HP = pointer_tree (tree, find (indx)); set (HP, 'facealpha', .5);
    title ('insert nodes on path');
    xlabel ('x [\mum]'); ylabel ('y [\mum]'); zlabel ('z [\mum]');
    view(2); grid on; axis image;
end

if strfind (options, '-e'),
   warning ('TREES:notetreechange', ['added ' num2str(N2) ' node(s)']);
end

if (nargout > 0)||(isstruct (intree)),
    varargout {1}  = tree;
else
    trees {intree} = tree;
end

if nargout == 2,
    varargout {2}  = indx;
end
