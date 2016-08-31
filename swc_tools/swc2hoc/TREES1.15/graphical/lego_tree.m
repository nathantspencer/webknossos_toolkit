% LEGO_TREE   Lego density plot of a tree.
% (trees package)
%
% [HP, M] = lego_tree (intree, sr, thr, options)
% ----------------------------------------------
%
% Uses "gdens_tree" to plot the density matrix of points in a tree.
% Opacity and colors increase with density.
%
% Input
% -----
% - intree::integer:index of tree in trees or structured tree
% - sr::scalar: spatial resolution in um
% - thr::0..1: threshold value in percentage of maximum in M
% - options::string: {DEFAULT: ''}
%     '-e' : edge
%     '-f' : no face transparency
%
% Output
% ------
% - HP::handle:patch elements, note that default facealpha is 0.2
% - M::matrix:3D matrix containing density measure for each bin (from
%     "gdens_tree")
%
% Example
% -------
% lego_tree (sample_tree, 15)
%
% See also
% Uses gdens_tree ver_tree X Y
%
% the TREES toolbox: edit, visualize and analyze neuronal trees
% Copyright (C) 2009  Hermann Cuntz

function [HP, M] = lego_tree (intree, sr, thr, options)

% trees : contains the tree structures in the trees package
global trees

if (nargin < 1)||isempty(intree),
    intree = length (trees); % {DEFAULT tree: last tree in trees cell array}
end;

ver_tree (intree); % verify that input is a tree structure

if (nargin <2)||isempty(sr),
    sr = 50; % {DEFAULT value: 50 um sampling}
end

if (nargin < 3)||isempty(thr),
    thr = 0; % {DEFAULT value: no thresholding}
end

if (nargin <4)||isempty(options),
    options = ''; % {DEFAULT: no option}
end

[M dX dY dZ] = gdens_tree (intree, sr, [], 'none');

% cube
cX = [0 0 0 0; ...
    0 1 1 0; ...
    0 1 1 0; ...
    1 1 0 0; ...
    1 1 0 0; ...
    1 1 1 1] - 0.5;
cY = [0 0 1 1; ...
    0 0 1 1; ...
    1 1 1 1; ...
    0 1 1 0; ...
    0 0 0 0; ...
    0 0 1 1] - 0.5;
cZ = [0 1 1 0; ...
    0 0 0 0; ...
    1 1 0 0; ...
    1 1 1 1; ...
    1 0 0 1; ...
    0 1 1 0] - 0.5;

% cylinder
res = 8;
xX = [cos(0 : 2*pi/res : (2*pi - 2*pi/res))' ...
    cos(2*pi/res : 2*pi/res : 2*pi)'...
    cos(2*pi/res : 2*pi/res : 2*pi)'...
    cos(0 : 2*pi/res : (2*pi - 2*pi/res))'] / 2;
xY = [sin(0 : 2*pi/res : (2*pi - 2*pi/res))' ...
    sin(2*pi/res : 2*pi/res : 2*pi)'...
    sin(2*pi/res : 2*pi/res : 2*pi)'...
    sin(0 : 2*pi/res : (2*pi - 2*pi/res))'] / 2;
xZ = repmat ([1 1 0 0], res, 1) - 0.5;

sc = mean (diff (dX)); % scaling factor
% unity cube :     p = patch (cX',cY',cZ',[0 0 0]);
% unity cylinder : p = patch (xX',xY',xZ',[0 0 0]);

uM = unique (M);
uM = uM (uM > thr .* max (uM));
nM = uM - min (uM);
if nM == 0,
    nM = 1;
else
    nM = nM ./ max (nM);
end

HP = [];
hold on;
for ward = 1 : length (uM);
    [Y X Z] = ind2sub (size (M), find (M == uM (ward)));
    for te = 1 : length (X),
        x = dX (X (te)); y = dY (Y (te)); z = dZ (Z (te));
        len = 1;
        p   = zeros (5, 1);

        % cubes
        xc = repmat (x, 1, 6);
        xc = repmat (reshape (xc', numel (xc), 1), 1, 4);
        yc = repmat (y, 1, 6);
        yc = repmat (reshape (yc', numel (yc), 1), 1, 4);
        zc = repmat (z, 1, 6);
        zc = repmat (reshape (zc', numel (zc), 1), 1, 4);

        SX = repmat (sc.*cX, len, 1) + xc;
        SY = repmat (sc.*cY, len, 1) + yc;
        SZ = repmat (sc.*cZ, len, 1) + zc;
        p (1) = patch (SX', SY', SZ', uM (ward));

        % cylinders
        xc = repmat (x, 1, res);
        xc = repmat (reshape (xc', numel (xc), 1), 1, 4);
        yc = repmat (y, 1, res);
        yc = repmat (reshape (yc', numel (yc), 1), 1, 4);
        zc = repmat (z, 1, res);
        zc = repmat (reshape (zc', numel (zc), 1), 1, 4);

        SX = repmat (0.3*sc*xX, len, 1) + xc - 0.25*sc;
        SY = repmat (0.3*sc*xY, len, 1) + yc - 0.25*sc;
        SZ = repmat (0.2*sc*xZ, len, 1) + zc +  0.5*sc;
        p (2) = patch (SX', SY', SZ', uM (ward));

        SX = repmat (0.3*sc*xX, len, 1) + xc + 0.25*sc;
        SY = repmat (0.3*sc*xY, len, 1) + yc - 0.25*sc;
        SZ = repmat (0.2*sc*xZ, len, 1) + zc +  0.5*sc;
        p (3) = patch (SX', SY', SZ', uM (ward));

        SX = repmat (0.3*sc*xX, len, 1) + xc - 0.25*sc;
        SY = repmat (0.3*sc*xY, len, 1) + yc + 0.25*sc;
        SZ = repmat (0.2*sc*xZ, len, 1) + zc +  0.5*sc;
        p (4) = patch (SX', SY', SZ', uM (ward));

        SX = repmat (0.3*sc*xX, len, 1) + xc + 0.25*sc;
        SY = repmat (0.3*sc*xY, len, 1) + yc + 0.25*sc;
        SZ = repmat (0.2*sc*xZ, len, 1) + zc +  0.5*sc;
        p (5) = patch (SX', SY', SZ', uM (ward));

        HP = [HP; p];
        if isempty (strfind (options, '-e')),
            set (p, 'edgecolor', 'none'); % remove black lines around patch
        end
        if isempty (strfind (options, '-f')),
            set (p, 'facealpha', nM (ward)); % increase opacity with density
        end
    end
end
axis equal;

