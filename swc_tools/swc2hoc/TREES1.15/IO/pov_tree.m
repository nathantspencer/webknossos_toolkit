% POV_TREE   POV-Ray rendering of trees.
% (trees package)
%
% [name path] = pov_tree (intree, name, v, options)
% -------------------------------------------------
%
% writes POV-ray files using the anatomy-data contained in intree.
%
% Input
% -----
% - intree::integer:index of tree in trees or structured tree or
%     cell-array of trees. Also: at any point instead of a full tree give a
%     Nx4 matrix containing points [X Y Z D] rendered as spheres then.
% - name::string: name of file including the extension ".pov"
%     {DEFAULT : open gui fileselect} spaces and other weird symbols not
%     allowed!
% - v::vector: values to be color-coded, cell array if for more than one
%     tree, same organization as intree.
% - options::string: {DEFAULT: '-b -w', because blob much much faster}
%     '-b' : blob, draws a skin around the cylinders
%     '-s' : show, write an extra standard file to display the povray object -
%        filename is same but starts with 'sh'. Options are -s1.. -s6.
%        -s1 : green fluorescence on black {DEFAULT}
%        -s2 : black on sand (add a photoshop canvas texture afterwards)
%        -s3 : black on white (no color mapping either)
%        -s4 : alien
%        -s5 : glass on cork
%        -s6 : red coral and watersurface on z = 0 plane
%     '-w' : waitbar
%     '-v' : adopt viewpoint from currently active axis
%     '-c' : brainbow colors (and '-z' sharp contrast brainbow)
%     '-minmax' : normalizes v values between min and max before
%         coloring, else: normalizes v values from zero to max before coloring
%     '->' : send directly to windows (necessitates -s option)
%
% Output
% ------
% - name::string: name of output file; [] no file was selected -> no output
% - path::sting: path of the file, complete string is therefore: [path name]
% - rpot::vector:output is the binned vector used for the coloring
%
% Example
% -------
% pov_tree (sample_tree, [], [], '-w -b -s ->')
%
% See also plot_tree x3d_tree swc_tree
% Uses len_tree cyl_tree D
%
% the TREES toolbox: edit, visualize and analyze neuronal trees
% Copyright (C) 2009  Hermann Cuntz

function [tname path rpot] = pov_tree (intree, tname, v, options)

% trees : contains the tree structures in the trees package
global trees

if (nargin<1)||isempty(intree),
    intree = length(trees); % {DEFAULT tree: last tree in trees cell array}
end;

% defining a name for the povray-tree
if (nargin<2)||isempty(tname),
    [tname path] = uiputfile ('.pov', 'export to POV-Ray', 'tree.pov');
    if tname  == 0,
        tname = [];
        return
    end
else
    path = '';
