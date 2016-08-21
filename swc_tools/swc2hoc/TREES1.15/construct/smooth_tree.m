% SMOOTH_TREE   Smoothens a tree along its longest paths.
% (trees package)
%
% tree = smooth_tree (intree, pwchild, p, n, options)
% ---------------------------------------------------
%
% smoothens a tree along its longest paths. This changes (shortens) the
% total length of the branch significantly. First finds the heavier
% sub-branches and puts them together to longest paths. Then a smoothing
% step is applied on the branches individually. smooth_tree calls
% smoothbranch but this subfunction can be replaced by any other one of a
% similar type.
%
% Input
% -----
% - intree::integer:index of tree in trees or structured tree
% - pwchild::0.5..1: sets the minimum weight asymmetry to choose weighted
%     subbranch {DEFAULT: 0.5} 
% - p::0..1: proportion smoothing at each iteration step {DEFAULT: 0.9}
% - n::integer>0: number of smoothing iterations {DEFAULT: 5}
% - options::string: {DEFAULT: '-w'}
%     '-s' : show
%     '-w' : waitbar
%
% Output
% ------
% if no output is declared the tree is changed in trees
% - tree:: structured output tree
%
% Example
% -------
% smooth_tree (sample_tree, .5, .5, 2, '-s');
%
% See also smoothbranch MST_tree
% Uses dissect_tree ipar_tree child_tree smoothbranch
%
% the TREES toolbox: edit, visualize and analyze neuronal trees
% Copyright (C) 2009  Hermann Cuntz

function  varargout = smooth_tree (intree, pwchild, p, n, options)

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

if (nargin <2)||isempty(pwchild),
    pwchild = 0.5; % {DEFAULT: minimum asymmetry}
end

if (nargin <3)||isempty(p),
    p = 0.9; % {DEFAULT: strong smoothing at each iteration}
end

if (nargin <4)||isempty(n),
    n = 5; % {DEFAULT: five smoothing iterations}
end

if (nargin <5)||isempty(options),
    options = '-w'; % {DEFAULT: waitbar option}
end

sect   = dissect_tree (tree); % starting and end points of all branches
ipar   = ipar_tree    (tree); % parent index structure (see "ipar_tree")
idpar  = ipar         (:, 2); % vector containing index to direct parent
nchild = child_tree   (tree); % number of daugther nodes

if strfind (options, '-w'), % waitbar option: initialization
    HW = waitbar (0, 'finding heavy sub-branches...');
    set (HW, 'Name', '..PLEASE..WAIT..YEAH..');
end
ward = 1;
while ward <= size (sect, 1),
    if strfind (options, '-w'), % waitbar option: update
        if mod (ward, 500) == 0,
            waitbar (ward / (size (sect, 1)), HW);
        end
    end
    dchildren = find (idpar == sect (ward, 2)); % direct children nodes of branch ward
    % index to branches which continue after branch ward
    indi1     = find (sect (:, 1) == sect (ward, 2));
    ep        = sect (indi1, 2); % end nodes of these branches
    wchild    = nchild (dchildren); % weight of child trees
    warning ('off', 'MATLAB:divideByZero'); 
    rwchild   = wchild ./ sum (wchild); % relative weight of child trees
    warning ('on',  'MATLAB:divideByZero');
    if sum (rwchild > pwchild),
        [i1 i2]    = max (rwchild);
        % sub tree of heaviest child tree
        [subs ip2] = ind2sub (size (ipar), find (ipar == dchildren (i2)));
        % index to branch which contains this child tree
        [i1 i2]    = intersect (ep, subs);
        sect (ward,       2) = sect (indi1 (i2), 2);
        sect (indi1 (i2), :) = [];
    else
        ward = ward + 1;
    end
end

if strfind (options, '-w'), % waitbar option: reinitialization
    waitbar (0, HW, 'smoothing heavy sub-branches...');
end
for ward = 1 : size (sect, 1),
    if strfind (options, '-w'), % waitbar option: update
        waitbar (ward / (size (sect, 1)), HW);
    end
    % corresponds to "plotsect_tree":
    indi2 = ipar (sect (ward, 2), 1 : find (ipar (sect (ward, 2), :) == sect (ward, 1)));
    % smoothen the heavier branches (see "smoothbranch")
    [Xs Ys Zs] = smoothbranch (tree.X (indi2), tree.Y (indi2), ...
        tree.Z (indi2), p, n);
    tree.X (indi2) = Xs;
    tree.Y (indi2) = Ys;
    tree.Z (indi2) = Zs;
end
if strfind (options, '-w'), % waitbar option: close
    close (HW);
end

if strfind (options, '-s'), % show option
    clf; shine; hold on; plot_tree (intree); plot_tree (tree, [1 0 0]);
    HP (1) = plot (1, 1, 'k-'); HP (2) = plot (1, 1, 'r-');
    legend (HP, {'before', 'after'}); set(HP, 'visible','off');
    title  ('smoothen tree');
    xlabel ('x [\mum]'); ylabel ('y [\mum]'); zlabel ('z [\mum]');
    view (3); grid on; axis image;
end

if (nargout == 1)||(isstruct(intree)),
    varargout {1}  = tree; % if output is defined then it becomes the tree
else
    trees {intree} = tree; % otherwise add to end of trees cell array
end