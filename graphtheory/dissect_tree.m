% DISSECT_TREE   Groups together nodes belonging to same branches.
% (trees package)
%
% [sect vec] = dissect_tree (intree, options)
% ----------------------------------------------
%
% groups segments together which belong to same branches to be used as
% sections in neuron-like compartmental modeling. Branches are defined as
% being separated by either branching or termination points or
% region-defined borders. To simplify a tree to its dissected version
% delete all continuation points with "delete_tree(tree,find(C_tree(tree))"
%
% Input
% -----
% - intree::integer:index of tree in trees structure or structured tree
% - options::string: {DEFAULT: ''}
%     '-s' : show branches
%
% Output
% ------
% - sect::two-column vector: 1. starting node 2. ending node
% - vec::optional vector Nx2: attributes to each element a branch index and
%     a path length value [in um] within the given section
% NOTE! this function isn't completely correct yet at the root
%
% Example
% -------
% sect = dissect_tree (sample_tree, '-s')
%
% See also resample_tree, delete_tree, neuron_tree
% Uses root_tree ipar_tree idpar_tree T_tree B_tree Pvec_tree ver_tree R
%
% the TREES toolbox: edit, visualize and analyze neuronal trees
% Copyright (C) 2009  Hermann Cuntz

function [sect vec] = dissect_tree (intree, options)

% trees : contains the tree structures in the trees package
global trees

if (nargin < 1)||isempty(intree),
    intree = length(trees); % {DEFAULT tree: last tree in trees cell array}
end;

ver_tree (intree); % verify that input is a tree structure

if (nargin < 2)||isempty(options),
    options = ''; % {DEFAULT: no option}
end

tree = root_tree (intree); % add an empty compartment in the root
ipar = ipar_tree (tree); % parent index structure (see "ipar_tree")
ipar = ipar + 1;
% iBT: positions at which to cut the tree:
iBT = T_tree (tree) | B_tree (tree); % binary vector with ones at branch and terminals
if isfield(tree,'R'),
    idpar = idpar_tree (tree); % vector with indices to direct parent
    iR = idpar(find(tree.R~=tree.R(idpar))); % detect region changes
    iBT(iR) = 1; % also dissect where regions change
end
% iBT therefore is one whenever a changing point B, T or new R
iiBT = [1; iBT];
% iS contains for each changing point the index in ipar to the directly
% previous changing point (the beginning of that branch)
if sum(iBT)==1,
    iS = sum(cumsum(iiBT(ipar(iBT,:))')'<=1,1)+1;
else
    iS = sum(cumsum(iiBT(ipar(iBT,:))')'<=1,2)+1;
end
% starting points of the branches are therefore just ipar of iS for all
% changing points:
startB = ipar(sub2ind(size(ipar),find(iBT),iS))-1;
startB(startB==0) = 1;
endB = find(iBT); % end points are obviously just all changing points
sect = [startB endB]-1; sect(sect==0)=1;

vec = [];
if nargout > 1
    vec = zeros(size(tree.dA,1)+1,2);
    Plen = [0; Pvec_tree(tree)]; % path length values from the root
    o = 1;
    for ward = find(iBT)',
        % correct the full path length values with the start of each
        % section:
        DEC = ipar(sub2ind(size(ipar), ones(1,iS(o)).*ward, 1:iS(o)));
        pif = diff(Plen(DEC([end 1])));
        pof = Plen(DEC(1:end-1)) - Plen(DEC(end));
        vec(DEC(1:end-1), 1) = o;
        vec(DEC(1:end-1), 2) = pof./pif;
        o = o + 1;
    end
    vec = vec(3:end, :); vec(1,2) = 0;
end

if strfind(options,'-s'), % show option
    clf; hold on; shine; 
    if ~isempty(vec)
        R = rand(size(sect,1),1); HP = plot_tree (intree,R(round(vec(:,1)),:));
    else
        HP = plot_tree (intree);
    end
    set(HP,'facealpha',.2);
    L = line([tree.X(startB) tree.X(endB)]',[tree.Y(startB) tree.Y(endB)]',...
        [tree.Z(startB) tree.Z(endB)]');
    set(L,'color',[1 0 0],'linewidth',2);
    HP(1) = plot(1,1,'r-');
    legend(HP,{'dissected branches'},'box','off');
    set(HP,'visible','off');
    xlabel ('x [\mum]'); ylabel ('y [\mum]'); zlabel ('z [\mum]');
    view(2); grid on; axis image;
end