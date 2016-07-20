% B_TREE   Branch point indices in a tree.
% (trees package)
% 
% B = B_tree (intree, options)
% ----------------------------
%
% returns a binary vector which is one only where there is a
% branching element (more than one child).
%
% Input
% -----
% - intree::integer:index of tree in trees or structured tree
% - options::string: {DEFAULT: ''}
%     '-s' : show
%
% Output
% ------
% B::Nx1 logical vector: branch points are 1, others 0
%
% Example
% -------
% B_tree (sample_tree, '-s')
%
% See also C_tree T_tree typeN_tree BCT_tree isBCT_tree
% Uses ver_tree dA
%
% the TREES toolbox: edit, visualize and analyze neuronal trees
% Copyright (C) 2009  Hermann Cuntz

function B = B_tree (intree, options)

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

% sum(dA) (actually faster than sum(dA)) ;-):
B = ((ones(1,size(dA,1))*dA)>1)'; % continuation points have more than one entry in dA

if strfind(options,'-s'), % show option
    clf; hold on; shine; HP = plot_tree (intree); set(HP, 'facealpha',0.2);
    HP = pointer_tree (intree, find(B), 50); set(HP, 'facealpha',0.2);
    title ('branch points');
    xlabel ('x [\mum]'); ylabel ('y [\mum]'); zlabel ('z [\mum]');
    view(2); grid on; axis image;
end