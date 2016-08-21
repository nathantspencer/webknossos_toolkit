% LAMBDA_TREE   Length constants of the segments of a tree.
% (trees package)
%
% lambda = lambda_tree (intree, options)
% --------------------------------------
%
% returns the length constant of all elements.
%
% Input
% -----
% - intree::integer:index of tree in trees or structured tree
% - options::string: {DEFAULT: ''}
%     '-s'  : show
%
% Output
% -------
% lambda::Nx1 vector: length constant values of each segment
%
% Example
% -------
% lambda_tree (sample_tree, '-s')
%
% See also elen_tree gm_tree
% Uses D Gm Ri
%
% the TREES toolbox: edit, visualize and analyze neuronal trees
% Copyright (C) 2009  Hermann Cuntz

function lambda = lambda_tree (intree, options)

% trees : contains the tree structures in the trees package
global trees

if (nargin < 1)||isempty(intree),
    intree = length(trees); % {DEFAULT tree: last tree in trees cell array}
end;

ver_tree (intree); % verify that input is a tree structure

% use full tree for this function
if ~isstruct (intree),
    tree = trees {intree};
else
    tree = intree;
end

if (nargin < 2)||isempty(options),
    options = ''; % {DEFAULT: no option}
end;

lambda = sqrt ((tree.D / 4) ./ (10000 .* tree.Gm .* tree.Ri));

if strfind (options, '-s'), % show option
    clf; shine; hold on; plot_tree (intree, lambda); colorbar;
    title  ('length constants [cm]');
    xlabel ('x [\mum]'); ylabel ('y [\mum]'); zlabel ('z [\mum]');
    view (2); grid on; axis image;
end
