% PL_TREE   Topological path length.
% (trees package)
% 
% PL = PL_tree (intree, options)
% ------------------------------
% 
% returns the topological path length PL to the root node in the tree.
%
% Input
% -----
% - intree::integer:index of tree in trees or structured tree
% - options::string: {DEFAULT: ''}
%     '-s' : show
%
% Output
% ------
% - PL::Nx1 vector:distances from each node to the root (first node) in
%     the tree 
%
% Example
% -------
% PL_tree (sample_tree, '-s')
%
% See also  BO_tree LO_tree Pvec_tree
% Uses ver_tree dA
%
% the TREES toolbox: edit, visualize and analyze neuronal trees
% Copyright (C) 2009  Hermann Cuntz

function  PL = PL_tree (intree, options)

% trees : contains the tree structures in the trees package
global trees

if (nargin < 1)||isempty(intree),
    intree = length(trees); % {DEFAULT tree: last tree in trees cell array} 
end;

ver_tree (intree); % verify that input is a tree structure

% use only directed adjacency for this function
if ~isstruct(intree),
    dA = trees{intree}.dA;
else
    dA = intree.dA;
end

if (nargin < 2)||isempty(options),
    options = ''; % {DEFAULT: no option}
end

% calculating weighted path length:
ward = 1;
PL = dA(:,1);
resPL = PL;
while sum(resPL==1)~=0,
    ward = ward + 1;
    resPL = dA*resPL; % use adjacency matrix to walk through tree
    PL = PL + ward.*resPL;
end
PL = full(PL);

if strfind(options,'-s'), % show option
    clf; hold on; shine; plot_tree (intree, PL); colorbar;
    title ('topological path length');
    xlabel ('x [\mum]'); ylabel ('y [\mum]'); zlabel ('z [\mum]');
    view(2); grid on; axis image;
end

% % shorter but slower (concatenation issue):
% ipar = ipar_tree(index);
% PL = ipar>0;
% PL = sum(PL')-1;