% POINTER_TREE Draws pointers (electrodes) to nodes on a tree.
% (trees package)
%
% HP = pointer_tree (intree, inodes, llen, color, DD, options)
% ------------------------------------------------------------
%
% draws pointers away at random positive deflections from nodes inodes.
% Look a bit like electrodes.
%
% Input
% -----
% - intree::integer:index of tree in trees or structured tree or Nx3 matrix
%     with [X Y Z] points 
% - inodes::vector: indices to intree where pointers should show.
% - llen::value: average length of pointer
% - color::RGB 3-tupel: RGB values {DEFAULT red}
% - DD:: XY-tupel or XYZ-tupel: coordinates offset {DEFAULT [0,0,0]}
% - options::string: {DEFAULT ''}
%     '-l' : thin electrode tip
%     '-v' : huge electrode tip
%
% Output
% ------
% - HP::handles: handles to the lines.
%
% Example
% -------
% pointer_tree (sample_tree)
%
% See also
% Uses ver X Y Z
%
% the TREES toolbox: edit, visualize and analyze neuronal trees
% Copyright (C) 2009  Hermann Cuntz

function HP = pointer_tree (intree, inodes, llen, color, DD, options)

% trees : contains the tree structures in the trees package
global trees

if (nargin < 1)||isempty(intree),
    intree = length (trees); % {DEFAULT tree: last tree in trees cell array}
end;

% use only node position for this function
if ~isstruct (intree),
    if numel (intree) == 1
    X = trees {intree}.X;
    Y = trees {intree}.Y;
    Z = trees {intree}.Z;
    else
        X = intree(:,1);
        Y = intree(:,2);
        Z = intree(:,3);
    end
else
    X = intree.X;
    Y = intree.Y;
    Z = intree.Z;
end

if (nargin <2 )||isempty(inodes),
    inodes = length (X); % {DEFAULT: last node in the tree}
end

if (nargin <3 )||isempty(llen),
    llen = 150; % {DEFAULT: average length of pointer}
end

if (nargin <6)||isempty(options),
    options = ''; % {DEFAULT: no option}
end

if (nargin < 4)||isempty(color),
    if strfind (options, '-v'),
        color = [0.6 0.7 1]; % {DEFAULT: bluegreenish}
    else
        color = [1 0 0]; % {DEFAULT: red}
    end
    
end

if (nargin <5)||isempty(DD),
    DD = [0 0 0]; % {DEFAULT 3-tupel: no spatial displacement from the root}
end
if length (DD) < 3,
    DD = [DD zeros(1, 3 - length (DD))];
end

% the electrodes are basically tapering straight dendrites:
switch options,
    case '-v',
        HP = zeros (length (inodes), 1);
        for ward = 1 : length (inodes),
            tree = []; tree.dA = sparse ([0 0; 1 0]);
            tree.X = X (inodes (ward)) + [0; rand*llen] + DD (1);
            tree.Y = Y (inodes (ward)) + [0; rand*llen] + DD (2);
            tree.Z = Z (inodes (ward)) + [0; rand*llen] + DD (3);
            tree.D = [1; 10];
            tree.frustum = 1;
            tree   = resample_tree (tree, 20, '-d');
            tree.D = tree.D * 10;
            HP (ward) = plot_tree (tree, color, [], [], 32);
        end
        set(HP,'facealpha',0.2);
    case '-l',
        HP = zeros (length (inodes), 1);
        for ward = 1 : length (inodes),
            tree = []; tree.dA = sparse([0 0; 1 0]);
            tree.X = X (inodes (ward)) + [0; rand*llen] + DD (1);
            tree.Y = Y (inodes (ward)) + [0; rand*llen] + DD (2);
            tree.Z = Z (inodes (ward)) + [0; rand*llen] + DD (3);
            tree.D = [1; 10];
            tree.frustum = 1;
            HP (ward) = plot_tree (resample_tree (tree, 20, '-d'), color, [], [], 8);
        end
    otherwise,
        HP = zeros (length (inodes), 1);
        [XS YS ZS] = sphere (16);
        for ward = 1 : length (inodes),
            HP (ward) = surface (X (inodes (ward)) + 2.5 * XS + DD (1),...
                Y (inodes (ward)) + 2.5 * YS + DD (2),...
                Z (inodes (ward)) + 2.5 * ZS + DD (3));
        end
        set (HP, 'edgecolor', 'none', 'facecolor', color, 'facealpha', .2); axis image;
end
axis equal

% % simple lines instead:
% % random deflection:
% R = rand (length (inodes), 3) .* repmat ([50 50 150], length (inodes), 1);
% hold on;
% HP = line ([X(inodes) X(inodes) + R(:, 1)]'+ DD (1),...
%     [Y(inodes) Y(inodes) + R(:, 2)]' + DD (2),...
%     [Z(inodes) Z(inodes) + R(:, 3)]' + DD (3));
% set (HP, 'linestyle', '-', 'color', color, 'linewidth', 2);
