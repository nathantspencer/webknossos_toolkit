% IPAR_TREE   Path to root: parent indices. 
% (trees package)
% 
% ipar = ipar_tree (intree, options)
% ----------------------------------
%
% returns the matrix of indices to the parent of individual nodes following
% the path against the direction of the adjacency matrix toward the root of
% the tree. This function is crucial to many other functions based on graph
% theory in the trees package.
%
% Input
% -----
% - intree::integer:index of tree in trees or structured tree
% - options::string: {DEFAULT: ''}
%     '-s' : show
%
% Output
% ------
% - ipar::matrix: path indices of parent nodes for each node in tree
%
% Example
% -------
% ipar_tree (sample_tree, '-s')
%
% See also idpar_tree child_tree
% Uses PL_tree ver_tree dA
%
% the TREES toolbox: edit, visualize and analyze neuronal trees
% Copyright (C) 2009  Hermann Cuntz

function ipar = ipar_tree (intree, options)

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

N = size (dA,1); % number of nodes in tree
maxPL = max (PL_tree (intree)); % maximum depth by maximum path length
V = (1:N)';
ipar = zeros (N, maxPL+2);
ipar(:,1) = V;
for ward = 2:maxPL+2,
    V = dA*V; % use adjacency matrix to walk through tree
    ipar(:, ward) = V;
end

if strfind(options,'-s'); % show option
    clf; imagesc(ipar);
    ylabel('node #');
    xlabel('parent path');
    colorbar;
    title('color: parent node #');
end

% % stupid concatenation issue (2.5 sec.. for hss):
% N = size(dA,1);
% V = (1:N)';
% ipar = V;
% while sum(V)~=0,
%     V = dA*V;
%     ipar = [ipar V];
% end

% % ALSO POSSIBLE but slower (something like):
% for ward = 0:N,
%     ipar = [ipar (dA^ward)*(1:N)'];
% end

