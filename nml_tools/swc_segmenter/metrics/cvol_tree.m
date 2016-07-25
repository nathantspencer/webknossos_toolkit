% CVOL_TREE   Continuous volume of segments in a tree.
% (trees package)
%
% cvol = cvol_tree (intree, options)
% ----------------------------------
%
% returns the continuous volume of all compartments [in 1/um]. This is
% used by  electrotonic calculations in relation to the specific axial
% resistance [ohm cm], see "sse_tree".
%
% Input
% -----
% - intree::integer:index of tree in trees or structured tree
% - options::string: {DEFAULT: ''}
%     '-s'  : show
%
% Output
% -------
% - cvol::Nx1 vector: continuous volume values for each segment
%
% Example
% -------
% cvol_tree (sample_tree, '-s')
%
% See also len_tree surf_tree vol_tree sse_tree
% Uses len_tree ver_tree D
%
% the TREES toolbox: edit, visualize and analyze neuronal trees
% Copyright (C) 2009  Hermann Cuntz

function cvol = cvol_tree (intree, options)

% trees : contains the tree structures in the trees package
global trees

if (nargin < 1)||isempty(intree),
    intree = length (trees); % {DEFAULT tree: last tree in trees cell array}
end;

ver_tree (intree); % verify that input is a tree structure

% use only local diameters vector for this function
isfrustum = 0;
if ~isstruct (intree),
    D = trees{intree}.D;
    if isfield(trees{intree},'frustum') && (trees{intree}.frustum==1),
        isfrustum = 1;
    end
else
    D = intree.D;
    if isfield(intree,'frustum') && (intree.frustum==1),
        isfrustum = 1;
    end
end

if (nargin < 2)||isempty(options),
    options = ''; % {DEFAULT: no option}
end

len = len_tree (intree); % vector containing length values of tree segments
if isfrustum,
    idpar = idpar_tree (intree); % vector containing index to direct parent
    % continuous volumes according to frustum (cone) -like segments
    % NOTE! not sure about this
    cvol = (12*len) ./ (pi*(D.^2 + D.*D(idpar) + D(idpar).^2));
    cvol (cvol == 0) = 0.0001; % !!!!!!!! necessary numeric correction
else
    cvol = (4*len)  ./ (pi*(D.^2)); % continuous volumes according to cylinder segments
    cvol (cvol == 0) = 0.0001; % !!!!!!!! necessary numeric correction
end

if strfind (options, '-s'), % show option
    clf; hold on; shine; plot_tree (intree, cvol); colorbar;
    title  ('continuous volume');
    xlabel ('x [\mum]'); ylabel ('y [\mum]'); zlabel ('z [\mum]');
    view(2); grid on; axis image;
end

% in 1/cm it would be:
% cvol = cvol * 10000; % astounding scaling factors from um to cm
