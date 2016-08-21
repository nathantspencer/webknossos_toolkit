% GSCALE_TREE   Scales trees from a set of trees to mean tree size.
% (trees package)
%
% [spanning ctrees] = gscale_tree (intrees, options)
% --------------------------------------------------
%
% Extracts region by region features from a group of trees intrees which
% are sufficient to constrain the artificial generation of trees similar to
% the original group. Is based on the assumption that the density of
% topological points on the trees are more or less scalable. The result is
% a structure spanning with some info about the spanning fields of the
% individual regions throughout the trees. ctrees contains the scaled
% trees.
%
% Input
% -----
% - intrees::integer:index of tree in trees or structured tree or
%     cell-array of trees.
% - options::string: {DEFAULT '-w'}
%     '-s' : show plot
%     '-w' : with waitbar
%
% Output
% ------
% - spanning:: structure containing scaling info about spanning fields of
%     ordered by region
% - trees:: cell array of scaled trees as trees structures.
%
% Example
% -------
% dLPTCs = load_tree ('dLPTCs.mtr');
% [spanning ctrees] = gscale_tree (dLPTCs{1}) % scaling of HSE dendrites
%
% See also clone_tree
% Uses 
%
% the TREES toolbox: edit, visualize and analyze neuronal trees
% Copyright (C) 2009  Hermann Cuntz

function [spanning ctrees] = gscale_tree (intrees, options)

% trees : contains the tree structures in the trees package
global trees

if (nargin < 1)||isempty(intrees),
    intrees = length (trees); % {DEFAULT tree: last tree in trees cell array}
end

if (nargin < 2)||isempty(options),
    options = '-w';
end

for ward = 1:length(intrees),
    intrees {ward} = tran_tree (intrees {ward});
end

 % structure containing info about scaling of trees and all the points:
spanning = [];

% in the array of input trees look for common region names
spanning.regions = intrees {1}.rnames;
for ward = 2 : length (intrees);
    spanning.regions = [spanning.regions intrees{ward}.rnames];
end
spanning.regions = unique (spanning.regions); lenr = length (spanning.regions);
% establish the spanning volume of the different regions for all trees
spanning.xlims = cell (1, lenr); spanning.ylims = cell (1, lenr);
spanning.zlims = cell (1, lenr); 
spanning.xmass = cell (1, lenr); spanning.ymass = cell (1, lenr);
spanning.zmass = cell (1, lenr);
spanning.iR    = cell (1,    1); spanning.nBT   = cell (1, 1);
dR = zeros (1, lenr); % empty region flag
if strfind (options, '-w'), % waitbar option: initialization
    HW = waitbar (0, 'scanning spanning fields region by region...');
    set (HW, 'Name', '..PLEASE..WAIT..YEAH..');
