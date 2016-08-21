% XPLORE_TREE   Tree exploration plots.
% (trees package)
% 
% [HT HP] = xplore_tree (intree, options, color, DD)
% --------------------------------------------------
%
% plots different 2D representative exploration plots for a tree.
%
% Input
% -----
% - intree::integer: index of tree in trees or structured tree
% - options::string: {DEFAULT '-1'} has to be one of the following:
%     '-1' : transparent full plot + arrows directed graph + index values
%     '-2' : regions keeper
%     '-3' : 3D - viewer 
% - color::3-tupel: RGB values {DEFAULT: black}
% - DD::3-tupel: XYZ translation
%
% Outputs
% -------
% - HT::handles: links to the text elements
% - HP::handles: links to the graphical objects
%
% Examples
% --------
% xplore_tree (sample2_tree)
% xplore_tree (sample2_tree, '-2')
% xplore_tree (sample2_tree, '-3', [1 0 0])
%
% See also plot_tree
% Uses plot_tree vtext_tree ver_tree
%
% the TREES toolbox: edit, visualize and analyze neuronal trees
% Copyright (C) 2009  Hermann Cuntz

function [HT HP] = xplore_tree (intree, options, color, DD)

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

if (nargin <2)||isempty(options),
    options = '-1'; % {DEFAULT: node navigator}
end

if (nargin<3)||isempty(color),
    color = [0 0 0];
end

if (nargin<4)||isempty(DD),
    DD = [0 0 0];
end
if length(DD)<3,
    DD = [DD zeros(1, 3 - length (DD))];
end

tree = tran_tree (tree, DD);

if strfind (options, '-1'),
    hold on;
    HP = plot_tree (tree, color);
    plot_tree (tree, color, [], [], [], '-3q');
    HT = vtext_tree (tree);
    set (HP, 'facealpha', 0.1);
end

if strfind (options, '-2'),
    hold on;
    HP = plot_tree (tree, tree.R);
    uR = unique (tree.R);
    for ward = 1 : length(uR);
        if isfield (tree, 'rnames'),
            rname = tree.rnames {ward};
        else
            rname = num2str (uR (ward));
        end
        iR = find (tree.R == uR (ward));
        HT = text (mean (tree.X (iR)), mean (tree.Y (iR)), rname);
        set (HT, 'color', [1 0 0], 'fontsize', 14);
    end
end

if strfind (options, '-3'),
    subplot (211);
    HP = plot_tree (tree, color, [], [], [],  '-3l');
    set (HP, 'linewidth', 1);
    axis equal; view ([0, 90]); box on; grid on;
    xlabel ('x'); ylabel ('y');
    subplot (413);
    HP = plot_tree (tree, color, [], [], [],   '-3l');
    set (HP, 'linewidth', 1);
    axis equal; view ([90, 0]); box on; grid on;
    ylabel ('y'); zlabel ('z');
    subplot (414);
    HP = plot_tree (tree, color, [], [], [], '-3l');
    set (HP, 'linewidth', 1);
    axis equal; view ([0, 0]);  box on; grid on;
    xlabel ('x'); zlabel ('z');
    HT = [];
end
