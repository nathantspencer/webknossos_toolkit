% IDPAR_TREE   Index to direct parent node in a tree.
% (trees package)
% 
% idpar = idpar_tree (intree, options)
% ------------------------------------
%
% returns the index to the direct parent node of each individual element in
% the tree 
%
% Input
% -----
% - intree::integer:index of tree in trees or structured tree
% - options::string: {DEFAULT: ''}
%     '-0' : the root node is 0 instead of 1 
%     '-s' : show
%
% Output
% ------
% - idpar::Nx1 vector: index of direct parent node to each node
%
% Example
% -------
% idpar_tree (sample_tree, '-s')
%
% See also ipar_tree child_tree
% Uses ver_tree dA
%
% the TREES toolbox: edit, visualize and analyze neuronal trees
% Copyright (C) 2009  Hermann Cuntz

function idpar = idpar_tree (intree, options)

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

% index to direct parent:
idpar = dA*(1:size(dA,1))'; % simple graph theory: feature of adjacency matrix

if isempty(strfind(options,'-0')),
    % null-compartment (root) becomes one
    idpar(idpar==0) = 1;
end

if strfind(options,'-s'), % show option
    clf; shine; HP = plot_tree(intree); set(HP,'facealpha',0.2);
    T = vtext_tree (intree, idpar, []);
    set (T, 'fontsize',14);
    title ('direct parend ID');
    xlabel ('x [\mum]'); ylabel ('y [\mum]'); zlabel ('z [\mum]');
    view(2); grid on; axis image;
end