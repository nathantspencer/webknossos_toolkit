% RECON_TREE   Reconnect subtrees to new parent nodes.
% (trees package)
%
% tree = recon_tree (intree, ichilds, ipars, options)
% ---------------------------------------------------
%
% reconnects a set of subtrees, given by points ichilds to new parents
% ipars. This function alters the original morphology!
%
% Input
% -----
% - intree::integer/tree:index of tree in trees or structured tree
% - ichilds::vector: children ids {NO DEFAULTS!!}
% - ipars::vector: new parent ids {NO DEFAULTS!!}
% - options::string: {DEFAULT: '-h', shifts the subtrees}
%   '-h' : shifting of subtree to match the position of parent id
%   '-s' : show
%
% Output
% ------
% if no output is declared the tree is changed in trees
% - tree:: structured output tree
%
% Examples
% --------
% recon_tree (sample_tree, 105, 160, '-s')
% recon_tree (sample_tree, 105, 160, '-s -h')
%
% See also cat_tree sub_tree
% Uses idpar_tree sub_tree ver_tree X Y Z
%
% the TREES toolbox: edit, visualize and analyze neuronal trees
% Copyright (C) 2009  Hermann Cuntz

function varargout = recon_tree (intree, ichilds, ipars, options)

% trees : contains the tree structures in the trees package
global trees

if (nargin < 1)||isempty(intree),
    intree = length (trees); % {DEFAULT tree: last tree in trees cell array}
end;

ver_tree (intree); % verify that input is a tree structure

% use full tree for this function
if ~isstruct(intree),
    tree = trees {intree};
else
    tree = intree;
end

if (nargin < 4)||isempty(options),
    options = '-h'; % {DEFAULT: shift tree}
end

if strfind (options, '-h'),
    for ward = 1:length (ichilds), % move subtrees:
        isub = find (sub_tree (tree, ichilds (ward)));
        dX   = tree.X (ichilds (ward)) - tree.X (ipars (ward));
        dY   = tree.Y (ichilds (ward)) - tree.Y (ipars (ward));
        dZ   = tree.Z (ichilds (ward)) - tree.Z (ipars (ward));
        tree.X (isub) = tree.X (isub) - dX;
        tree.Y (isub) = tree.Y (isub) - dY;
        tree.Z (isub) = tree.Z (isub) - dZ;
    end
end

idpar = idpar_tree (tree); % vector containing index to direct parent
for ward = 1 : length (ichilds),
    tree.dA (ichilds (ward), idpar (ichilds (ward))) = 0;
    tree.dA (ichilds (ward), ipars (ward))           = 1;
end

if strfind (options, '-s'), % show option
    clf; shine; hold on; 
    plot_tree (intree, [0 0 0], -120);
    plot_tree (tree,   [1 0 0]);
    HP (1) = plot (1, 1, 'k-'); HP (2) = plot (1, 1, 'r-');
    legend (HP, {'before', 'after'}); set (HP, 'visible', 'off');
    title  ('reconnect nodes');
    xlabel ('x [\mum]'); ylabel ('y [\mum]'); zlabel ('z [\mum]');
    view(2); grid on; axis image;
end

if (nargout == 1)||(isstruct (intree)),
    varargout {1}  = tree; % if output is defined then it becomes the tree
else
    trees {intree} = tree; % otherwise the orginal tree in trees is replaced
end
