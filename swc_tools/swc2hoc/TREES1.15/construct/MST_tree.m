% MST_TREE   Minimum spanning tree based tree constructor.
% (trees package)
%
% [tree indx] = MST_tree (msttrees, X, Y, Z, bf, thr, mplen, DIST, options)
% -------------------------------------------------------------------------
%
% Creates trees corresponding to the minimum spanning tree keeping the path
% length to the root small (with balancing factor bf). A sparse distance
% matrix DIST between nodes is added to the cost function. Don't forget to
% include input tree nodes into the distance matrix DIST!
%
% For speed and memory considerations an area of close vicinity is drawn
% around each tree as it grows.
%
% Input
% -----
% - msttrees::vector: indices to the starting points of trees(# determines
%     # of trees), or starting trees as cell array of trees structures
%     {DEFAULT: additional node (0,0,0)}
% - X::vertical vector: X coords of pts to be connected {1000 rand. pts}
% - Y::vertical vector: Y coords of pts to be connected {1000 rand. pts}
% - Z::vertical vector: Z coords of pts to be connected {DEFAULT: zeros}
% - bf::number between 0 1: balancing factor {DEFAULT: 0.4}
% - thr::value: max distance that a connection can span {DEFAULT: 50}
% - mplen::value: maximum path length in a tree {DEFAULT: 10000}
%     (doesn't really work yet..)
% - DIST::sparse matrix BIGNxBIGN: zero indicates probably no connection,
%     numbers increasing probabilities of a connection {DEFAULT: sparse
%     zeros matrix}. order of elements is first all trees in order and then
%     all open points.
% - options::string: {DEFAULT '-w'}
%     '-s' : show plot (much much much slower)
%     '-w' : with waitbar
%     '-t' : time lapse save
%     '-b' : suppress multifurcations
%
% Output
% ------
% if no output is declared the trees are added in trees
% - tree:: structured output trees, cell array if many
% - indx:: index indicating where points ended up [itree inode]
%
% Example
% -------
% X = rand (100, 1) * 100; Y = rand (100, 1) * 100; Z = zeros (100, 1);
% tree = MST_tree (1, [50;X], [50;Y], [0;Z], .5, 50, [], [], '-s');
%
% See also rpoints_tree quaddiameter_tree BCT_tree
%
% the TREES toolbox: edit, visualize and analyze neuronal trees
% Copyright (C) 2009  Hermann Cuntz

function [tree, indx] = MST_tree (msttrees, X, Y, Z, bf, thr, mplen, DIST, options)

% trees : contains the tree structures in the trees package
global trees

if (nargin<2)||isempty(X),
    X = rand  (1000, 1)        .* 400;
end

if (nargin<3)||isempty(Y),
    Y = rand  (size (X, 1), 1) .* 400;
end

if (nargin<4)||isempty(Z),
    Z = zeros (size (X, 1), 1);
end

if (nargin<1)||isempty(msttrees),
    % starting tree is just point (0,0,0)
    msttrees = {};
    msttrees {1}.X  = 0; msttrees {1}.Y = 0; msttrees {1}.Z = 0;
    msttrees {1}.dA = sparse (0); msttrees {1}.D = 1; msttrees {1}.R = 1;
    msttrees {1}.rnames = {'tree'};
end

if ~iscell (msttrees),
    ID = msttrees;
    msttrees = cell (1, length (ID));
    for ward = 1:length (ID),
        msttrees {ward}.X  = X (ID (ward));
        msttrees {ward}.Y  = Y (ID (ward));
        msttrees {ward}.Z  = Z (ID (ward));
        msttrees {ward}.dA = sparse (0); msttrees {ward}.D = 1;
        msttrees {ward}.R  = 1;
        msttrees {ward}.rnames = {'tree'};
    end
    X (ID) = []; Y (ID) = []; Z (ID) = [];
end

if (nargin<5)||isempty(bf),
    bf = 0.4;
end

if (nargin<6)||isempty(thr),
    thr = 50;
end

if (nargin<7)||isempty(mplen),
    mplen = 10000;
end

lenX = length (X);  % number of points
lent = length (msttrees);   % number of trees

if (nargin<8)||isempty(DIST),
    DIST = [];
else
    Derr = max (max (DIST)); DIST = DIST / Derr;
end
if ~isempty (DIST),
    iDIST = cell (lent, 1); iDISTP = cell (lent, 1); TSUM = 0;
    for ward = 1 : lent,
        N = length (msttrees {ward}.X); % number of nodes in tree;
        % DIST index creation, which indicates which node in the tree
        % corresponds to which field in DIST:
        iDIST {ward} = TSUM + 1 : TSUM + N; TSUM = TSUM + N;
    end
end

if (nargin<9)||isempty(options),
    options = '-w';
end

if strfind (options, '-t'),  % time lapse save
    timetrees = cell (lent, 1);
    for tissimo = 1 : lent,
        timetrees{tissimo}{1} = msttrees {tissimo};
    end
end
if strfind (options, '-s'),  % prepare a plot if showing
    clf;
    colors = [[1 0 0];[0 1 0];[0 0 1];[0.2 0.2 0.2];[1 0 1];[1 1 0];[0 1 1]];
    if lent > 7,
        colors = [colors; rand(lent - 7, 3)];
    end
    plot3 (X, Y, Z, 'k.'); hold on;
    HP = cell (1, lent);
    for ward = 1 : lent,
        HP {ward} = plot_tree (msttrees {ward});
    end
    view (2); grid on;
    axis image;
end

% initialization:
N     = cell (lent, 1); tthr   = cell (lent, 1); root_dist = cell (lent, 1);
rdist = cell (lent, 1); irdist = cell (lent, 1); plen      = cell (lent, 1);
avic  = cell (lent, 1); inX    = cell (lent, 1); dplen     = cell (lent, 1);
ITREE = cell (lent, 1);
for ward = 1 : lent,
    N {ward} = length (msttrees {ward}.X); % number of nodes in tree;
    if N {ward} > 1,   % initialization is a lot harder when starting tree is
        % not empty:
        % starting path length to the root in the tree:
        plen {ward} = Pvec_tree (msttrees {ward});
        plen {ward} (plen {ward} > mplen) = NaN; % don't allow to go beyond a maximum path length
        % threshold distance determining the vicinity circle:
        eucl = eucl_tree (msttrees {ward});
        tthr {ward} = max (eucl) + thr;
        % calculate distance from all open points to root
        root_dist {ward} = sqrt ((X - msttrees {ward}.X(1)).^2 + ...
            (Y - msttrees {ward}.Y(1)).^2 + (Z - msttrees {ward}.Z(1)).^2)';
        % calculate distance from all open points to any point on the tree
        dis = zeros (1, lenX); idis = ones (1, lenX);
        if strfind (options, '-b'), % avoid multifurcations
            iCT = find (sum (msttrees {ward}.dA, 1) < 2); % non-branch points
            for te = 1 : lenX % search only among non-branch-points:
                sdis = sqrt ((X (te) - msttrees {ward}.X(iCT)).^2 + ...
                    (Y (te) - msttrees {ward}.Y(iCT)).^2 + ...
                    (Z (te) - msttrees {ward}.Z(iCT)).^2);
                [dis(te) idis(te)] = min (sdis); % dis contains closest node on tree
            end
            idis = iCT (idis); % retranslate index to all nodes
        else
            for te = 1 : lenX
                sdis = sqrt ((X (te) - msttrees {ward}.X).^2 + ...
                    (Y (te) - msttrees {ward}.Y).^2 + ...
                    (Z (te) - msttrees {ward}.Z).^2);
                [dis(te) idis(te)] = min (sdis); % dis contains closest node on tree
            end
        end
        dis (dis > thr) = NaN; % don't allow to go beyond the threshold distance
        % sort points according to their distance to the tree:
        [rdist{ward} irdist{ward}] = sort (dis);
        % set actual vicinity to all points in distance tthr of root
        avic {ward} = sum (rdist {ward} < tthr {ward});
        if strfind (options, '-s'),
            plot3 (X (irdist {ward}(1 : avic{ward})), ...
                Y (irdist {ward}(1 : avic{ward})), ...
                Z (irdist {ward}(1 : avic{ward})), 'g.');
        end
        % vector index in XYZ all points which are in vicinity but not yet on tree
        inX{ward} = irdist {ward} (1 : avic {ward});
        if ~isempty (DIST),
            % index of open points in distance matrix DIST:
            iDISTP {ward} = inX {ward} + TSUM;
            % initialize distance vector including path to root and extra
            % distance:
            dplen {ward} = rdist {ward}(1 : avic{ward}) + bf * plen {ward} (idis (inX {ward}))' + ...
                Derr * (1 - DIST (iDIST {ward} (idis (inX {ward}))', iDISTP {ward}));
        else
            % initialize distance vector including path to root
            dplen {ward} = rdist {ward} (1 : avic {ward}) + bf * plen {ward} (idis (inX {ward}))';
        end
        % initialize index vector indicating to which point on tree an open point
        % is closest to:
        ITREE {ward} = idis (inX {ward});
    else
        % starting path length to the root in the tree is just 0
        plen {ward} = 0;
        % threshold distance determining the vicinity circle
        tthr {ward} = thr;
        % calculate distance from all open points to root
        root_dist {ward} = sqrt ((X - msttrees {ward}.X(1)).^2 +...
            (Y - msttrees {ward}.Y(1)).^2 + (Z - msttrees {ward}.Z(1)).^2)';
        % dis contains closest node on tree
        dis = root_dist {ward};% simply the distance to root in this case
        dis (dis > thr) = NaN; % don't allow to go beyond the threshold distance
        % sort points according to their distance to the root:
        [rdist{ward} irdist{ward}] = sort (root_dist {ward});
        % set actual vicinity to all points in distance tthr of root
        avic {ward} = sum (rdist {ward} < tthr {ward});
        if strfind (options, '-s'),
            plot3 (X (irdist {ward} (1 : avic {ward})), ...
                Y (irdist {ward} (1 : avic {ward})), ...
                Z (irdist {ward} (1 : avic {ward})), 'g.');
        end
        % vector index in XYZ all points which are in vicinity but not yet on tree
        inX {ward} = irdist {ward} (1 : avic {ward});
        if ~isempty (DIST),
            % index of open points in distance matrix DIST:
            iDISTP{ward} = inX {ward} + TSUM;
            % initialize distance vector including path to root and extra
            % distance:
            dplen {ward} = dis (inX {ward}) + ...
                Derr * (1 - DIST (iDIST {ward} (1), iDISTP {ward}));
        else
            % initialize distance vector including path to root
            dplen {ward} = dis (inX {ward});
        end
        % initialize index vector indicating to which point on tree an open point
        % is closest to: in the beginning all points are closest to the root (#1)
        ITREE {ward} = ones (1, avic {ward});
    end
end

if strfind (options, '-w'),
    HW = waitbar (0, 'finding minimum spanning tree...');
    set (HW, 'Name', '..PLEASE..WAIT..YEAH..');
end

% find closest point one by one
counter = 0; flag = 1; indx = zeros (size (X, 1), 2);
while ~isempty (dplen) && (flag == 1),
    if strfind (options, '-w'),
        if mod (counter, 500) == 0,
            waitbar (counter / lenX, HW);
        end
    end
    flag = 0;
    for ward = 1 : lent,  % proceed iteratively one tree at a time
        % choose closest point:
        [idis iopen] = min (dplen {ward}, [], 2); % iopen: index in Open points of vicinity
        itree = ITREE {ward} (iopen);           % itree: index in tree
        if ~isnan (idis), % NaN means distance is bigger than threshold (see below)
            % update vicinity distance:
            tthr {ward} = max (tthr {ward}, thr + root_dist {ward} (inX {ward} (iopen)));
            % update adjacency matrix dA
            msttrees {ward}.dA (end + 1, itree)   = 1;
            msttrees {ward}.dA (itree,   end + 1) = 0;
            N {ward} = N {ward} + 1; % update number of nodes in tree
            % calculate the actual distance of the point to its closest
            % partner in the tree (itree)
            dis = sqrt ((X (inX {ward} (iopen)) - msttrees {ward}.X (itree)).^2+...
                (Y (inX {ward} (iopen)) - msttrees {ward}.Y (itree)).^2+...
                (Z (inX {ward} (iopen)) - msttrees {ward}.Z (itree)).^2);
            dis (dis > thr) = NaN; % don't allow to go beyond the threshold distance
            % and add this to the path length of that point (itree) to get
            % the total path length to the new point:
            plen_new = plen {ward} (itree) + dis;
            plen_new (plen_new > mplen) = NaN; % don't allow to go beyond a maximum path length
            plen {ward} = [plen{ward}; plen_new];
            % update node coordinates in tree
            msttrees {ward}.X = [msttrees{ward}.X; X(inX {ward} (iopen))];
            msttrees {ward}.Y = [msttrees{ward}.Y; Y(inX {ward} (iopen))];
            msttrees {ward}.Z = [msttrees{ward}.Z; Z(inX {ward} (iopen))];
            msttrees {ward}.D = [msttrees{ward}.D; 1];
            msttrees {ward}.R = [msttrees{ward}.R; 1];
            % remember which node came from where:
            indx (inX {ward} (iopen), :) = [ward length(msttrees {ward}.X)];
            if ~isempty (DIST), % move node index of DIST matrix from open points to tree
                iDIST  {ward}         = [iDIST{ward} iDISTP{ward}(iopen)];
                iDISTP {ward} (iopen) = [];
            end
            % eliminate point in other trees:
            for mation = [1:ward-1 ward+1:lent],
                iiopen = find (inX {mation} == inX {ward} (iopen));
                dplen  {mation} (iiopen) = [];
                inX    {mation} (iiopen) = [];
                ITREE  {mation} (iiopen) = [];
                iiiopen = find (irdist {mation} == inX {ward} (iopen));
                irdist {mation} (iiiopen) = [];
                rdist  {mation} (iiiopen) = [];
                if iiiopen <= avic {mation}, avic {mation} = avic {mation} - 1; end;
                if ~isempty (DIST), % get rid of indices in DIST of open nodes in all other trees
                    iDISTP {mation} (iiopen) =[];
                end
            end
            % get rid of point in open points in vicinity
            dplen {ward} (iopen) = []; inX {ward} (iopen) = []; ITREE {ward} (iopen) = [];
            % compare point to dplen to point which is now in the tree
            if ~isempty (dplen {ward}), % update in current vicinity
                dis = (sqrt ((X (inX {ward}) - msttrees {ward}.X (end)).^2 + ...
                    (Y (inX {ward}) - msttrees {ward}.Y (end)).^2 + ...
                    (Z (inX {ward}) - msttrees {ward}.Z (end)).^2));
                dis (dis > thr) = NaN;
                if ~isempty (DIST), % add DISTance matrix factor to Error
                    [dplen{ward} idplen] = min ([dplen{ward}; ...
                        (dis+bf*plen{ward}(end) + ...
                        Derr*(1-DIST(iDISTP{ward},iDIST{ward}(end))) )'],[],1);
                else % 
                    [dplen{ward} idplen] = min([dplen{ward}; ...
                        (dis+bf*plen{ward}(end))'],[],1);
                end
                ITREE{ward} (idplen == 2) = N {ward}; % last added point
                if strfind (options, '-b'),
                    if sum (msttrees {ward}.dA (:, itree)) > 1,
                        iCT = find (sum (msttrees {ward}.dA, 1) < 2); % non-branch points
                        inewbp = find (ITREE {ward} == itree);
                        if ~isempty (inewbp),
                            for tetete = 1 : length (inewbp),
                                dis = (sqrt ((X (inX {ward} (inewbp (tetete))) - msttrees {ward}.X (iCT)).^2+...
                                    (Y (inX {ward} (inewbp (tetete))) - msttrees {ward}.Y (iCT)).^2+...
                                    (Z (inX {ward} (inewbp (tetete))) - msttrees {ward}.Z (iCT)).^2));
                                dis (dis > thr) = NaN;
                                if ~isempty (DIST),
                                    [d1 id1] = min (dis + bf * plen {ward} (iCT) + ...
                                        Derr * (1 - DIST (iDISTP {ward} (inewbp (tetete)), ...
                                        iDIST {ward} (iCT)))', [], 1);
                                else
                                    [d1 id1] = min (dis + bf * plen {ward} (iCT), [], 1);
                                end
                                dplen {ward} (inewbp (tetete)) = d1;
                                ITREE {ward} (inewbp (tetete)) = iCT (id1);
                            end
                        end
                    end
                end
            end
            % update vicinity
            vic = sum (rdist {ward} < tthr {ward});
            % update dplen etc... according to new vicinity
            if vic > avic {ward},
                indo = irdist {ward} (avic {ward} + 1 : vic); % new points in vicinity
                leno = length (indo); % number of new points
                % repeat the old story with all new points:
                if strfind (options, '-b'),
                    iCT = find (sum (msttrees {ward}.dA, 1) < 2); % non-branch points
                    dis = sqrt ((repmat (X (indo)', length (iCT), 1) - ...
                        repmat (msttrees {ward}.X (iCT), 1, leno)).^2 + ...
                        (repmat (Y (indo)', length (iCT), 1) - ...
                        repmat (msttrees {ward}.Y (iCT), 1, leno)).^2 + ...
                        (repmat (Z (indo)', length (iCT), 1) - ...
                        repmat (msttrees {ward}.Z (iCT), 1, leno)).^2);
                    dis (dis > thr) = NaN;
                    if ~isempty (DIST),
                        [d1 id1] = min (dis + bf * repmat (plen {ward} (iCT), 1, leno) + ...
                            Derr * (1 - DIST (sub2ind (size (DIST), ...
                            repmat (indo, length (iCT), 1), ...
                            repmat (iDIST {ward} (iCT), leno, 1)'))), [], 1);
                    else
                        [d1 id1] = min (dis + bf * repmat (plen {ward} (iCT), 1, leno), [], 1);
                    end
                    id1 = iCT (id1);
                else
                    dis = sqrt ((repmat (X (indo)', N {ward}, 1) - ...
                        repmat (msttrees {ward}.X, 1, leno)).^2 + ...
                        (repmat (Y (indo)', N {ward}, 1) - ...
                        repmat (msttrees {ward}.Y, 1, leno)).^2 + ...
                        (repmat (Z (indo)', N {ward}, 1) - ...
                        repmat (msttrees {ward}.Z, 1, leno)).^2);
                    dis (dis > thr) = NaN;
                    if ~isempty (DIST),
                        [d1 id1] = min (dis + bf * repmat (plen {ward}, 1, leno) + ...
                            Derr * (1 - DIST (sub2ind (size (DIST), repmat (indo, N {ward}, 1), ...
                            repmat (iDIST {ward}, leno, 1)'))), [], 1);
                    else
                        [d1 id1] = min (dis + bf * repmat (plen {ward}, 1, leno), [], 1);
                    end
                end
                dplen {ward} = [dplen{ward}  d1];
                ITREE {ward} = [ITREE{ward} id1];
                inX {ward} = [inX{ward} indo];
                if ~isempty (DIST),
                    iDISTP {ward} = [iDISTP{ward} indo+TSUM];
                end
                if strfind (options, '-s'),
                    plot3 (X (indo), Y (indo), Z (indo), 'g.');
                end
                avic {ward} = vic;
            end
            if strfind (options, '-s'),
                set (HP {ward}, 'visible', 'off');
                HP {ward} = plot_tree (msttrees {ward}, colors (ward, :));
                drawnow;
            end
            if strfind (options, '-t'),
                timetrees{ward}{end+1} = msttrees {ward};
            end
            flag = 1; % indicates that a point has been added in at least one tree
            counter = counter + 1;
        end
    end
end
if strfind (options, '-w'),
    close (HW);
end
if strfind (options, '-t'),
    msttrees = timetrees;
end
if (nargout > 0),
    if lent == 1,
        tree = msttrees {1};
    else
        tree = msttrees;
    end
else
    trees = [trees msttrees];
end
