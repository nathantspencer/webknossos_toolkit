% BO_TREE   Branch order values in a tree.
% (trees package)
% 
% BO = BO_tree (intree, options)
% ------------------------------
% 
% returns the branch order of all nodes referring to the first node as
% the root of the tree. This value starts at 0 and increases after every
% branch point.
%
% Input
% -----
% - intree::integer:index of tree in trees or structured tree
% - options::string: {DEFAULT: ''}
%     '-s' : show
%
% Output
% ------
% BO::Nx1 vector: vector of branch order values
%
% Example
% -------
% BO_tree (sample_tree, '-s')
%
% See also PL_tree LO_tree
% Uses ver_tree typeN_tree dA
%
% the TREES toolbox: edit, visualize and analyze neuronal trees
% Copyright (C) 2009  Hermann Cuntz

function BO = BO_tree (intree, options)

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

N = size(dA, 1); % number of nodes in tree
% type (2:B, 1:C, 0:T) on the spot in a matrix sdA:
% 2s potentiate and then taking the log2 to indicate branching point on the
% way..
% dA * diag(sum(dA)):
sdA = dA*spdiags(typeN_tree(intree), 0, N, N);
% calculating weighted path length:
BO = sdA(:,1);
resBO = BO;
while sum(resBO)~=0,
    resBO = sdA*resBO; % use adjacency matrix to walk through tree
    BO = BO + resBO;
end
BO(1)=1;
BO = full(log2(BO));

if strfind(options,'-s'), % show option
    clf; hold on; shine; plot_tree (intree, BO); colorbar;
    title ('branch order');
    xlabel ('x [\mum]'); ylabel ('y [\mum]'); zlabel ('z [\mum]');
    view(2); grid on; axis image;
end

