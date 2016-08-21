% ALLBCTS_TREE   Outputs all possible trees with N nodes.
% (trees package)
% 
% [BCTs BCTtrees] = allBCTs_tree (N, options)
% -------------------------------------------
%
% Outputs in BCTs all possible non-isomorphic BCT strings with N nodes. On
% demand, cell array of trees BCTtrees is calculated whose trees correspond
% to the BCT strings using sensible metrics. This uses the equivalent tree
% method from "BCT_tree". Gets very slow very quickly.
%
% Input
% -----
% - N::integer: number of nodes {DEFAULT 8 nodes}
% - options::string: {DEFAULT '-w'}
%     '-s' : show
%     '-w' : waitbar
%
% Example
% -------
% [BCTs trees] = allBCTs_tree (8, '-w -s')
%
% Output
% ------
% - BCTtrees::cell array of trees: all possible trees with N nodes
% - BCTs::vector: the BCT version of the trees in a matrix
%
% See also BCT_tree
% Uses isBCT_tree BCT_tree sortLO_tree
%
% the TREES toolbox: edit, visualize and analyze neuronal trees
% Copyright (C) 2009  Hermann Cuntz

function [BCTs BCTtrees] = allBCTs_tree (N, options)

if (nargin<1)||isempty(N),
    N = 8; % {DEFAULT: eight nodes}
end

if (nargin<2)||isempty(options),
    options = '-w'; % {DEFAULT: waitbar}
end

MT = [];
if strfind (options, '-w'), % waitbar option: initialization
    HW = waitbar (0, 'trying out BCT strings...');
    set (HW, 'Name', '..PLEASE..WAIT..YEAH..');
end
for ward = 0 : (3^N) - 1,
    if strfind (options, '-w'), % waitbar option: update
        waitbar (ward / ((3^N) - 1), HW);
    end
    % create all possible strings with B, C and T:
    BCT = mod (floor (ward ./ (3.^(N - 1 : -1 : 0))), 3);
    if isBCT_tree (BCT),
        MT = [MT; BCT]; % if they are BCT conform then add them to the list
    end
end
if strfind (options, '-w'), % waitbar option: close
    close (HW);
end

MT2 = zeros (size (MT, 1), N);
for ward = 1 : size (MT, 1),
    BCT = MT (ward, :);
    tree = BCT_tree  (BCT,  '-dA'); % create a tree from BCT string
    tree = sort_tree (tree, '-LO'); % sort in a unique way
    MT2 (ward, :) = full (sum (tree.dA));
end

BCTs = unique (MT2, 'rows'); % get rid of duplicates

if (nargout>1) || ~isempty(strfind (options, '-s')),
    BCTtrees = cell (1, size (BCTs, 1));
    for ward = 1 : size (BCTs, 1),
        BCTtrees {ward} = BCT_tree (BCTs (ward, :));
    end
end

if strfind (options, '-s'), % show option
    clf; shine; hold on; dd = spread_tree (BCTtrees);
    for ward = 1 : length (BCTtrees),
        plot_tree (BCTtrees {ward}, [] , dd {ward}); pointer_tree (dd {ward});
    end
    text (0, 50, ['all BCT trees - ' num2str(N) ' nodes']);
    view(2); axis equal off;
end