end
for ward = 1 : length (spanning.regions);
    if strfind (options, '-w'), % waitbar option: update
        waitbar (ward / length (spanning.regions), HW);
    end
    flag = 0;
    for counter = 1 : length (intrees),
        iR0 = find (strcmp (intrees {counter}.rnames, spanning.regions {ward}));
        if ~isempty (iR0),
            % read out index values for each region in each cell:
            spanning.iR{ward}{counter} = find (intrees {counter}.R == iR0);
            BT   = ~C_tree (intrees {counter});
            iBT  = logical (BT (spanning.iR{ward}{counter}));
            % branch and termination points in that region
            iRBT = spanning.iR{ward}{counter}(iBT);
            spanning.nBT{ward}{counter} = length (iRBT);
            if ~isempty (spanning.iR{ward}{counter}),
                % if nodes exist in that region in that cell readout x y z
                % limits:
                spanning.xlims {ward} = [spanning.xlims{ward}; ...
                    [min(intrees {counter}.X (spanning.iR{ward}{counter})) ...
                    max(intrees  {counter}.X (spanning.iR{ward}{counter}))]];
                spanning.ylims {ward} = [spanning.ylims{ward}; ...
                    [min(intrees {counter}.Y (spanning.iR{ward}{counter})) ...
                    max(intrees  {counter}.Y (spanning.iR{ward}{counter}))]];
                spanning.zlims {ward} = [spanning.zlims{ward}; ...
                    [min(intrees {counter}.Z (spanning.iR{ward}{counter})) ...
                    max(intrees  {counter}.Z (spanning.iR{ward}{counter}))]];
                % now readout the center of mass:
                spanning.xmass {ward} = [spanning.xmass{ward}; ...
                    mean(intrees{counter}.X(iRBT))];
                spanning.ymass {ward} = [spanning.ymass{ward}; ...
                    mean(intrees{counter}.Y(iRBT))];
                spanning.zmass {ward} = [spanning.zmass{ward}; ...
                    mean(intrees {counter}.Z (iRBT))];
                flag = 1; % indicate that nodes were found in that region at least in one cell
            else
                spanning.xlims {ward} = [spanning.xlims{ward}; [NaN NaN]];
                spanning.ylims {ward} = [spanning.ylims{ward}; [NaN NaN]];
                spanning.zlims {ward} = [spanning.zlims{ward}; [NaN NaN]];
                spanning.xmass {ward} = [spanning.xmass{ward}; NaN];
                spanning.ymass {ward} = [spanning.ymass{ward}; NaN];
                spanning.zmass {ward} = [spanning.zmass{ward}; NaN];
            end
        else
            spanning.xlims {ward} = [spanning.xlims{ward}; [NaN NaN]];
            spanning.ylims {ward} = [spanning.ylims{ward}; [NaN NaN]];
            spanning.zlims {ward} = [spanning.zlims{ward}; [NaN NaN]];
            spanning.xmass {ward} = [spanning.xmass{ward}; NaN];
            spanning.ymass {ward} = [spanning.ymass{ward}; NaN];
            spanning.zmass {ward} = [spanning.zmass{ward}; NaN];
            spanning.iR{ward}{counter} = [];
        end
    end
    % if flag is not set then the region is fully empty and we can delete
    % it (see below):
    if ~flag,
        dR (ward) = 1;
    end
end

% create sample tapering in trees to determine region-wise tapering parameters
qtrees = cell (1, 1);
for ward = 1 : length (intrees)
    if strfind (options, '-w'), % waitbar option: update
        waitbar (ward / length (intrees), HW);
    end
    qtrees{ward} = quaddiameter_tree (intrees {ward});
end

% measure wriggliness amplitude independently of region
% can be expanded
spanning.wriggles = zeros (length (intrees), 2);
for counter = 1:length (intrees)
    if strfind (options, '-w'), % waitbar option: update
        waitbar (counter / length (intrees), HW);
    end
    tree = intrees {counter};
    ampl = 2 * (sum (len_tree (tree)) ./ ...
        sum (len_tree (delete_tree (tree, find (C_tree (tree))))) - 1);
    lambda = 5;
    spanning.wriggles (counter, :) = [ampl lambda];
end

% delete emptyregions
emptyregion = find (dR);
for ward = 1 : length (emptyregion),
    spanning.regions (emptyregion (ward)) = [];
    spanning.xlims   (emptyregion (ward)) = [];
    spanning.ylims   (emptyregion (ward)) = [];
    spanning.zlims   (emptyregion (ward)) = [];
    spanning.xmass   (emptyregion (ward)) = [];
    spanning.ymass   (emptyregion (ward)) = [];
    spanning.zmass   (emptyregion (ward)) = [];
    spanning.iR      (emptyregion (ward)) = [];
    spanning.nBT     (emptyregion (ward)) = [];
end
lenr = length (spanning.regions);

