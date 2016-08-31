% ELEN_TREE   Electrotonic length of segments in a tree
% (trees package)
% 
% elen = elen_tree (intree, options)
% ----------------------------------
%
% returns the electrotonic length of all segments (length/lambda).
%
% Input
% -----
% - intree::integer:index of tree in trees or structured tree
% - options::string: {DEFAULT: ''}
%     '-s' : show
%
% Output
% ------
% - elen::Nx1 vector: electrotonic length values of each segment
%
% Example
% -------
% elen_tree (sample_tree, '-s')
%
% See also lambda_tree len_tree
% Uses lambda_tree len_tree ver_tree
%
% the TREES toolbox: edit, visualize and analyze neuronal trees
% Copyright (C) 2009  Hermann Cuntz

function elen = elen_tree (intree, options)

% trees : contains the tree structures in the trees package
global trees

if nargin < 1,
    intree = length (trees);  % {DEFAULT tree: last tree in trees cell array}
end;

ver_tree (intree); % verify that input is a tree structure

if (nargin < 2)||isempty(options),
    options = ''; % {DEFAULT: no option}
end

elen = len_tree (intree) ./ lambda_tree (intree) / 10000;
% conversion here from [um] length to [cm]

if strfind (options, '-s'),
    ipart = find (elen ~= 0); % single out non-0-length segments
    clf; shine; hold on; plot_tree (intree, elen, [], ipart); colorbar;
    title  (['electrotonic lengths (total: ~' num2str(round (sum (elen)))...
        ') [in length constants]' ]);
    xlabel ('x [\mum]'); ylabel ('y [\mum]'); zlabel ('z [\mum]');
    view (2); grid on; axis image;
end
