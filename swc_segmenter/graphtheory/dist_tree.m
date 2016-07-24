% DIST_TREE   Index to tree nodes at um path distance away from root.
% (trees package)
% 
% dist = dist_tree (intree, l, options)
% -------------------------------------
%
% returns a binary output indicating the nodes which are in path distance l
% from the root. If l is a vector dist is a matrix. 
%
% Input
% -----
% - intree::integer:index of tree in trees or structured tree
% - l::horizontal vector:distances from the root in um {DEFAULT: 100}
% - options::string: {DEFAULT: ''}
%     '-s' : shows nodes dist
%
% Output
% ------
% - dist::sparse binary matrix (N x length(l)): 1 when node segement is in distance l.
%
% Example
% -------
% dist_tree (sample_tree, [50 100], '-s')
%
% See also sholl_tree Pvec_tree
% Uses len_tree Pvec_tree idpar_tree ver_tree
%
% the TREES toolbox: edit, visualize and analyze neuronal trees
% Copyright (C) 2009  Hermann Cuntz

function dist = dist_tree (intree, l, options)

% trees : contains the tree structures in the trees package
global trees

if (nargin < 1)||isempty(intree),
    intree = length(trees); % {DEFAULT tree: last tree in trees cell array} 
end;

ver_tree (intree); % verify that input is a tree structure

if (nargin < 2)||isempty(l),
    l = 100; % {DEFAULT horizontal vector: one value, 100 um} 
end

if (nargin < 3)||isempty(options),
    options = ''; % {DEFAULT: no option}
end

Plen = Pvec_tree (intree, len_tree (intree)); % path length from the root [um]
idpar = idpar_tree (intree); % vector containing index to direct parent
llen = size(l, 2); l = repmat(l,size(Plen,1),1);
% node itself is more than l path length from root but parent is less:
dist = sparse((l>=repmat(Plen(idpar),1,llen)) & (l<repmat(Plen,1,llen)));

if strfind(options,'-s'), % show option
    clf; hold on; shine; plot_tree (intree, [0 0 0], [], ~sum(dist, 2));
    for ward = 1:size(dist,2),
        plot_tree (intree, [1 0 0], [], dist(:,ward));
    end
    title ('distance crossing');
    xlabel ('x [\mum]'); ylabel ('y [\mum]'); zlabel ('z [\mum]');
    view(2); grid on; axis image;
end
