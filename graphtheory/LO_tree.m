% LO_TREE   Level order of all nodes of a tree.
% (trees package)
% 
% LO = LO_tree (intree, options)
% ------------------------------
% 
% returns the summed topological path distance of all child branches to the
% root. The function is called level order and is useful to classify rooted
% trees into isomorphic classes. (see code below)
%
% Input
% -----
% - intree::integer:index of tree in trees or structured tree
% - options::string: {DEFAULT: ''}
%     '-s' : show
%
% Output
% ------
% - LO::vector Nx1:level order of each compartment.
%
% Example
% -------
% LO_tree (sample_tree, '-s')
%
% See also PL_tree BO_tree sortLO_tree
% Uses PL_tree ver_tree dA
%
% the TREES toolbox: edit, visualize and analyze neuronal trees
% Copyright (C) 2009  Hermann Cuntz

function  LO = LO_tree (intree, options)

% trees : contains the tree structures in the trees package
global trees

if (nargin < 1)||isempty(intree),
    intree = length(trees); % {DEFAULT tree: last tree in trees cell array} 
end;

ver_tree (intree); % verify that input is a tree structure

% use only directed adjacency for this function
if ~isstruct(intree),
    dA = trees{intree}.dA;
else
    dA = intree.dA;
end

if (nargin < 2)||isempty(options),
    options = ''; % {DEFAULT: no option}
end

N = size (dA, 1); % number of nodes in tree
PL = PL_tree (intree); % path length away from node
sdA = spdiags(PL, 0, N, N)*dA; % dA-ordered path length values
% calculating weighted path length:
ward = 1;
resLO = sdA;
LO = sum(resLO)';
while sum(resLO(:,1))~=0,
    ward = ward + 1;
    % starting at the tips
    resLO = resLO*dA; % use adjacency matrix to walk through tree accumulating LO
    LO = LO + sum(resLO)';
end
LO = LO + PL;
LO = full(LO);

if strfind(options,'-s'), % show option
    clf; hold on; shine; plot_tree (intree, LO);
    title ('level order');
    xlabel ('x [\mum]'); ylabel ('y [\mum]'); zlabel ('z [\mum]');
    view(2); grid on; axis image; colorbar;
end
