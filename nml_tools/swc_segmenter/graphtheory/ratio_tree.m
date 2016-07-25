% RATIO_TREE   Ratio between parent and daughter segments in a tree.
% (trees package)
% 
% ratio = ratio_tree (intree, v, options)
% ---------------------------------------
%
% returns ratio values between daughter nodes and parent nodes for any
% values given in vector v. Typically this is applied on diameter, but:
% This is a META-FUNCTION and can lead to various applications.
%
% Input
% -----
% - intree::integer:index of tree in trees or structured tree
% - v::Nx1 vector: for each node a number to be ratioed {DEFAULT: D, diameter}
% - options::string: {DEFAULT: ''}
%     '-s' : show
%
% Output
% ------
% - ratio::Nx1 vector: ratios of v-values child node to parent node
%
% Example
% -------
% ratio_tree (sample_tree, [], '-s')
%
% See also child_tree
% Uses idpar_tree ver_tree
%
% the TREES toolbox: edit, visualize and analyze neuronal trees
% Copyright (C) 2009  Hermann Cuntz

function ratio = ratio_tree (intree, v, options)

% trees : contains the tree structures in the trees package
global trees

if (nargin < 1)||isempty(intree),
    intree = length(trees); % {DEFAULT tree: last tree in trees cell array} 
end

ver_tree (intree); % verify that input is a tree structure

if (nargin < 2)||isempty(v),
    % {DEFAULT vector: diameter values from the tree} 
    if ~isstruct(intree),
        v = trees{intree}.D;
    else
        v = intree.D;
    end
end

if (nargin < 3)||isempty(options),
    options = ''; % {DEFAULT: no option}
end

idpar = idpar_tree (intree); % vector containing index to direct parent
warning ('off', 'MATLAB:divideByZero');
ratio = v ./v (idpar);       % well yes, is this worth an extra function?
warning ('on',  'MATLAB:divideByZero');

if strfind(options,'-s'), % show option
    clf; hold on; shine; plot_tree (intree, ratio); colorbar;
    title ('parent daughter ratios');
    xlabel ('x [\mum]'); ylabel ('y [\mum]'); zlabel ('z [\mum]');
    view(2); grid on; axis image;
end
