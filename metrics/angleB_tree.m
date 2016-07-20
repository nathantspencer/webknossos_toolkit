% ANGLEB_TREE   Angle values at branch points in a tree.
% (trees package)
%
% angleB = angleB_tree (intree, options)
% --------------------------------------
%
% returns for each branching point an angle value corresponding to the
% branching angle within the branching plane. Tree must be BCT (at least
% trifurcations are forbidden of course), use "repair_tree" if necessary.
% NOTE !!this function is not yet opimized for speed and readability!!
%
% Input
% -----
% - intree::integer:index of tree in trees or structured tree
% - options::string: {DEFAULT: ''}
%     '-m' : movie
%     '-s' : show
%
% Output
% ------
% angleB::vertical vector: angle value for each branching point
%
% Example
% -------
% angleB_tree (sample_tree, '-m -s')
%
% See also asym_tree B_tree
% Uses ipar_tree B_tree ver_tree dA X Y Z
%
% the TREES toolbox: edit, visualize and analyze neuronal trees
% Copyright (C) 2009  Hermann Cuntz

function angleB = angleB_tree (intree, options)

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

if (nargin < 2)||isempty(options),
    options = ''; % {DEFAULT: no option}
end

iB     = find (B_tree (intree));  % vector containing branch point indices
angleB = zeros (length (iB), 1);  % vector containing angle values for each BP
for ward = 1 : length (iB),       % walk through all branch points
    BB = find (tree.dA (:, iB (ward))); % indices of branch point daughters 
     
    Pr = [tree.X(iB(ward)) tree.Y(iB(ward)) tree.Z(iB(ward))]; % coordinates of BP
    P1 = [tree.X(BB(1))    tree.Y(BB(1))    tree.Z(BB(1))];    % coordinates of daughter 1
    P2 = [tree.X(BB(2))    tree.Y(BB(2))    tree.Z(BB(2))];    % coordinates of daughter 2
    
    V1 = P1 - Pr; % vector of daughter branch 1
    V2 = P2 - Pr; % vector of daughter branch 2
    % normalized vectors:
    nV1 = V1 / sqrt (sum (V1 .^ 2));
    nV2 = V2 / sqrt (sum (V2 .^ 2));
    
    % the angle between to vectors in 3D is simply the inverse cosine of
    % their dot-product.
    angleB (ward) = acos (dot (nV1, nV2));
    
    if strfind (options, '-m'), % show movie option
        clf; hold on; shine; HP = plot_tree (intree); set (HP, 'facealpha', 0.2);
        L(1) = line ([Pr(1) Pr(1)+V1(1)],[Pr(2) Pr(2)+V1(2)],[Pr(3) Pr(3)+V1(3)]);
        L(2) = line ([Pr(1) Pr(1)+V2(1)],[Pr(2) Pr(2)+V2(2)],[Pr(3) Pr(3)+V2(3)]);
        set (L, 'linewidth', 4, 'color', [1 0 0]);
        text (tree.X (iB (ward)), tree.Y (iB (ward)), tree.Z (iB (ward)), num2str (angleB (ward)));
        title  ('angle at b-points');
        xlabel ('x [\mum]'); ylabel ('y [\mum]'); zlabel ('z [\mum]');
        view (2); grid on; axis image;
        pause (.3);
    end
end
% map angle on a Nx1 vector, rest becomes NaN:
tangleB     = angleB;
angleB      = NaN (size (tree.dA, 1), 1);
angleB (iB) = tangleB;

if strfind (options, '-s'), % show option
    clf; hold on; shine;
    plot_tree (intree, [], [], find (~B_tree(intree))); axis equal;
    iB = find (B_tree (intree));
    plot_tree (intree, angleB (iB), [], iB);
    title  (['angle at b-points, mean: ' num2str(nanmean (angleB))]);
    xlabel ('x [\mum]'); ylabel ('y [\mum]'); zlabel ('z [\mum]');
    view(2); grid on; axis image; colorbar;
end
