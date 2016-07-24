% RESAMPLE_TREE   Redistributes nodes on tree.
% (trees package)
%
% tree = resample_tree (intree, sr, options)
% ------------------------------------------
%
% resamples a tree to equidistant nodes of distance sr. In order to do so
% some abstraction principles need to be arbitrarily set. This function
% alters the original morphology.
%
% Input
% -----
% - intree::integer/tree:index of tree in trees or structured tree
% - sr::scalar: sampling [um]  {DEFAULT: 10 um}
% - options::string: {DEFAULT: '-w'}
%     '-s'  : show
%     '-e'  : echo modified nodes
%     '-w'  : waitbar
%     '-d'  : interpolates diameters (changes total surface & volume)
%     '-v'  : do not collapse branchings of small angles {NOT DEFAULT}
%     imprecise resampling. Resampling automatically reduces length and
%     that reduces the sr-length pieces sligthly. However, this can be
%     altered by:
%     '-l' : length conservation - reduced pieces are lenghtened to
%        reflect the original path lengths in the tree. But the total
%        tree size expands in the process (no good for automated
%        reconstruction procedure for example)
%     %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%     '-o' : size conservation - scholl-like procedure which distributes nodes
%        on tree disregarding the path lengths. Therefore the resulting
%        length of the tree is shorter. But the individual pieces are
%        exactly sr length. (NOTE! NOT IMPLEMENTED YET)
%     '-h' : harmonika - in order to conserve both space and cable length
%        a wrigliness is introduced. (NOTE! NOT IMPLEMENTED YET)
%     '-3' : collapse multifurcations (may reduce total length
%        drastically) (NOTE! NOT IMPLEMENTED YET)
%
% Output
% ------
% if no output is declared the tree is changed in the trees structure
% - tree::tree: altered tree structure
%
% Example
% -------
% resample_tree (sample_tree, 5, '-s')
%
% See also insertp_tree, insert_tree, delete_tree, cat_tree, recon_tree
% Uses T_tree Pvec_tree insertp_tree morph_tree len_tree idpar_tree
% delete_tree
%
% the TREES toolbox: edit, visualize and analyze neuronal trees
% Copyright (C) 2009  Hermann Cuntz

function varargout = resample_tree (intree, sr, options)

% trees : contains the tree structures in the trees package
global trees

if (nargin < 1)||isempty(intree),
    intree = length(trees); % {DEFAULT tree: last tree in trees cell array}
end;

ver_tree (intree); % verify that input is a tree structure

% use full tree for this function
if ~isstruct (intree),
    tree = trees {intree};
else
    tree = intree;
end

if (nargin < 2)||isempty(sr),
    sr = 10; % {DEFAULT: 10 um spacing between the nodes}
end

if (nargin < 3)||isempty(options),
    options = '-w'; % {DEFAULT: waitbar}
end

if strfind (options, '-s'),
    clf; hold on;
end

%%%%%%
% attach a sr/2 um piece at each single terminal:
iT   = find (T_tree (tree)); % vector containing termination point indices
len  = len_tree (tree); % vector containing length values of tree segments [um]
lenT = len;
lenT (iT) = len(iT) + .5*sr; % vector with new lengths is ready for morphing
% (conserve options from resample_tree  but not show -> waitbar)
% - options2 is used again further below -
i1 = strfind (options, '-s'); options2 = options; options2 (i1 : i1+1) = '';
if isempty (options2), options2 = 'none'; end;
 % see "morph_tree", changes length values but preserves topology and
 % angles:
tree = morph_tree (tree, lenT, options2);

%%%%%%
% initialize coordinates of nodes and adjacency matrix
idpar = idpar_tree (tree); % vector containing index to direct parent
Plen  = Pvec_tree  (tree); % path length from the root [um]
dA    = tree.dA;           % directed adjacency matrix of tree
N     = size (dA, 1);      % number of nodes in tree
mdA   = dA ^ 0;            % = eye(N,N) but twice as fast!
% these all will contain the new tree:
ndA   = dA; nindy = (1 : N)';
nX = tree.X; nY = tree.Y; nZ = tree.Z; nD = tree.D;

if strfind (options, '-w'), % waitbar option: initialization
    HW = waitbar (0, 'insert points on all paths ...');
    set (HW, 'Name', 'please wait...');
end
for ward = 1 : N, % for each node look at point to add on the path
    if strfind (options, '-w'), % waitbar option: update
        if mod (ward, 500) == 0,
            waitbar (ward ./ N, HW);
        end
    end
    ic = find (mdA * dA (:, 1)); % children index
    mdA = mdA * dA; % walk through the adjacency matrix
    ip = idpar (ic); % parent index
    for te = 1 : length (ic),
        Gpath = (0 : sr : Plen (ic (te))); Gpath = Gpath (Gpath > Plen (ip (te)));
        if ~isempty (Gpath),
            lenG  = length( Gpath);
            nN    = size (ndA, 1);
            ndA (ic (te), ip (te)) = 0;
            ndA   = [ndA sparse(nN, lenG)];
            ndA   = [ndA; [sparse(lenG, nN) spdiags(ones (lenG, 1), -1, lenG, lenG)]];
            ndA (nN + 1, ip (te)) = 1; ndA (ic (te), nN + lenG) = 1;
            rpos  = ((Gpath - Plen (ip (te))) / (Plen (ic (te)) - Plen (ip (te))))';
            nX    = [nX; nX(ip (te))+rpos*(nX (ic (te))-nX (ip (te)))];
            nY    = [nY; nY(ip (te))+rpos*(nY (ic (te))-nY (ip (te)))];
            nZ    = [nZ; nZ(ip (te))+rpos*(nZ (ic (te))-nZ (ip (te)))];
            nD    = [nD; nD(ip (te))+rpos*(nD (ic (te))-nD (ip (te)))];      
            nindy = [nindy; ones(lenG, 1)*ic(te)];    
        end
    end
