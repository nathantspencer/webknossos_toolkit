% GDENS_TREE   Density matrix of a tree.
% (trees package)
%
% [M dX dY dZ HP] = gdens_tree (intree, sr, ipart, options)
% ---------------------------------------------------------
%
% calculates a density matrix of nodes in the tree intree. Uses isosurface
% to display the resulting gradient and increases opacity with density.
%
% Input
% -----
% - intree::integer:index of tree in trees or structured tree
%       alternatively, intree can be a Nx3 matrix XYZ of points
% - sr::scalar: spatial resolution in um {DEFAULT: 5 um}
% - ipart::index:index to the subpart to be considered {DEFAULT: all nodes}
% - options::string: {DEFAULT: '-s'}
%     '-s' : show
%
% Output
% ------
% - M::matrix:3D matrix containing density measure for each bin
% - dX::vector:X-locations at which density was measured (in a bin)
% - dY::vector:Y-locations at which density was measured (in a bin)
% - dZ::vector:Z-locations at which density was measured (in a bin)
% - HP::handles: depending on options HP links to the graphical objects.
%
% Example
% -------
% gdens_tree (sample_tree, 20)
%
% See also lego_tree
% Uses ver_tree X Y Z
%
% the TREES toolbox: edit, visualize and analyze neuronal trees
% Copyright (C) 2009  Hermann Cuntz


function [M dX dY dZ HP] = gdens_tree (intree, sr, ipart, options)

% trees : contains the tree structures in the trees package
global trees

if (nargin < 1)||isempty(intree),
    intree = length(trees); % {DEFAULT tree: last tree in trees cell array}
end;

% use only node position for this function
if isnumeric(intree) && numel(intree)>1,
    X = intree (:, 1);
    Y = intree (:, 2);
    Z = intree (:, 3);
else
    ver_tree (intree); % verify that input is a tree structure
    if ~isstruct (intree),
        X = trees {intree}.X;
        Y = trees {intree}.Y;
        Z = trees {intree}.Z;
    else
        X = intree.X;
        Y = intree.Y;
        Z = intree.Z;
    end
end

if (nargin <2)||isempty(sr),
    sr = 5; % {DEFAULT value: 5um sampling}
end

if (nargin < 3)||isempty(ipart),
    ipart = (1 : length(X))'; % {DEFAULT index: select all nodes/points}
end

if (nargin <4)||isempty(options),
    options = '-s'; % {DEFAULT: show result}
end

X = X (ipart);
Y = Y (ipart);
Z = Z (ipart);

dX = min (X) - 2 * sr : sr : max (X) + 2 * sr;
dY = min (Y) - 2 * sr : sr : max (Y) + 2 * sr;
dZ = min (Z) - 2 * sr : sr : max (Z) + 2 * sr;

M = zeros (length (dY), length (dX), length (dZ));

iX = (repmat (X, 1, length (dX)) <  repmat (dX + sr, length (X), 1)) & ...
    repmat   (X, 1, length (dX)) >= repmat (dX,      length (X), 1);
iY = (repmat (Y, 1, length (dY)) <  repmat (dY + sr, length (Y), 1)) & ...
    repmat   (Y, 1, length (dY)) >= repmat (dY,      length (Y), 1);
iZ = (repmat (Z, 1, length (dZ)) <  repmat (dZ + sr, length (Z), 1)) & ...
    repmat   (Z, 1, length (dZ)) >= repmat (dZ,      length (Z), 1);

iX = sum (iX .* repmat (1 : length (dX), length (X), 1), 2);
iY = sum (iY .* repmat (1 : length (dY), length (Y), 1), 2);
iZ = sum (iZ .* repmat (1 : length (dZ), length (Z), 1), 2);

indx  = sub2ind (size (M), iY, iX, iZ);
uindx = unique  (indx);

dX = dX + sr / 2;
dY = dY + sr / 2;
dZ = dZ + sr / 2;

M (uindx) = histc (indx, uindx);

if findstr (options, '-s'),
    hold on; minM = min (min (min (M))); maxM = max (max (max (M)));
    HP = zeros (1, 11); counter = 1;
    for ward = minM : (maxM - minM) / 10 : maxM,
        c = isosurface (dX, dY, dZ, M, ward);
        HP (counter) = patch (c, 'FaceVertexCData', ward, 'facecolor', 'flat');
        % transparency expresses density:
        taux = 0.3; trans = exp (- (1 - ( ((ward - minM) ./ (maxM - minM)) )) ./ taux);
        set (HP (counter), 'EdgeColor', 'none', 'facealpha', trans - 0.00001);
        counter = counter + 1;
    end
    axis equal
else
    HP = [];
end
