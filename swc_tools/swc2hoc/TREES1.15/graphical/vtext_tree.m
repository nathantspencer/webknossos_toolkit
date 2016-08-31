% VTEXT_TREE   Write text at node locations in a tree.
% (trees package)
% 
% HP = vtext_tree (intree, v, color, DD, crange, ipart, options)
% --------------------------------------------------------------
%
% displays text numbers in the vector v at the coordinates of the tree
%
% Input
% -----
% - intree::integer:index of tree in trees structure or structured tree
% - v::vertical vector of size N (number of nodes):any vector of numbers to be
%     displayed in the appropriate location {DEFAULT: node indices}
% - color::RGB 3-tupel, vector or matrix: RGB values {DEFAULT [0 0 0]}
%     if vector then values are treated in colormap (must contain one value
%     per node then!)
%     if matrix (num x 3) then individual colors are mapped to each element
% - DD:: XY-tupel or XYZ-tupel: coordinates offset {DEFAULT [0,0,0]}
% - crange::2-tupel: color range [min max] {DEFAULT tight}
% - ipart::index:index to the subpart to be plotted (child nodes)
% - options::string: {DEFAULT ''}
%     '-2d': text coordinates only 2 dimensions (DD has to correspond)
%     '-scale': text does not scale the axis not even with axis tight, this
%         option does it for you
%
% Output
% ------
% - HP::handles: depending on options HP links to the graphical objects.
%
% Example
% -------
% vtext_tree (sample_tree, [], [], [], [], [], '-scale');
%
% See also plot_tree xplore_tree
% Uses X,Y,Z
%
% the TREES toolbox: edit, visualize and analyze neuronal trees
% Copyright (C) 2009  Hermann Cuntz

function HP = vtext_tree (intree, v, color, DD, crange, ipart, options)

% trees : contains the tree structures in the trees package
global trees

if (nargin <7)||isempty(options),
    options = ''; % {DEFAULT: no option}
end

if (nargin < 1)||isempty(intree),
    intree = length (trees); % {DEFAULT tree: last tree in trees cell array}
end;

ver_tree (intree); % verify that input is a tree structure

% use only node position for this function
if ~isstruct (intree),
    X = trees {intree}.X;
    Y = trees {intree}.Y;
    if isempty (strfind (options, '-2d')),
        Z = trees {intree}.Z;
    end
else
    X = intree.X;
    Y = intree.Y;
    if isempty (strfind (options, '-2d')),
        Z = intree.Z;
    end
end

N = size (X, 1); % number of nodes in tree

if (nargin <6)||isempty(ipart),
    ipart = (1 : N)'; % {DEFAULT index: select all nodes/points}
end

if (nargin < 2)||isempty(v),
    v = (1 : N)'; % {DEFAULT vector: count up nodes}
end
if (size (v, 1) == N) && (size (ipart, 1) ~= N),
    v = v (ipart);
end

if (nargin < 3)||isempty(color),
    color = [1 0 0]; % {DEFAULT color: red} 
end;
if (size (color, 1) == N) && (size (ipart, 1) ~= N),
    color = color (ipart);
end

if (nargin <4)||isempty(DD),
    DD = [0 0 0]; % {DEFAULT 3-tupel: no spatial displacement from the root}
end
if length (DD) < 3,
    DD = [DD zeros(1, 3 - length (DD))]; % append 3-tupel with zeros
end

% if color values are mapped:
if size (color, 1) > 1,
    if size (color, 2) ~= 3,
        if islogical (color),
            color = double (color);
        end
        if (nargin<5)||isempty(crange),
            crange = [min(color) max(color)];
        end
        % scaling of the vector
        if diff (crange) == 0,
            color = ones (size (color, 1), 1);
        else
            color = floor ((color - crange (1)) ./ ((crange (2) - crange (1)) ./ 64));
            color (color < 1 ) =  1;
            color (color > 64) = 64;
        end
        map = colormap;
        colors = map (color, :);
    end
end

if strfind (options, '-2d'),
    vt = num2str (v);
    HP = text (X (ipart) + DD (1), Y (ipart) + DD (2), vt);
else
    vt = num2str (v);
    HP = text (X (ipart) + DD (1), Y (ipart) + DD (2), Z (ipart) + DD (3), vt);
end

if size (color, 1) > 1,
    for ward = 1 : length (ipart),
        set (HP (ward), 'color', colors (ward, :), 'fontsize', 14);
    end
else
    set (HP, 'color', color, 'fontsize', 14);
end

if strfind (options, '-scale'),
    axis equal; xlim ([min(X) max(X)]); ylim ([min(Y) max(Y)]);
    if isempty (strfind (options, '-2d')),
        zlim ([min(Z) max(Z)]);
    end
end