end
if strfind (options, '-w'), % waitbar option: close
    close (HW);
end

% build the new tree
ntree = []; ntree.dA = ndA; ntree.X = nX; ntree.Y = nY; ntree.Z = nZ;
if strfind (options, '-d'),
    ntree.D = nD;
end

% expand vectors of form Nx1
S = fieldnames (tree);
for te = 1 : length (S)
    if (~strcmp (S{te}, 'dA') && ~strcmp (S{te}, 'X') && ...
            ~strcmp (S{te}, 'Y') && ~strcmp (S{te}, 'Z')),
        if (~isempty (strfind (options, '-d')) && strcmp (S{te}, 'D')) 
        else
            vec = tree.(S{te});
            if isvector(vec) && (numel (vec) == N),
                ntree.(S{te}) = vec (nindy);
            else
                ntree.(S{te}) = vec;
            end
        end
    end
end

tree = delete_tree (ntree, 2 : N); % resampled tree

if isempty (strfind (options, '-v')),
    % a bit complicated for collapsing multifurcations:
    iF = [1; (N+1 : size(ntree.dA))'];
    % collapse small angle branches:
    Bs = find (sum (tree.dA) > 1)'; % multibranch point indices
    ipar_ntree = ipar_tree (ntree); % memorize all parent relationships of ntree
    len_ntree  = len_tree (ntree);
    collab = {};
    for ward = 1 : length (Bs),
        % here are the daughters of the branching point in the newly pruned
        % tree:
        idaughters = find (tree.dA (:, Bs(ward)));
        % but we kept old tree ntree and can check
        LIPAR = {};
        for te = 1 : length (idaughters),
            % beware of indices again:
            % points in original tree ntree from branching point to daughter:
            lipar     = ipar_ntree (iF (idaughters (te)), :);
            LIPAR{te} = lipar (1 : find (lipar == iF (Bs (ward))) - 1);
        end
        DIS = [];
        for te1 = 1 : length (idaughters)
            for te2 = te1+1 : length (idaughters)
                DIS(end+1,:) = [te1 te2 sum(len_ntree (unique ([LIPAR{te1} LIPAR{te2}])))/(2*sr)];
            end
        end
        for te = 1 : size (DIS, 1),
            if DIS (te, 3) < 0.75,
                collab {end + 1} = idaughters (DIS (te, 1 : 2));
            end
        end
    end
    % collab now contains pairs of indices of nodes to collapse together
    child  = child_tree (tree); 
    itodel = cat (2, collab{:}); % to collapse
    % collapse the point with least amount of child nodes:
    [i1 icollapse] = min (child (itodel));
    if ~isempty (icollapse),
        % (3- icollapse is the other node in the pair)...
        for ward = 1:size (collab, 2),
            XM = mean (tree.X (collab {ward}));
            YM = mean (tree.Y (collab {ward}));
            ZM = mean (tree.Z (collab {ward}));
            tree.X (collab {ward}) = XM;
            tree.Y (collab {ward}) = YM;
            tree.Z (collab {ward}) = ZM;
            tree.dA (logical (tree.dA (:, collab {ward} (icollapse (ward)))), ...
                collab {ward} (3 - icollapse (ward)))     = 1;
            tree.dA (:, collab {ward} (icollapse (ward))) = 0;
        end
        tree = delete_tree (tree, itodel (sub2ind (size (itodel), icollapse, 1 : length (icollapse))));
    end
end

if ~isempty(strfind(options,'-l')),
    % now after deleting points on the way the length of an edge is not sr
    % anymore (because we cut the paths short), prolong all pieces to sr via
    % morphing:
    tree = morph_tree (tree, sr * ones(length (tree.X), 1), options2);
end

















if strfind (options, '-s'),
    clf; hold on; shine; HP = plot_tree (intree, [], -120, [], 2, '-b');
    set(HP,'facecolor','none','linestyle','-','edgecolor',[0 0 0]);
    HP = plot_tree (tree, [1 0 0], [], [], 2, '-b');
    set(HP,'facecolor','none','linestyle','-','edgecolor',[1 0 0]);
    HP(1) = plot(1,1,'k-');HP(2) = plot(1,1,'r-');
    set(HP(2),'markersize',48);
    legend(HP,{'old tree','new tree'}); set(HP,'visible','off');
    title ('resampling tree');
    xlabel ('x [\mum]'); ylabel ('y [\mum]'); zlabel ('z [\mum]');
    view(2); grid on; axis image;
end

if strfind (options,'-e'),
    display('resample_tree: added some nodes');
end

if (nargout > 0)||(isstruct(intree)),
    varargout{1} = tree;
else
    trees{intree} = tree;
end








