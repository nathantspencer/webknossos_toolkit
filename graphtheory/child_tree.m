% CHILD_TREE   Attribute add-up child node values all nodes in a tree.
% (trees package)
% 
% child = child_tree (intree, v, options)
% ---------------------------------------
%
% returns a vector with the added up v values of all child nodes excluding
% itself to each node in the tree. This is a META-FUNCTION and
% can lead to various applications.
%
% Input
% -----
% - intree::integer:index of tree in trees or structured tree
% - v::Nx1 vector: values to be integrated {DEFAULT: ones, number of child nodes}
% - options::string: {DEFAULT: ''}
%     '-s' : show
%
% Output
% ------
% - child::Nx1 vector: accumulated values of all children to each node
%
% Example
% -------
% child_tree (sample_tree, [], '-s')
%
% See also ipar_tree ratio_tree LO_tree
% Uses ipar_tree ver_tree
%
% the TREES toolbox: edit, visualize and analyze neuronal trees
% Copyright (C) 2009  Hermann Cuntz

function child = child_tree (intree, v, options)

% trees : contains the tree structures in the trees package
global trees

if (nargin < 1)||isempty(intree),
    intree = length(trees); % {DEFAULT tree: last tree in trees cell array} 
end;

ver_tree (intree); % verify that input is a tree structure

ipar = ipar_tree (intree); % parent index structure (see "ipar_tree")
N = size(ipar, 1); % number of nodes in tree

if (nargin < 2)||isempty(v),
    v = ones(N,1); % {DEFAULT vector: ones, results in counting child nodes} 
end

if (nargin < 3)||isempty(options),
    options = ''; % {DEFAULT: no option}
end

v = [0; v];
ipar2 = [zeros(1, size(ipar, 2)-1) ; ipar(:, 2:end)];
% accumulate along parent paths:
child = accumarray (reshape(ipar2+1, numel(ipar2), 1), ...
    repmat(v, size(ipar2,2), 1));
child = child (2:end);
if size(child, 1)<N,
    child (N) = 0;
end

if strfind(options,'-s'), % show option
    clf; hold on; shine; plot_tree (intree, child); colorbar;
    title ('child count');
    xlabel ('x [\mum]'); ylabel ('y [\mum]'); zlabel ('z [\mum]');
    view(2); grid on; axis image;
end

%%% ALSO (mathematically more logical but more time consuming):
%
%%% columnsum of sum (A^i)
%
% dA = trees(index).dA;
% resW = dA;
% N = dA;
% while full(sum(sum(resW)))~=0,%sum(resW)~=0,
%     resW = dA*resW;
%     N = N + resW;%(resW==1);
% end
% result = full(sum(N));
