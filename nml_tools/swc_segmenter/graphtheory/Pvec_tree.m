% PVEC_TREE   Cumulative summation along paths of a tree.
% (trees package)
% 
% Pvec = Pvec_tree (intree, v, options)
% -------------------------------------
%
% cumulative vector, calculates the total path to the root cumulating
% elements of v (addition) of each node. - metafunction
%
% Input
% -----
% - intree::integer:index of tree in trees structure or structured tree
% - v::Nx1 vector: for each node a number to be cumulated {DEFAULT: len}
% - options::string: {DEFAULT: ''}
%     '-s' : shows first column of matrix dist
%
% Output
% ------
% - Pvec::Nx1 vector: cumulative v along path from the root
%
% Example
% -------
% Pvec_tree (sample_tree, [], '-s')
%
% See also ipar_tree child_tree morph_tree bin_tree
% Uses ipar_tree len_tree ver_tree dA
%
% the TREES toolbox: edit, visualize and analyze neuronal trees
% Copyright (C) 2009  Hermann Cuntz

function Pvec = Pvec_tree (intree, v, options)

% trees : contains the tree structures in the trees package
global trees

if (nargin < 1)||isempty(intree),
    intree = length(trees); % {DEFAULT tree: last tree in trees cell array} 
end;

ver_tree (intree); % verify that input is a tree structure

if (nargin < 2)||isempty(v),
    v = len_tree (intree); % {DEFAULT vector: lengths of segments} 
end

if (nargin < 3)||isempty(options),
    options = ''; % {DEFAULT: no option}
end

ipar = ipar_tree (intree); % parent index structure (see "ipar_tree")
v0 = [0; v];

if size(ipar,1) == 1,
    Pvec = v;
else
    Pvec = sum (v0(ipar+1),2);
end

if strfind(options,'-s'), % show option
    clf; hold on; shine; plot_tree (intree, Pvec); colorbar;
    title ('path accumulation');
    xlabel ('x [\mum]'); ylabel ('y [\mum]'); zlabel ('z [\mum]');
    view(2); grid on; axis image;
end