end
% extract a sensible name from the filename string:
nstart = unique ([0 strfind(tname, '/') strfind(tname, '\')]);
name = tname (nstart (end) + 1 : end - 4);
if nstart (end) > 0,
    path = [path tname(1 : nstart (end))];
    tname (1 : nstart (end)) = '';
end
name2 = [path name '.dat']; % imaging file, if v not empty or '-c' option
name3 = [path 'sh' name '.pov']; % show file, with '-s' option

if (nargin<3)||isempty(v),
    v = []; % {DEFAULT: no color mapping}
end

if (nargin<4)||isempty(options),
    options = '-b -w'; % {DEFAULT: blobs and waitbar}
end

if isempty (v) && isempty (strfind (options, '-c'))  && isempty (strfind (options, '-z')),
    iflag = 0; % imaging is off, no specified colors.
else
    iflag = 1; % imaging is on, colors specified by v or random (brainbow)
    map    = jet (256);     % colormap, change if necessary
    lenm   = size (map, 1); % number of colormap entries
    povray = fopen (name2, 'w'); % open file
    if strfind (options, '-c') % brainbow
        if iscell (intree), % many cells
            rpot = cell (1, length (intree)); % concatenate all values between 0 and 1
            for ward = 1 : length (intree)
                if isstruct (intree {ward})
                    len    = len_tree (intree{ward});
                    lenner = sum (len > 0.0001);
                else
                    lenner = size (intree {ward}, 1);
                end
                colorcode = repmat   (rand (1, 3), lenner, 1);
                colorcode = reshape  (colorcode', numel (colorcode), 1);
                rpot {ward} = repmat (ward / length (intree), lenner, 1);
                fprintf (povray, '%12.8f,\n', colorcode);
            end
        else % single cell: random color
            rpot = {};
            if isstruct (intree) || (numel (intree) == 1),
                len    = len_tree (intree);
                lenner = sum (len > 0.0001);
            else
                lenner = size (intree, 1);
            end
            colorcode = repmat  (rand (1, 3), lenner, 1);
            colorcode = reshape (colorcode', numel (colorcode), 1);
            rpot {1}  = zeros   (lenner, 1);
            fprintf (povray, '%12.8f,\n', colorcode);
        end
    elseif strfind (options, '-z') % brainbow high contrast
        if iscell (intree), % many cells
            rpot = cell (1, length (intree)); % concatenate all values between 0 and 1
            for ward = 1 : length (intree)
                if isstruct (intree {ward})
                    len    = len_tree (intree {ward});
                    lenner = sum (len > 0.0001);
                else
                    lenner = size (intree {ward}, 1);
                end
                R = rand (1, 3); R = R - min (R); R = R ./ max (R);
                colorcode = repmat   (R, lenner, 1);
                colorcode = reshape  (colorcode', numel (colorcode), 1);
                rpot {ward} = repmat (ward / length (intree), lenner, 1);
                fprintf (povray, '%12.8f,\n', colorcode);
            end
        else % single cell: random color
            rpot = {};
            if isstruct (intree) || (numel (intree) == 1),
                len    = len_tree (intree);
                lenner = sum (len > 0.0001);
            else
                lenner = size (intree, 1);
            end
            R = rand (1, 3); R = R - min (R); R = R ./ max (R);
            colorcode = repmat  (R, lenner, 1);
            colorcode = reshape (colorcode', numel (colorcode), 1);
            rpot {1}  = zeros   (lenner, 1);
            fprintf (povray, '%12.8f,\n', colorcode);
        end
    else
        if iscell (intree),
            if isstruct (intree {1})
                len = len_tree (intree {1});
            else
                len = ones (size (intree {1}, 1), 1);
            end
            vt = v {1};
            if size (vt, 2) == 3,
                rpot = cell (1, length (intree));
                for ward = 1 : length (intree),
                    if isstruct (intree {ward})
                        len = len_tree (intree {ward});
                    else
                        len = ones( size (intree {ward}, 1), 1);
                    end
                    vt = v {ward};
                    if islogical (vt), vt = double (vt); end
                    vt = vt (len > 0.0001, :);
                    colorcode = reshape (vt', length (vt) * 3, 1);
                    rpot {ward} = vt;
                    fprintf (povray, '%12.8f,\n', colorcode);
                end
            else
                if islogical (vt), vt = double (vt); end
                vt = vt (len > 0.0001);
                if isempty (strfind (options, '-minmax')),
                    irange = [min(vt) max(vt)];
                else
                    irange = [0 max(vt)];
                end
                for ward = 2 : length (intree) % first find v value range
                    if isstruct (intree {ward})
                        len = len_tree (intree {ward});
                    else
                        len = ones (size (intree {ward}, 1), 1);
                    end
                    vt = v {ward};
                    if islogical (vt), vt = double (vt); end
                    vt = vt (len > 0.0001);
                    if max (vt) > irange (2),
                        irange (2) = max (vt);
                    end
                    if strfind (options, '-minmax'),
                        if min (vt) < irange (1),
                            irange (1) = min (vt);
                        end
                    end
                end
                rpot = cell (1, length (intree));
                for ward = 1 : length (intree)
                    if isstruct (intree {ward})
                        len = len_tree (intree {ward});
                    else
                        len = ones (size (intree {ward}, 1), 1);
                    end
                    vt = v {ward};
                    if islogical (vt), vt = double (vt); end
                    vt = vt (len > 0.0001);
                    vt = floor ((vt - irange (1)) ./ ((irange (2) - irange (1)) ./ lenm));
                    vt (vt < 1) = 1; vt (vt > lenm) = lenm;
                    colorcode = map (vt, :);
                    colorcode = reshape (colorcode', length (vt) * 3, 1);
                    rpot {ward} = vt;
                    fprintf (povray, '%12.8f,\n', colorcode);
                end
            end
        else
            if isstruct (intree) || (numel (intree) == 1),
                len = len_tree (intree);
            else
                len = ones (size (intree, 1), 1);
            end
            if size (v, 2) == 3,
                if islogical (v), v = double (v); end
                v = v (len > 0.0001, :);
                colorcode = reshape (v', length (v) * 3, 1);
                rpot = {}; rpot {1} = v;
                fprintf (povray, '%12.8f,\n', colorcode);
            else
                if islogical (v), v = double (v); end
                v = v (len > 0.0001);
                if strfind (options, '-minmax'),
                    irange = [min(v) max(v)];
                else
                    irange = [0 max(v)];
                end
                v = floor((v - irange (1))./((irange (2) - irange (1)) ./ lenm));
                v (v < 1) = 1; v (v > lenm) = lenm;
                colorcode = map (v, :);
                colorcode = reshape (colorcode', length (v) * 3, 1);
                rpot = {}; rpot {1} = v;
                fprintf (povray, '%12.8f,\n', colorcode);
            end
        end
    end
    fclose (povray); % close file
end

if iscell (intree),
    if strfind (options, '-s') % show option: extra file
        X = cell (length (intree), 1); Y = cell (length (intree), 1);
        for ward = 1 : length (intree),
            if isstruct (intree {ward}),
                X {ward} = intree {ward}.X;      Y {ward} = intree {ward}.Y;
            else
                X {ward} = intree {ward} (:, 1); Y {ward} = intree {ward} (:, 2);
            end
        end
    end
    % file-pointer to the povray-file
    povray = fopen ([path tname], 'w');
    % Writing the cylinders into a povray variable called 'name'
    fwrite (povray, ['#declare ' name ' = union{', char(13), char(10)], 'char');
    if strfind (options, '-w') % waitbar option: initialization
        HW = waitbar (0, 'writing trees ...');
        set (HW, 'Name', '..PLEASE..WAIT..YEAH..');
    end
    for te = 1 : length (intree),
        if strfind (options, '-w') % waitbar option: update
            if mod (te, 500) == 0,
                waitbar (te ./ length (intree), HW);
            end
        end
        if isstruct (intree {te}),
            if strfind (options, '-b'), % blob option: skin around bodies, faster but sloppier
                fwrite (povray, ['blob { threshold .15  // cell obj #', num2str(te), ...
                    char(13), char(10)], 'char');
            end
            D   = intree {te}.D;
            cyl = cyl_tree (intree {te});
            len = len_tree (intree {te});
            N   = length (D);
            for ward = 1 : N,
                if len (ward) > 0.0001,
                    fwrite (povray, ['cylinder { <',   num2str(cyl (ward, 1)),  ',', ...
                        num2str(cyl (ward, 3)), ',',   num2str(cyl (ward, 5)),  '>, <', ...
                        num2str(cyl (ward, 2)), ',',   num2str(cyl (ward, 4)),  ',', ...
                        num2str(cyl (ward, 6)), '>, ', num2str(D (ward) ./ 2)], 'char');
                    if strfind (options, '-b') % blob option: skin around bodies, faster but sloppier
                        fwrite (povray, ', 1', 'char');
                    end
                    if iflag
                        fwrite (povray, [' texture {#read (inning, R) #read (inning, G) #read (inning, B) ', ...
                            'pigment {color red R green G blue B}}'], 'char');
                    end
                    fwrite (povray, ['}', char(13), char(10)], 'char');
                end
            end
        else
            if strfind (options, '-b'), % blob option: skin around bodies, faster but sloppier
                fwrite (povray, ['blob { threshold .15  // points obj #', num2str(te), ...
                    char(13), char(10)], 'char');
            end
            for ward = 1 : size (intree {te}, 1),
                fwrite (povray, ['sphere { <', num2str(intree {te} (ward, 1)), ',', ...
                    num2str(intree {te} (ward, 2)), ',', num2str(intree {te} (ward, 3)), '>, ', ...
                    num2str(intree {te} (ward, 4) ./ 2)], 'char');
                if findstr (options, '-b'),
                    fwrite (povray, ', 1', 'char');
                end
                if iflag,
                    fwrite (povray, [' texture {#read (inning, R) #read (inning, G) #read (inning, B) ', ...
                        'pigment {color red R green G blue B}}'], 'char');
                end
                fwrite (povray, ['}', char(13), char(10)], 'char');
            end
        end
        if strfind (options, '-b'), % blob option: skin around bodies, faster but sloppier
            fwrite (povray, ['}', char(13), char(10)], 'char');
        end
    end
    if strfind (options, '-w') % waitbar option: close
        close (HW);
    end
    fwrite (povray, ['}', char(13), char(10)], 'char');
    fclose (povray);
else
    X = {}; Y = {};
    if ~isstruct (intree),
        if (numel (intree) == 1)
            D = trees {intree}.D;
            if strfind (options, '-s') % show option: extra file
                X {1} = trees {intree}.X;
                Y {1} = trees {intree}.Y;
            end
        else
            if strfind (options, '-s') % show option: extra file
                X {1} = intree (:, 1);
                Y {1} = intree (:, 2);
            end
        end
    else
        D = intree.D;
        if strfind (options, '-s') % show option: extra file
            X {1} = intree.X;
            Y {1} = intree.Y;
        end
    end
    % file-pointer to the povray-file
    povray = fopen ([path tname], 'w');
    % Writing the cylinders into a povray variable called 'name'
    fwrite (povray, ['#declare ' name ' = union{', char(13), char(10)], 'char');
    if strfind (options, '-w') % waitbar option: initialization
        HW = waitbar (0, 'writing cylinders ...');
        set (HW, 'Name', '..PLEASE..WAIT..YEAH..');
    end
    if strfind (options, '-b'), % blob option: skin around bodies, faster but sloppier
        fwrite (povray, ['blob { threshold .15', char(13), char(10)], 'char');
    end
    if isstruct (intree) || (numel (intree) == 1),
        N   = length (D);
        cyl = cyl_tree (intree);
        len = len_tree (intree);
        for ward = 1 : N,
            if strfind (options, '-w') % waitbar option: update
                if mod (ward, 500) == 0,
                    waitbar (ward ./ N, HW);
                end
            end
            if len (ward) > 0.0001,
                fwrite (povray ,['cylinder { <',   num2str(cyl (ward, 1)),  ',', ...
                    num2str(cyl (ward, 3)), ',',   num2str(cyl (ward, 5)),  '>, <', ...
                    num2str(cyl (ward, 2)), ',',   num2str(cyl (ward, 4)),  ',', ...
                    num2str(cyl (ward, 6)), '>, ', num2str(D (ward) ./ 2)], 'char');
                if strfind (options, '-b'), % blob option: skin around bodies, faster but sloppier
                    fwrite (povray, ', 1', 'char');
                end
                if iflag
                    fwrite (povray, [' texture {#read (inning, R) #read (inning, G) #read (inning, B) ', ...
                        'pigment {color red R green G blue B}}'], 'char');
                end
                fwrite (povray, ['}', char(13), char(10)], 'char');
            end
        end
    else
        for ward = 1 : size (intree, 1),
            if findstr (options, '-w'), % waitbar option: update
                if mod (ward, 500) == 0,
                    waitbar (ward ./ size (intree, 1), HW);
                end
            end
            fwrite (povray, ['sphere { <', num2str(intree (ward, 1)), ',', ...
                num2str(intree (ward, 2)), ',', num2str(intree (ward, 3)), '>, ', ...
                num2str(intree (ward, 4) ./ 2)], 'char');
            if findstr (options, '-b'),
                fwrite (povray, ', 1', 'char');
            end
            if iflag,
                fwrite (povray, [' texture {#read (inning, R) #read (inning, G) #read (inning, B) ', ...
                    'pigment {color red R green G blue B}}'], 'char');
            end
            fwrite (povray, ['}', char(13), char(10)], 'char');
        end
    end
    if strfind (options, '-w') % waitbar option: close
        close (HW);
    end
    fwrite (povray, ['}', char(13), char(10)], 'char');
    if strfind (options, '-b'), % blob option: skin around bodies, faster but sloppier
        fwrite (povray, ['}', char(13), char(10)], 'char');
    end
    fclose (povray);
end

if strfind (options, '-s') % show option: extra file
    a1 = strfind (options, '-s');
    if length (options) > a1 + 1
        typ = str2double (options (a1 + 2));
        if isnan (typ),
            typ = 1;
        end
    else
        typ = 1;
    end
    povray = fopen (name3, 'w');
    X  = cat (1, X {:}); Y = cat (1, Y {:});
    dX = abs (max (X) - min (X));
    mX = min (X)+(max (X) - min (X)) ./ 2;
    mY = min (Y)+(max (Y) - min (Y)) ./ 2;
    if strfind (options, '-v'),
        ax = get (gcf, 'CurrentAxes');
        if ~isempty (ax),
            cpos =   get (ax, 'cameraposition');
            cangle = get (ax, 'cameraviewangle') * 1.3;
            tpos =   get (ax, 'cameratarget');
            skyvec = get (ax, 'CameraUpVector');
            uvec =   [1 0 0];
            cX = cpos (1); cY = cpos (2); cZ = cpos (3);
            tX = tpos (1); tY = tpos (2); tZ = tpos (3);
        else
             cX = mX; cY = mY; cZ = -dX;
             tX = mX; tY = mY; tZ = 0; cangle = 65;
        end
    else
       cX = mX; cY = mY; cZ = -dX;
       tX = mX; tY = mY; tZ = 0; cangle = 65;
    end
    
    if iflag
        fwrite (povray, ['#fopen inning "' name '.dat" read', char(13), char(10)], 'char');
    end
    fwrite (povray, ['#include "' name '.pov"', char(13), char(10)], 'char');
    fwrite (povray, ['#include "colors.inc"', char(13), char(10)], 'char');
    switch typ
        case 1
            fwrite (povray, ['', char(13), char(10)], 'char');
            fwrite (povray, ['background {rgbt <0,0,0,0.75>}', char(13), char(10)], 'char');
            fwrite (povray, ['camera {', char(13), char(10)], 'char');
            if strfind (options, '-v'),
                fwrite (povray, ['  sky<' num2str(skyvec (1)), ',' , num2str(skyvec (2)), ',' ,...
                    num2str(skyvec (3)), '>' , char(13), char(10)], 'char');
                fwrite (povray, ['  up<' num2str(uvec (1)), ',' , num2str(uvec (2)), ',' ,...
                    num2str(uvec (3)), '>' , char(13), char(10)], 'char');
            end
            fwrite (povray, ['  right x*image_width/image_height', char(13), char(10)], 'char');
            fwrite (povray, ['  location <' num2str(cX) ',' num2str(cY) ',' num2str(cZ) '>', char(13), char(10)], 'char');
            fwrite (povray, ['  look_at <' num2str(tX) ',' num2str(tY) ',' num2str(tZ) '>', char(13), char(10)], 'char');
            fwrite (povray, ['  /*focal_point <' num2str(tX) ',' num2str(tY) ',' num2str(tZ) '-150> ', char(13), char(10)], 'char');
            fwrite (povray, ['  aperture 50 // increase for more focal blur', char(13), char(10)], 'char');
            fwrite (povray, ['  blur_samples 150*/ // add focal blur if you want', char(13), char(10)], 'char');
            fwrite (povray, ['  angle ' num2str(cangle), char(13), char(10)], 'char');
            fwrite (povray, ['}', char(13), char(10)], 'char');
            fwrite (povray, ['',  char(13), char(10)], 'char');
            fwrite (povray, ['light_source  { <' num2str(cX) ',' num2str(cY) ',' num2str(cZ) '> White fade_distance 500}', char(13), char(10)], 'char');
            fwrite (povray, ['',  char(13), char(10)], 'char');
            fwrite (povray, ['/*plane { // uncomment for water surface', char(13), char(10)], 'char');
            fwrite (povray, ['  z, 50', char(13), char(10)], 'char');
            fwrite (povray, ['  pigment{rgbt <1,1,0.9,0.95>}', char(13), char(10)], 'char');
            fwrite (povray, ['  finish {ambient 0.15 diffuse 1 brilliance 16.0 reflection 0}', char(13), char(10)], 'char');
            fwrite (povray, ['  normal {bumps 0.5 scale 120 turbulence .1}', char(13), char(10)], 'char');
            fwrite (povray, ['} ', char(13), char(10)], 'char');
            fwrite (povray, ['', char(13), char(10)], 'char');
            fwrite (povray, ['plane {', char(13), char(10)], 'char');
            fwrite (povray, ['  z, -200', char(13), char(10)], 'char');
            fwrite (povray, ['  pigment{rgbt <1,1,0.9,0.95>}', char(13), char(10)], 'char');
            fwrite (povray, ['  finish {ambient 0.15 diffuse 0.55  brilliance 16.0 reflection 0.5}', char(13), char(10)], 'char');
            fwrite (povray, ['  normal {bumps 0.5 scale 60 turbulence .1}', char(13), char(10)], 'char');
            fwrite (povray, ['} */ ', char(13), char(10)], 'char');
            fwrite (povray, ['', char(13), char(10)], 'char');
            fwrite (povray, ['light_source {', char(13), char(10)], 'char');
            fwrite (povray, ['  <0, 0, 0>', char(13), char(10)], 'char');
            fwrite (povray, ['  color rgb  <1, 1, 0>', char(13), char(10)], 'char');
            fwrite (povray, ['  looks_like {' name, char(13), char(10)], 'char');
            fwrite (povray, ['    texture {', char(13), char(10)], 'char');
            fwrite (povray, ['      pigment {rgbft <0.2, 1.0, 0.2, 0.15,0.5>}', char(13), char(10)], 'char');
            fwrite (povray, ['      finish {ambient 0.8 diffuse 0.6 reflection .28 ior 3 specular 1 roughness .001}', char(13), char(10)], 'char');
            fwrite (povray, ['    }', char(13), char(10)], 'char');
            fwrite (povray, ['  }', char(13), char(10)], 'char');
            fwrite (povray, ['}', char(13), char(10)], 'char');
            fclose (povray);
        case 2
            fwrite (povray, ['', char(13), char(10)], 'char');
            fwrite (povray, ['background {rgbt <0.95,0.85,0.75,0.55>}', char(13), char(10)], 'char');
            fwrite (povray, ['camera {', char(13), char(10)], 'char');
            if strfind(options,'-v'),
                fwrite (povray, ['  sky<' num2str(skyvec (1)), ',' , num2str(skyvec (2)), ',' ,...
                    num2str(skyvec (3)), '>' , char(13), char(10)], 'char');
                fwrite (povray, ['  up<' num2str(uvec (1)), ',' , num2str(uvec (2)), ',' ,...
                    num2str(uvec (3)), '>' , char(13), char(10)], 'char');
            end
            fwrite (povray, ['  right x*image_width/image_height', char(13), char(10)], 'char');
            fwrite (povray, ['  location <' num2str(cX) ',' num2str(cY) ',' num2str(cZ) '>', char(13), char(10)], 'char');
            fwrite (povray, ['  look_at <' num2str(tX) ',' num2str(tY) ',' num2str(tZ) '>', char(13), char(10)], 'char');
            fwrite (povray, ['  angle ' num2str(cangle), char(13), char(10)], 'char');
            fwrite (povray, ['}', char(13), char(10)], 'char');
            fwrite (povray, ['', char(13), char(10)], 'char');
            fwrite (povray, ['light_source  { <' num2str(cX) ',' num2str(cY) ',' num2str(cZ) '> White fade_distance 500}', char(13), char(10)], 'char');
            fwrite (povray, ['', char(13), char(10)], 'char');
            fwrite (povray, ['plane {    // paper 1', char(13), char(10)], 'char');
            fwrite (povray, ['  z, 50', char(13), char(10)], 'char');
            fwrite (povray, ['  pigment{ color rgbt <.95,.95,0.05,0.7>}', char(13), char(10)], 'char');
            fwrite (povray, ['  normal {wrinkles 1 scale 0.4}', char(13), char(10)], 'char');
            fwrite (povray, ['  finish {diffuse .7 roughness .085 ambient 0.1}', char(13), char(10)], 'char');
            fwrite (povray, ['} ', char(13), char(10)], 'char');
            fwrite (povray, ['', char(13), char(10)], 'char');
            fwrite (povray, ['plane {    // paper 2', char(13), char(10)], 'char');
            fwrite (povray, ['  z, 51', char(13), char(10)], 'char');
            fwrite (povray, ['  pigment{ color rgbt <1,0,0,0.85>}', char(13), char(10)], 'char');
            fwrite (povray, ['  normal {wrinkles 1 scale 100}', char(13), char(10)], 'char');
            fwrite (povray, ['  finish {diffuse .7 roughness .085 ambient 0.1}', char(13), char(10)], 'char');
            fwrite (povray, ['} ', char(13), char(10)], 'char');
            fwrite (povray, ['', char(13), char(10)], 'char');
            fwrite (povray, ['plane {    // paper 3', char(13), char(10)], 'char');
            fwrite (povray, ['  z, 52', char(13), char(10)], 'char');
            fwrite (povray, ['  pigment{ color rgbt <.5,1,0,.85>}', char(13), char(10)], 'char');
            fwrite (povray, ['  normal {wrinkles 1 scale 1}', char(13), char(10)], 'char');
            fwrite (povray, ['  finish {diffuse .7 roughness .85 ambient 0.1}', char(13), char(10)], 'char');
            fwrite (povray, ['} ', char(13), char(10)], 'char');
            fwrite (povray, ['', char(13), char(10)], 'char');
            fwrite (povray, ['light_source {', char(13), char(10)], 'char');
            fwrite (povray, ['  <0, 0, 0>', char(13), char(10)], 'char');
            fwrite (povray, ['  color rgbt  <0, 0, 0, 0.5>', char(13), char(10)], 'char');
            fwrite (povray, ['  looks_like {' name, char(13), char(10)], 'char');
            fwrite (povray, ['    normal {wrinkles 1 scale 0.4}', char(13), char(10)], 'char');
            fwrite (povray, ['    finish {diffuse .7 roughness .085 ambient 0.1}', char(13), char(10)], 'char');
            fwrite (povray, ['  }', char(13), char(10)], 'char');
            fwrite (povray, ['}', char(13), char(10)], 'char');
            fclose (povray);
        case 3
            fwrite (povray, ['', char(13), char(10)], 'char');
            fwrite (povray, ['background {rgbt <1,1,1,0>}', char(13), char(10)], 'char');
            fwrite (povray, ['camera {', char(13), char(10)], 'char');
            if strfind(options,'-v'),
                fwrite (povray, ['  sky<' num2str(skyvec (1)), ',' , num2str(skyvec (2)), ',' ,...
                    num2str(skyvec (3)), '>' , char(13), char(10)], 'char');
                fwrite (povray, ['  up<' num2str(uvec (1)), ',' , num2str(uvec (2)), ',' ,...
                    num2str(uvec (3)), '>' , char(13), char(10)], 'char');
            end
            fwrite (povray, ['  right x*image_width/image_height', char(13), char(10)], 'char');
            fwrite (povray, ['  location <' num2str(cX) ',' num2str(cY) ',' num2str(cZ) '>', char(13), char(10)], 'char');
            fwrite (povray, ['  look_at <' num2str(tX) ',' num2str(tY) ',' num2str(tZ) '>', char(13), char(10)], 'char');
            fwrite (povray, ['  angle ' num2str(cangle), char(13), char(10)], 'char');
            fwrite (povray, ['}', char(13), char(10)], 'char');
            fwrite (povray, ['', char(13), char(10)], 'char');
            fwrite (povray, ['light_source  { <' num2str(cX) ',' num2str(cY) ',' num2str(cZ) '>}', char(13), char(10)], 'char');
            fwrite (povray, ['', char(13), char(10)], 'char');
            fwrite (povray, ['light_source {', char(13), char(10)], 'char');
            fwrite (povray, ['  <0, 0, 0>', char(13), char(10)], 'char');
            fwrite (povray, ['  color rgbt  <0, 0, 0, 0.5>', char(13), char(10)], 'char');
            fwrite (povray, ['  looks_like {' name '}', char(13), char(10)], 'char');
            fwrite (povray, ['}', char(13), char(10)], 'char');
            fclose (povray);
        case 4
            fwrite (povray, ['', char(13), char(10)], 'char');
            fwrite (povray, ['background {rgbt <0.05,0.05,0.05,0.75>}', char(13), char(10)], 'char');
            fwrite (povray, ['camera {', char(13), char(10)], 'char');
            if strfind(options,'-v'),
                fwrite (povray, ['  sky<' num2str(skyvec (1)), ',' , num2str(skyvec (2)), ',' ,...
                    num2str(skyvec (3)), '>' , char(13), char(10)], 'char');
                fwrite (povray, ['  up<' num2str(uvec (1)), ',' , num2str(uvec (2)), ',' ,...
                    num2str(uvec (3)), '>' , char(13), char(10)], 'char');
            end
            fwrite (povray, ['  right x*image_width/image_height', char(13), char(10)], 'char');
            fwrite (povray, ['  location <' num2str(cX) ',' num2str(cY) ',' num2str(cZ) '>', char(13), char(10)], 'char');
            fwrite (povray, ['  look_at <' num2str(tX) ',' num2str(tY) ',' num2str(tZ) '>', char(13), char(10)], 'char');
            fwrite (povray, ['  angle ' num2str(cangle), char(13), char(10)], 'char');
            fwrite (povray, ['}', char(13), char(10)], 'char');
            fwrite (povray, ['', char(13), char(10)], 'char');
            fwrite (povray, ['light_source  { <' num2str(cX) ',' num2str(cY) ',' num2str(cZ) '> White fade_distance 500}', char(13), char(10)], 'char');
            fwrite (povray, ['', char(13), char(10)], 'char');
            fwrite (povray, ['plane {', char(13), char(10)], 'char');
            fwrite (povray, ['  z, 50', char(13), char(10)], 'char');
            fwrite (povray, ['  pigment{rgbt <1,1,0.5,0.75>}', char(13), char(10)], 'char');
            fwrite (povray, ['  finish {ambient 0.15 diffuse 1 brilliance 16.0 reflection 0}', char(13), char(10)], 'char');
            fwrite (povray, ['  normal {bumps 0.5 scale 120 turbulence .1}', char(13), char(10)], 'char');
            fwrite (povray, ['} ', char(13), char(10)], 'char');
            fwrite (povray, ['', char(13), char(10)], 'char');
            fwrite (povray, ['plane {', char(13), char(10)], 'char');
            fwrite (povray, ['  z, -200', char(13), char(10)], 'char');
            fwrite (povray, ['  pigment{rgbt <1,1,0.5,0.75>}', char(13), char(10)], 'char');
            fwrite (povray, ['  finish {ambient 0.15 diffuse 0.55 brilliance 16.0 reflection 0.5}', char(13), char(10)], 'char');
            fwrite (povray, ['  normal {bumps 0.5 scale 60 turbulence .1}', char(13), char(10)], 'char');
            fwrite (povray, ['} ', char(13), char(10)], 'char');
            fwrite (povray, ['', char(13), char(10)], 'char');
            fwrite (povray, ['light_source {', char(13), char(10)], 'char');
            fwrite (povray, ['  <0, 0, 0>', char(13), char(10)], 'char');
            fwrite (povray, ['  color rgb  <1, 1, 1>', char(13), char(10)], 'char');
            fwrite (povray, ['  looks_like {' name, char(13), char(10)], 'char');
            fwrite (povray, ['    hollow interior{media {emission 0}}', char(13), char(10)], 'char');
            fwrite (povray, ['    pigment{color rgbt <0.5,0,0,0.2>}', char(13), char(10)], 'char');
            fwrite (povray, ['    normal {wrinkles 1.25 scale 0.35}', char(13), char(10)], 'char');
            fwrite (povray, ['    finish { reflection 0.75}', char(13), char(10)], 'char');
            fwrite (povray, ['  }', char(13), char(10)], 'char');
            fwrite (povray, ['}', char(13), char(10)], 'char');
            fclose (povray);
        case 5
            fwrite (povray, ['#include "textures.inc"', char(13), char(10)], 'char');
            fwrite (povray, ['', char(13), char(10)], 'char');
            fwrite (povray, ['camera {', char(13), char(10)], 'char');
            if strfind(options,'-v'),
                fwrite (povray, ['  sky<' num2str(skyvec (1)), ',' , num2str(skyvec (2)), ',' ,...
                    num2str(skyvec (3)), '>' , char(13), char(10)], 'char');
                fwrite (povray, ['  up<' num2str(uvec (1)), ',' , num2str(uvec (2)), ',' ,...
                    num2str(uvec (3)), '>' , char(13), char(10)], 'char');
            end
            fwrite (povray, ['  right x*image_width/image_height', char(13), char(10)], 'char');
            fwrite (povray, ['  location <' num2str(cX) ',' num2str(cY) ',' num2str(cZ) '>', char(13), char(10)], 'char');
            fwrite (povray, ['  look_at <' num2str(tX) ',' num2str(tY) ',' num2str(tZ) '>', char(13), char(10)], 'char');
            fwrite (povray, ['  angle ' num2str(cangle), char(13), char(10)], 'char');
            fwrite (povray, ['}', char(13), char(10)], 'char');
            fwrite (povray, ['', char(13), char(10)], 'char');
            fwrite (povray, ['light_source  { <' num2str(cX) ',' num2str(cY) ',' num2str(cZ) '> White fade_distance 500}', char(13), char(10)], 'char');
            fwrite (povray, ['', char(13), char(10)], 'char');
            fwrite (povray, ['plane {', char(13), char(10)], 'char');
            fwrite (povray, ['  z, 150', char(13), char(10)], 'char');
            fwrite (povray, ['  texture {White_Wood scale 5}', char(13), char(10)], 'char');
            fwrite (povray, ['} ', char(13), char(10)], 'char');
            fwrite (povray, ['', char(13), char(10)], 'char');
            fwrite (povray, ['light_source {', char(13), char(10)], 'char');
            fwrite (povray, ['  <0, 0, 0>', char(13), char(10)], 'char');
            fwrite (povray, ['  color rgb  <0, 0, 1>', char(13), char(10)], 'char');
            fwrite (povray, ['  looks_like {' name, char(13), char(10)], 'char');
            fwrite (povray, ['    pigment {rgbft <0.2, 0.2, 1, 1,0.7>}', char(13), char(10)], 'char');
            fwrite (povray, ['    finish {ambient 0.1 diffuse 0.1 reflection .2 ior 1 specular 1 roughness .001}', char(13), char(10)], 'char');
            fwrite (povray, ['  }', char(13), char(10)], 'char');
            fwrite (povray, ['}', char(13), char(10)], 'char');
            fclose (povray);
        case 6
            fwrite (povray, ['', char(13), char(10)], 'char');
            fwrite (povray, ['background {rgbt <0.7,0.7,0.7,0.75>}', char(13), char(10)], 'char');
            fwrite (povray, ['camera {', char(13), char(10)], 'char');
            if strfind(options,'-v'),
                fwrite (povray, ['  sky<' num2str(skyvec (1)), ',' , num2str(skyvec (2)), ',' ,...
                    num2str(skyvec (3)), '>' , char(13), char(10)], 'char');
                fwrite (povray, ['  up<' num2str(uvec (1)), ',' , num2str(uvec (2)), ',' ,...
                    num2str(uvec (3)), '>' , char(13), char(10)], 'char');
            end
            fwrite (povray, ['  right x*image_width/image_height', char(13), char(10)], 'char');
            fwrite (povray, ['  location <' num2str(cX) ',' num2str(cY) ',' num2str(cZ) '>', char(13), char(10)], 'char');
            fwrite (povray, ['  look_at <' num2str(tX) ',' num2str(tY) ',' num2str(tZ) '>', char(13), char(10)], 'char');
            fwrite (povray, ['  /*focal_point <' num2str(tX) ',' num2str(tY) ',' num2str(tZ) '-150> ', char(13), char(10)], 'char');
            fwrite (povray, ['  aperture 50 // increase for more focal blur', char(13), char(10)], 'char');
            fwrite (povray, ['  blur_samples 150*/ // add focal blur if you want', char(13), char(10)], 'char');
            fwrite (povray, ['  angle ' num2str(cangle), char(13), char(10)], 'char');
            fwrite (povray, ['}', char(13), char(10)], 'char');
            fwrite (povray, ['', char(13), char(10)], 'char');
            fwrite (povray, ['light_source  { <' num2str(cX) ',' num2str(cY) ',' num2str(cZ) '> White fade_distance 500}', char(13), char(10)], 'char');
            fwrite (povray, ['', char(13), char(10)], 'char');
            fwrite (povray, ['plane {    //plane of water at z=0', char(13), char(10)], 'char');
            fwrite (povray, ['  z, 0', char(13), char(10)], 'char');
            fwrite (povray, ['  pigment{rgbt <1,1,0.5,0.75>}', char(13), char(10)], 'char');
            fwrite (povray, ['  finish {ambient 0.15 diffuse 0.55 brilliance 6.0 reflection 0.2}', char(13), char(10)], 'char');
            fwrite (povray, ['  normal {bumps 0.5 scale 20 turbulence 1}', char(13), char(10)], 'char');
            fwrite (povray, ['} ', char(13), char(10)], 'char');
            fwrite (povray, ['', char(13), char(10)], 'char');
            fwrite (povray, ['light_source {', char(13), char(10)], 'char');
            fwrite (povray, ['  <0, 0, 0>', char(13), char(10)], 'char');
            fwrite (povray, ['  color rgb  <1, 1, 0>', char(13), char(10)], 'char');
            fwrite (povray, ['  looks_like {' name, char(13), char(10)], 'char');
            fwrite (povray, ['    hollow interior{ media {emission 0}}', char(13), char(10)], 'char');
            fwrite (povray, ['    pigment{ color rgbt <0.5,0,0,0.2>}', char(13), char(10)], 'char');
            fwrite (povray, ['    normal { wrinkles 1.25 scale 0.35}', char(13), char(10)], 'char');
            fwrite (povray, ['  }', char(13), char(10)], 'char');
            fwrite (povray, ['}', char(13), char(10)], 'char');
            fclose (povray);
    end
    if strfind (options, '->')
        if ispc,        % this even calls the file directly (only windows)
            winopen (name3);
        end
    end
end
