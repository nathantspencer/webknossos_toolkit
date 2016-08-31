% HULL_TREE   isosurface/line at a distance from any point on tree.
% (trees package)
%
% [c M HP] = hull_tree (intree, thr, bx, by, bz, options)
% --------------------------------------------------------
%
% calculates a space-filling 3D isosurface around the tree with a threshold
% distance of thr um. In order to do this it creates a grid defined by the
% vectors bx, by and bz and calculates the closest point of the tree to any
% of the points on the grid. Higher resolution requires more computer power
% but results in higher accuracy of contour. Don't forget that the smaller
% the threshold distance thr the better spatial resolution you need!
% Reduce the resulting patch resolution with: reducepatch (HP, ratio)
%
% Input
% -----
% - intree::integer:index of tree in trees or structured tree
% - thr::value: threshold value for the isoline contour {DEFAULT: 25 um}
% - bx::vector: horiz. defining underlying grid or single value = spat. res.
%               {DEFAULT: 50}
% - by::vector: vert. defining underlying grid or single value = spat. res.
%               {DEFAULT: 50}
% - bz::vector: zdir defining underlying grid or single value = spat. res.
%               {DEFAULT: 50}
% - options::string: {DEFAULT: '-w -s -F'}
%     '-s'  : show isosurface/line
%     '-w'  : waitbar, good for large bx and by and bz
%     '-F'  : output M is full distances matrix
%     '-2d' : 2D isoline instead of 3D isosurface
%
% Outputs
% -------
% - c::polygon:
% - HP::handle:handle to patches
% - M::binary matrix:
%
% Example
% -------
% hull_tree (sample_tree)
% hull_tree (sample_tree, [], [], [], [], '-2d -s')
%
% See also chull_tree vhull_tree
% Uses cyl_tree ver_tree X Y (Z)
%
% the TREES toolbox: edit, visualize and analyze neuronal trees
% Copyright (C) 2009  Hermann Cuntz

function [c M HP] = hull_tree (intree, thr, bx, by, bz, options)

% trees : contains the tree structures in the trees package
global trees

if (nargin <6)||isempty(options),
    % {DEFAULT: waitbar, show result and output full distance matrix}
    options = '-w -s -F';
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

if (nargin <2)||isempty(thr),
    thr = 25; % {DEFAULT: 25 um distance threshold}
end

if (nargin <3)||isempty(bx),
    bx = 50; % {DEFAULT: divide x axis in 50 pieces}
end

if (nargin <4)||isempty(by),
    by = 50; % {DEFAULT: divide y axis in 50 pieces}
end

if (nargin <5)||isempty(bz),
    bz = 50; % {DEFAULT: divide z axis in 50 pieces}
end

% calculate bx/by/bz values for the grid
if numel(bx)==1,
    bx = min (X) - 2*thr : (4*thr + max (X) - min (X)) / bx : max (X) + 2*thr;
end
if numel(by)==1,
    by = min (Y) - 2*thr : (4*thr + max (Y) - min (Y)) / by : max (Y) + 2*thr;
end

if isempty (strfind (options, '-2d')), % 3D option
    if numel (bz) == 1, % only here do you need bz of course
        bz = min (Z) - 2*thr : (4*thr + max (Z) - min (Z)) / bz : max (Z) + 2*thr;
    end
    len = length (by); % we will go about line by line on y-axis
    M = zeros (len, length (bx), length (bz));
    [X1, X2, Y1, Y2, Z1, Z2] = cyl_tree (intree); % segment start and end coordinates
    
    X1 = repmat (X1, 1, len); % create Nxlen comparison matrices
    X2 = repmat (X2, 1, len);
    Y1 = repmat (Y1, 1, len);
    Y2 = repmat (Y2, 1, len);
    Z1 = repmat (Z1, 1, len);
    Z2 = repmat (Z2, 1, len);
    
    if strfind (options, '-w'), % waitbar option: initialization
        HW = waitbar (0, 'building up distance matrix ...');
        set (HW, 'Name', '..PLEASE..WAIT..YEAH..');
    end
    for te = 1 : length (bz),
        if strfind (options, '-w'), % waitbar option: update
            waitbar (te ./ length (bz), HW);
        end
        for ward = 1 : length (bx),
            XP = ones (size (X1, 1), len) .* bx (ward);
            YP = repmat (by, size (X1, 1), 1);
            ZP = ones (size (X1, 1), len) .* bz (te);
            % oh yeah it's the full palette, calculate distance from each
            % point to the line between two nodes of the tree:
            warning ('off', 'MATLAB:divideByZero');
            u = ((XP - X1).*(X2 - X1) + (YP - Y1).*(Y2 - Y1) + (ZP - Z1).*(Z2 - Z1)) ./ ...
                ((X2 - X1).^2 + (Y2 - Y1).^2 + (Z2 - Z1).^2);
            warning ('on',  'MATLAB:divideByZero');
            u (isnan (u)) = 0;
            u (u < 0)     = 0;
            u (u > 1)     = 1;
            Xu = X1 + u.*(X2 - X1);
            Yu = Y1 + u.*(Y2 - Y1);
            Zu = Z1 + u.*(Z2 - Z1);
            dist = sqrt((XP - Xu).^2 + (YP - Yu).^2 + (ZP - Zu).^2);
            i1 = min (dist);
            M (:, ward, te)  = reshape (i1, len, 1, 1); % build up distance matrix
        end
    end
    if strfind (options, '-w'), % waitbar option: close
        close (HW);
    end
    c = isosurface (bx, by, bz, M, thr);
    if strfind (options, '-s'), % show option
        HP = patch (c);
        set (HP, 'FaceColor', 'red', 'EdgeColor', 'none', 'facealpha', 0.3);
        axis equal
    end