spanning.mxdiff = zeros (lenr, 1); spanning.stdxdiff = zeros (lenr, 1);
spanning.mydiff = zeros (lenr, 1); spanning.stdydiff = zeros (lenr, 1);
spanning.mzdiff = zeros (lenr, 1); spanning.stdzdiff = zeros (lenr, 1);
for ward = 1 : lenr;
    % readout mean and standard deviation of spanning hull limits
    isy = ~isnan (spanning.xlims {ward}(:, 1));
    spanning.mxdiff    (ward) = mean (diff (spanning.xlims {ward}(isy, :), [], 2));
    if spanning.mxdiff (ward) == 0,  spanning.mxdiff (ward) = 1; end
    spanning.stdxdiff  (ward) = std  (diff (spanning.xlims {ward}(isy, :), [], 2));
    spanning.mydiff    (ward) = mean (diff (spanning.ylims {ward}(isy, :), [], 2));
    if spanning.mydiff (ward) == 0,  spanning.mydiff (ward) = 1; end
    spanning.stdydiff  (ward) = std  (diff (spanning.ylims {ward}(isy, :), [], 2));
    spanning.mzdiff    (ward) = mean (diff (spanning.zlims {ward}(isy, :), [], 2));
    if spanning.mzdiff (ward) == 0,  spanning.mzdiff (ward) = 1; end
    spanning.stdzdiff  (ward) = std  (diff (spanning.zlims {ward}(isy, :), [], 2));
end
ctrees = intrees;
spanning.X     = cell (1, 1); spanning.Y = cell (1, 1); spanning. Z = cell (1, 1);
spanning.qdiam = cell (1, 1);
for ward = 1 : length (spanning.regions);
    if strfind (options, '-w'), % waitbar option: update
        waitbar (ward / length (spanning.regions), HW);
    end
    spanning.qdiam {ward} = [];
    for counter = 1 : size (spanning.xlims {ward}, 1),
        BT   = ~C_tree (intrees {counter});
        iBT  = logical (BT (spanning.iR{ward}{counter}));
        % branch and termination points in that region
        iRBT = spanning.iR{ward}{counter} (iBT);
        Xpre = intrees {counter}.X (iRBT);
        Ypre = intrees {counter}.Y (iRBT);
        Zpre = intrees {counter}.Z (iRBT);
        % scale X Y Z coordinates with mean limits and collect for all
        % cells:
        if diff (spanning.xlims {ward}(counter, :)) ~= 0
            spanning.X{ward}{counter} = spanning.xmass {ward}(counter) + ...
                spanning.mxdiff (ward) * (Xpre - spanning.xmass {ward}(counter))' / ...
                diff (spanning.xlims {ward}(counter, :));
            ctrees {counter}.X (spanning.iR{ward}{counter}) = spanning.mxdiff (ward) *...
                ctrees {counter}.X (spanning.iR{ward}{counter})' / ...
                diff (spanning.xlims {ward}(counter, :));
        else
            spanning.X{ward}{counter} = Xpre';
        end
        if diff (spanning.ylims {ward}(counter, :)) ~= 0
            spanning.Y{ward}{counter} = spanning.ymass {ward}(counter) + ...
                spanning.mydiff (ward) * (Ypre - spanning.ymass {ward}(counter))' / ...
                diff (spanning.ylims {ward}(counter, :));
            ctrees {counter}.Y (spanning.iR{ward}{counter}) = spanning.mydiff (ward)*...
                ctrees {counter}.Y (spanning.iR{ward}{counter})' / ...
                diff (spanning.ylims {ward}(counter, :));
        else
            spanning.Y{ward}{counter} = Ypre';
        end
        if diff (spanning.zlims {ward}(counter, :)) ~= 0
            spanning.Z{ward}{counter} = spanning.zmass {ward}(counter) + ...
                spanning.mzdiff (ward) * (Zpre - spanning.zmass {ward}(counter))' /...
                diff (spanning.zlims {ward}(counter, :));
            ctrees {counter}.Z (spanning.iR{ward}{counter}) = spanning.mzdiff (ward) *...
                ctrees {counter}.Z (spanning.iR{ward}{counter})' / ...
                diff (spanning.zlims {ward}(counter, :));
        else
            spanning.Z{ward}{counter} = Zpre';
        end
        % determine region-wise tapering:
        if ~isempty (spanning.iR{ward}{counter}),
            m1  = min (intrees {counter}.D (spanning.iR{ward}{counter}));
            m2  = max (intrees {counter}.D (spanning.iR{ward}{counter}));
            mm1 = min (qtrees  {counter}.D (spanning.iR{ward}{counter}));
            mm2 = max (qtrees  {counter}.D (spanning.iR{ward}{counter}));
            spanning.qdiam {ward}(end + 1, :) = .5 * [(m2 - m1)/(mm2 - mm1) m1/mm1];
        end
    end
