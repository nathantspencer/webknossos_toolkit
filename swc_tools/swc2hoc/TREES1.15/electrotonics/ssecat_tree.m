% SSECAT_TREE   steady-state electrotonic signature of elsyn-connected trees.
% (trees package)
%
%  sse = ssecat_tree (intrees, inodes1, inodes2, gelsyn, I, options)
% -------------------------------------------------------------------
%
% concatenates many trees with electrical synapses and calculates the
% steady-state matrix (see sse_tree). Indices are cumulative summing along
% trees
%
% Input
% -----
% - intrees::cell array:cell array of trees
% - inodes1::array: indices for elsyn origin, indices are cumulated over
%     trees {DEFAULT: last node of last tree}
% - inodes2::array: indices of elsyn endpoints. {DEFAULT: root of first
%     tree}
% - gelsyn::number or vector:conductance value or values if inhomogeneous
% - I::NxH matrix or value:(optional) current injection vector
%     if I is a number, then 1 nA is injected in position I)
%     if I is omitted I is the identity matrix {DEFAULT}
% - options::string: {DEFAULT: ''}
%     '-s' : show - full matrix if I is left empty (full sse)
%                 - tree distribution if I is Nx1 vector
%                 - other Is first column
%
% Output
% ------
% - sse::NxH matrix: electrotonic signature matrix
%
% Example
% -------
% ssecat_tree ({sample_tree, tran_tree(sample2_tree,[-50 30 0])}, 197,...
% 205, .01, 195, '-s');
%
% sse = ssecat_tree ({sample_tree, tran_tree(sample2_tree,[-50 30 0])},...
% 197, 205, .01, [], '-s');
%
% See also sse_tree syn_tree syncat_tree M_tree loop_tree
% Uses M_tree ver_tree
%
% the TREES toolbox: edit, visualize and analyze neuronal trees
% Copyright (C) 2009  Hermann Cuntz

function sse = ssecat_tree (intrees, inodes1, inodes2, gelsyn, I, options)

% trees : contains the tree structures in the trees package
global trees

if (nargin < 1)||isempty(intrees),
    intrees = trees;
end;

len = length (intrees);

for ward = 1 : len,
    ver_tree (intrees {ward});
end

siz = zeros (1, len);
for ward = 1 : len,
    siz (ward) = length (intrees {ward}.X);
end;
sumsiz = [0 cumsum(siz)];
N = sumsiz (end);

if (nargin < 2)||isempty(inodes1),
    inodes1 = size(sumsiz(end), 1);
end

if (nargin < 3)||isempty(inodes2),
    inodes2 = 1;
end

if (nargin < 4)||isempty(gelsyn),
    gelsyn = 1;
end

if (nargin < 6)||isempty(options),
    options = '';
end

MM = sparse (sumsiz (len + 1), sumsiz (len + 1));

for ward = 1 : len,
    MM (sumsiz (ward) + 1 : sumsiz (ward + 1), sumsiz (ward) + 1 : sumsiz (ward + 1)) = ...
        M_tree (intrees {ward});
end

if numel (gelsyn) == 1,
    gelsyn = ones (length (inodes1), 1) .* gelsyn;
end

for ward = 1 : length (inodes1),
    MM (inodes1 (ward), inodes2 (ward)) = MM (inodes1 (ward), inodes2 (ward)) - gelsyn (ward);
    MM (inodes2 (ward), inodes1 (ward)) = MM (inodes2 (ward), inodes1 (ward)) - gelsyn (ward);
    MM (inodes1 (ward), inodes1 (ward)) = MM (inodes1 (ward), inodes1 (ward)) + gelsyn (ward);
    MM (inodes2 (ward), inodes2 (ward)) = MM (inodes2 (ward), inodes2 (ward)) + gelsyn (ward);
end

if (nargin<5)||isempty(I),
    sse = inv (MM);
else
    if numel (I) == 1,
        dI = I;
        I  = sparse (size (MM, 1), 1); I (dI) = 1;
    end
    sse = MM \ I;
end

if strfind (options, '-s'),
    if numel (MM) == numel (sse)
        clf; imagesc(sse); colorbar; axis image;
        xlabel ('node #'); ylabel ('node #');
        title  ('potential distribution [mV]');
    else
        clf; shine; hold on; X = zeros (N, 1); Y = zeros (N, 1); Z = zeros (N, 1);
        for ward = 1 : len,
            plot_tree (intrees {ward}, sse (sumsiz (ward) + 1 : sumsiz (ward + 1), 1));
            X (sumsiz (ward) + 1 : sumsiz (ward + 1)) = intrees {ward}.X;
            Y (sumsiz (ward) + 1 : sumsiz (ward + 1)) = intrees {ward}.Y;
            Z (sumsiz (ward) + 1 : sumsiz (ward + 1)) = intrees {ward}.Z;
        end;
        L = line ([X(inodes1) X(inodes2)]', [Y(inodes1) Y(inodes2)]',...
            [Z(inodes1) Z(inodes2)]');
        set (L, 'linestyle', '--', 'color', [0 0 0], 'linewidth', 2);
        legend (L(1), 'el. synapse'); colorbar;
        title  ('potential distribution [mV]');
        xlabel ('x [\mum]'); ylabel ('y [\mum]'); zlabel ('z [\mum]');
        view (2); grid on; axis image; set (gca, 'clim', [0 full(1.2 * max (max (sse)))]);
    end
end