else % 2D option:
    [X1, X2, Y1, Y2] = cyl_tree (intree, '-2d');
    lenx = length (bx);
    leny = length (by);
    len2 = lenx * leny; % estimate expense of calculation
    if len2 > 256, % if that is large than split up:
        BX = bx;
        M = zeros (leny, lenx);
        lenx = 1;
        len2 = leny;
        X1 = repmat (X1, 1, len2); % create Nx1xleny comparison matrices
        Y1 = repmat (Y1, 1, len2);
        X2 = repmat (X2, 1, len2);
        Y2 = repmat (Y2, 1, len2);
        if strfind (options, '-w'),
            HW = waitbar (0, 'building up distance matrix ...');
            set (HW, 'Name', 'please wait...');
        end
        for ward = 1 : length (BX),
            if strfind (options, '-w'),
                waitbar (ward ./ length (BX), HW);
            end
            bx = BX (ward);
            XP = repmat (reshape (repmat (bx,  leny, 1),    1, len2), size (X1, 1), 1);
            YP = repmat (reshape (repmat (by', 1,    lenx), 1, len2), size (X1, 1), 1);
            % oh yeah it's the full palette, calculate distance from each
            % point to the line between two nodes of the tree:
            warning ('off', 'MATLAB:divideByZero');
            u = ((XP - X1).*(X2 - X1) + (YP - Y1).*(Y2 - Y1))./((X2 - X1).^2+(Y2 - Y1).^2);
            warning ('on',  'MATLAB:divideByZero');
            u (isnan (u)) = 0;
            u (u < 0)     = 0;
            u (u > 1)     = 1;
            Xu = X1 + u.*(X2 - X1);
            Yu = Y1 + u.*(Y2 - Y1);
            dist = sqrt ((XP - Xu).^2+(YP - Yu).^2);
            i1 = min (dist);
            M (:, ward)  = reshape (i1, leny, lenx); % build up distance matrix
        end
        bx = BX;
        if strfind (options, '-w'),
            close (HW);
        end
    else
        X1 = repmat (X1, 1, len2); % create full Nx1xlen2 comparison matrices
        Y1 = repmat (Y1, 1, len2);
        X2 = repmat (X2, 1, len2);
        Y2 = repmat (Y2, 1, len2);
        XP = repmat (reshape (repmat (bx,  leny, 1),    1, len2), size (X1, 1), 1);
        YP = repmat (reshape (repmat (by', 1,    lenx), 1, len2), size (X1, 1), 1);
        % oh yeah it's the full palette, calculate distance from each
            % point to the line between two nodes of the tree:
        warning ('off', 'MATLAB:divideByZero');
        u = ((XP - X1).*(X2 - X1) + (YP - Y1).*(Y2 - Y1)) ./ ((X2 - X1).^2+(Y2 - Y1).^2);
        warning ('on',  'MATLAB:divideByZero');
        u (isnan (u)) = 0;
        u (u < 0)     = 0;
        u (u > 1)     = 1;
        Xu = X1 + u.*(X2 - X1);
        Yu = Y1 + u.*(Y2 - Y1);
        dist = sqrt ((XP - Xu).^2+(YP - Yu).^2);
        i1 = min (dist);
        M = reshape (i1, leny, lenx); % build up distance matrix
    end
    c = contourc (bx, by, M, [thr thr]); % use contour to find isoline
    c = c'; % checkout "cpoints" and "cplotter" to find out more about contour convention
    if strfind (options, '-s')
        HP = cplotter (c); axis equal;
    end
end

if isempty (strfind (options, '-F')), % threshold distance matrix
    M = M < thr;
end