end

spanning.mnBT = zeros (lenr, 1); spanning.stdnBT = zeros (lenr, 1);
for ward = 1: lenr,
    spanning.mnBT   (ward) = mean (cat (2, spanning.nBT{ward}{:}));
    spanning.stdnBT (ward) = std  (cat (2, spanning.nBT{ward}{:}));
end

if strfind (options, '-w'), % waitbar option: close
    close (HW);
end

if strfind (options, '-s'),
    clf; hold on; shine;
    cX = [0 0 0 0; 0 1 1 0; 0 1 1 0; 1 1 0 0; 1 1 0 0; 1 1 1 1] - 0.5;
    cY = [0 0 1 1; 0 0 1 1; 1 1 1 1; 0 1 1 0; 0 0 0 0; 0 0 1 1] - 0.5;
    cZ = [0 1 1 0; 0 0 0 0; 1 1 0 0; 1 1 1 1; 1 0 0 1; 0 1 1 0] - 0.5;
    colors = [[0 0 0];[1 0 0];[0 1 0];[0 0 1]]; colors = [colors; rand(lenr - 4, 3)];
    for ward = 1 : lenr,
        HP = patch (mean (spanning.xmass {ward}) + cX' * spanning.mxdiff (ward), ...
            mean (spanning.ymass {ward}) + cY' * spanning.mydiff (ward),...
            mean (spanning.zmass {ward}) + cZ' * spanning.mzdiff (ward), colors (ward, :));
        set (HP, 'edgecolor', colors (ward, :), 'facealpha', .2);
        HP = patch (mean (spanning.xmass {ward}) + ...
            cX' * (spanning.mxdiff (ward) + spanning.stdxdiff (ward)), ...
            mean (spanning.ymass {ward})  + ...
            cY' * (spanning.mydiff (ward) + spanning.stdydiff (ward)), ...
            mean (spanning.zmass {ward})  + ...
            cZ' * (spanning.mzdiff (ward) + spanning.stdzdiff (ward)), ...
            colors (ward, :));
        set (HP, 'edgecolor', colors (ward, :), 'facealpha', 0);
        XT = cat (2, spanning.X{ward}{:});
        YT = cat (2, spanning.Y{ward}{:});
        ZT = cat (2, spanning.Z{ward}{:});
%         SR = round(max([max(XT)-min(XT) max(YT)-min(YT)...
%             max(ZT)-min(ZT)])/20);
%         if (SR==0)|(isempty(SR)), SR = 10;end;
        HT = text (mean (spanning.xmass {ward}) - spanning.mxdiff (ward) / 2, ...
            mean (spanning.ymass {ward}) + spanning.mydiff (ward) / 2, ...
            mean (spanning.zmass {ward}) - spanning.mzdiff (ward) / 2, spanning.regions {ward});
        set (HT, 'color', colors (ward, :), 'verticalalignment', 'bottom');
    end
    title  ('spanning the tree');
    xlabel ('x [\mum]'); ylabel ('y [\mum]'); zlabel ('z [\mum]');
    view (2); grid on; axis image;
end
