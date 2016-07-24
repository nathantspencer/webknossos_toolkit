% ELIMT_TREE   Replace multifurcations by multiple bifurcations in a tree.
% (trees package)
% 
% tree = elimt_tree (intree, options)
% -----------------------------------
% 
% eliminates the trifurcation/multifurcations present in the tree's
% adjacency matrix by adding tiny (x-deflected) compartments. This function
% alters the original morphology minimally!
% 
% Input
% -----
% - intree::integer:index of tree in trees or structured tree
% - options::string: {DEFAULT: '-e'}
%     '-s' : show
%     '-e' : echo added nodes
%
% Output
% ------
% if no output is declared the tree is changed in trees
% - tree:: structured output tree
%
% Example
% -------
% tree = redirect_tree (sample2_tree, 3);
% elimt_tree (tree, '-s -e');
%
% See also elim0_tree delete_tree repair_tree
% Uses ver_tree dA
%
% the TREES toolbox: edit, visualize and analyze neuronal trees
% Copyright (C) 2009  Hermann Cuntz

function varargout = elimt_tree (intree, options)

% trees : contains the tree structures in the trees package
global trees

if (nargin < 1)||isempty (intree),
    intree = length (trees); % {DEFAULT tree: last tree in trees cell array}
end;

ver_tree (intree); % verify that input is a tree structure

% use full tree for this function
if ~isstruct (intree),
    tree = trees {intree};
else
    tree = intree;
end

if (nargin < 2)||isempty (options),
    options = '-e'; % {DEFAULT: echo changes}
end

dA    = tree.dA;           % directed adjacency matrix of tree
num   = size (dA, 1);      % number of nodes in tree
sumdA = ones(1, num) * dA; % typeN: (actually faster than sum(dA)) ;-)
itrif = find (sumdA > 2);  % find trifurcations

for ward = 1 : length(itrif),
    N = size (dA, 1);
    fed = sumdA (itrif(ward)) - 2;
    dA = [[dA; zeros(fed,num)], zeros(fed + num, fed)];
    % lengthen all vectors of form Nx1
    S = fieldnames (tree);
    for te = 1 : length(S),
        if ~strcmp (S{te}, 'dA'),
            vec = tree.(S{te});
            if isvector(vec) && (numel(vec) == N),
                if strcmp(S{te},'X'),
                    tree.X = [tree.X; ones(fed,1).*tree.X(itrif(ward)) + 0.0001.*(1:fed)'];
                else
                    tree.(S{te}) = [tree.(S{te}); ...
                        ones(fed,1).*tree.(S{te})(itrif(ward))];
                end
            end
        end
    end
    ibs = find (dA(:, itrif (ward)) == 1);
    num = num + 1;
    dA (num, itrif(ward))    = 1;
    dA (ibs(2), itrif(ward)) = 0;
    dA (ibs(2), num)         = 1;
    for tissimo = 3:sumdA(itrif(ward))-1,
        num = num + 1;
        dA (num, num - 1)                = 1;
        dA (ibs (tissimo), itrif (ward)) = 0;
        dA (ibs (tissimo), num)          = 1;
    end
    dA (ibs (sumdA (itrif (ward))), itrif (ward)) = 0;
    dA (ibs (sumdA (itrif (ward))), num)          = 1;
end
tree.dA = dA;

if strfind (options, '-s'), % show option
    clf; shine; hold on; xplore_tree (tree);
    if ~isempty (itrif)
        HP = pointer_tree (intree, itrif); set (HP, 'facealpha',.5);
    end
    title ('eliminate trifurcations');
    xlabel ('x [\mum]'); ylabel ('y [\mum]'); zlabel ('z [\mum]');
    view(2); grid on; axis image;
end

if strfind (options,'-e'),
    display (['elimt_tree: eliminated ' num2str(length (itrif)) ' trifurcations']);
end

if (nargout == 1)||(isstruct(intree)),
    varargout {1}  = tree;
else
    trees {intree} = tree;
end

