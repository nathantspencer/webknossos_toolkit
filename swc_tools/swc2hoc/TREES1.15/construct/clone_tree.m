% CLONE_TREE   Cloning a tree type using the minimum spanning tree constructor.
% (trees package)
%
% trees = clone_tree (intrees, num, bf, options)
% ----------------------------------------------
%
% Creates as set of num trees similar to an input set of trees
% intrees by distributing points randomly in the spanning fields of the
% average intrees, scaling them within the variance of intrees and
% connecting them with "MST_tree", the minimum spanning tree constructor.
% "MST_tree" requires the balancing factor bf between minimization of path
% length and total wire length. (this script should be revised and is not
% generally usable. This should be adapted for each separate project.
%
% Input
% -----
% - intrees::integer:index of tree in trees or structured tree or
%     cell-array of trees.
% - num::integer: number of clones requested. (can take very long!!)
%     {DEFAULT: 1}
% - bf::number between 0 ~2: balancing factor {DEFAULT: 0.4}
% - options::string: {DEFAULT '-w'}
%     '-s' : show plot
%     '-w' : with waitbar
%
% Output
% ------
% if no output is declared the trees are added in trees
% - trees:: cell array of structured output trees
%
% Example
% -------
% clone_tree (sample_tree, 5, .4, '-s')
%
% See also MST_tree rpoints_tree quaddiameter_tree BCT_tree gscale_tree
% Uses MST_tree rpoints_tree quaddiameter_tree gscale_tree
%
% the TREES toolbox: edit, visualize and analyze neuronal trees
% Copyright (C) 2009  Hermann Cuntz

function ctrees = clone_tree (intrees, num, bf, options)

% trees : contains the tree structures in the trees package
global trees

if (nargin < 1)||isempty(intrees),
    intrees = length(trees); % {DEFAULT tree: last tree in trees cell array}
end

if (nargin < 2)||isempty(num),
    num = 1; % {DEFAULT number of trees: one}
end

if (nargin < 3)||isempty(bf),
    bf = 0.4; % {DEFAULT balancing factor (see "MST_tree")}
end

if (nargin < 4)||isempty(options),
    options = '-w';
end

spanning = gscale_tree (intrees);

Rsoma =    find (strcmp  (spanning.regions, 'soma'));
Rapical =  find (strcmp  (spanning.regions, 'apical'));
Rspines =  find (strcmp  (spanning.regions, 'spines')); % not used for now!
Rother =   find (~strcmp (spanning.regions, 'spines') & ...
    ~strcmp (spanning.regions, 'apical') & ...
    ~strcmp (spanning.regions, 'axon') & ...
    ~strcmp (spanning.regions, 'soma'));

if strfind (options, '-w'), % waitbar option: initialization
    HW = waitbar (0, 'creating clones one by one...');
    set (HW, 'Name', '..PLEASE..WAIT..YEAH..');
end

% store artificial trees:
ctrees = cell (1, 1);

for mation = 1 : num,
    if strfind (options, '-w'), % waitbar option: update
        waitbar (mation / num, HW);
    end
    if ~isempty (Rsoma),
        maxD = [];
        for counter = 1 : length (intrees),
            if ~isempty (spanning.iR{Rsoma}{counter}),
                maxD = [maxD max(intrees{counter}.D (spanning.iR{Rsoma}{counter}))];
            end
        end
       % extract typical soma limits from data and create random:
        XL = [randn*std(spanning.xlims {Rsoma}(:, 1))+mean(spanning.xlims {Rsoma}(:, 1)); ...
            randn*std(spanning.xlims   {Rsoma}(:, 2))+mean(spanning.xlims {Rsoma}(:, 2))];
        YL = [randn*std(spanning.ylims {Rsoma}(:, 1))+mean(spanning.ylims {Rsoma}(:, 1)); ...
            randn*std(spanning.ylims   {Rsoma}(:, 2))+mean(spanning.ylims {Rsoma}(:, 2))];
        ZL = [randn*std(spanning.zlims {Rsoma}(:, 1))+mean(spanning.zlims {Rsoma}(:, 1)); ...
            randn*std(spanning.zlims   {Rsoma}(:, 2))+mean(spanning.zlims {Rsoma}(:, 2))];
        tree = MST_tree (1, [mean(XL); XL], [mean(YL); YL], [mean(ZL); ZL], 0 , ...
            10000, 15000, [], 'none');
        tree = resample_tree (tree,  1, 'none');
        tree = jitter_tree   (tree, .1, 4, 'none');
        Dmax = randn * std (maxD) + mean (maxD);
        if Dmax < (mean (maxD) - std (maxD)), Dmax = mean (maxD); end;
        Dlen = sum (len_tree (tree));
        tree.R = tree.R * 0 + 2; tree.rnames = {'new', 'soma'};
    else
        tree.X  = 0;
        tree.Y  = 0;
        tree.Z  = 0;
        tree.dA = sparse(0); tree.D = 1;
        tree.R  = 2;
        tree.rnames = {'new','soma'};
    end
    soma = tree;
    
    % APICAL DENDRITE:
    if ~isempty(Rapical),
        % find all coordinates of all cells which belong to this region:
        XT = cat(2,spanning.X{Rapical}{:})';
        YT = cat(2,spanning.Y{Rapical}{:})';
        ZT = cat(2,spanning.Z{Rapical}{:})';
        % scale with parameters from normal distribution:
        XT = XT*(randn*spanning.stdxdiff(Rapical)+spanning.mxdiff(Rapical))/...
            spanning.mxdiff(Rapical);
        YT = YT*(randn*spanning.stdydiff(Rapical)+spanning.mydiff(Rapical))/...
            spanning.mydiff(Rapical);
        ZT = ZT*(randn*spanning.stdzdiff(Rapical)+spanning.mzdiff(Rapical))/...
            spanning.mzdiff(Rapical);
        % clean single outlier points:
        flag = 1; lenT = ceil(length(XT)/2);
        while flag,
            SR = round(max([max(XT)-min(XT) max(YT)-min(YT)...
                max(ZT)-min(ZT)])/5);
            if isempty(SR)||(SR==0),
                flag = 0;
            else
                [M dX dY dZ] = gdens_tree ([XT YT ZT],SR,[],'none');
                iM = find(M==1); % where there is only one point in a large bin
                if isempty(iM),
                    flag = 0;
                else
                    oo = [];
                    for ward = 1:length(iM),
                        [i1 i2 i3] = ind2sub(size(M),iM(ward));
                        o = find((YT>=dY(i1)-SR/2)&(YT<=dY(i1)+SR/2)&...
                            (XT>=dX(i2)-SR/2)&(XT<=dX(i2)+SR/2)&...
                            (ZT>=dZ(i3)-SR/2)&(ZT<=dZ(i3)+SR/2));
                        oo = [oo o];
                    end
                    if isempty(oo),
                        flag = 0;
                    else
                        XT(oo') = []; YT(oo') = []; ZT(oo') = [];
                    end
                end
            end
            if length(XT)<=lenT,
                flag = 0;
            end
        end
        eucl = eucl_tree([XT YT ZT],[0 0 0]); % euclidean distance to root
        maxeucl = max(eucl); ifar = eucl>maxeucl/2; iclose = eucl<=maxeucl/2;
        
        % start with far points:
        SR = round(max([max(XT(ifar))-min(XT(ifar)) max(YT(ifar))-min(YT(ifar))...
            max(ZT(ifar))-min(ZT(ifar))])/30); if SR==0, SR = 1;end;
        [M dX dY dZ] = gdens_tree ([XT(ifar) YT(ifar) ZT(ifar)],SR,[],'none');
        % distribute 2/3 of points there:
        N = round(2/3*(randn*spanning.stdnBT(Rapical)+spanning.mnBT(Rapical)));
        if N<2/3*(spanning.mnBT(Rapical)-spanning.stdnBT(Rapical)),
            N = round(spanning.mnBT(Rapical));
        end
        % but start with 4x too many:
        [XR YR ZR] = rpoints_tree (M, 4*N, [], dX, dY, dZ, 0, 'none');
        % try out one tree with N points
        [tree1 indx] = MST_tree ({soma}, XR(1:N), YR(1:N), ZR(1:N), bf ,...
            10000, 150000, [], '-b');
        iNEW = zeros(size(tree1.dA,1),1); iNEW(indx(indx(:,2)~=0,2)) = 1;
        theseBT = sum((B_tree(tree1)|T_tree(tree1))&iNEW);
        % and scale up by the number of missing points (MST_tree
        % results in some points becoming continuation points and not
        % branch or termination (BT) points):
        NN = round(N*(N/theseBT)); if NN>3.5*N, NN = round(N*3.5);end
        tree = MST_tree ({soma}, XR(1:NN), YR(1:NN), ZR(1:NN), bf ,...
            10000, 150000, [], '-b');
        idpar = idpar_tree (tree);
        isoma = length (soma.X); % index at which the apical tree is attached (hopefully)
        [ii subtree] = sub_tree (tree, idpar(isoma+1));
        subtree = resample_tree(subtree,5,'none');
        % add the closeby points (same procedure:
        SR = round(max([max(XT(iclose))-min(XT(iclose)) max(YT(iclose))-min(YT(iclose))...
            max(ZT(iclose))-min(ZT(iclose))])/30);
        [M dX dY dZ] = gdens_tree ([XT(iclose) YT(iclose) ZT(iclose)],SR,[],'none');
        % just distribute remaining 1/3 points:
        N = round(1/3*(randn*spanning.stdnBT(Rapical)+spanning.mnBT(Rapical)));
        if N<1/3*(spanning.mnBT(Rapical)-spanning.stdnBT(Rapical)), 
            N = round(spanning.mnBT(Rapical));
        end
        [XR YR ZR] = rpoints_tree (M, 4*N, [], dX, dY, dZ, 0, 'none');
        [tree1 indx] = MST_tree ({subtree}, XR(1:N), YR(1:N), ZR(1:N), bf , ...
            10000, 150000, [], '-b');
        iNEW = zeros(size(tree1.dA,1),1); iNEW(indx(indx(:,2)~=0,2)) = 1;
        theseBT = sum((B_tree(tree1)|T_tree(tree1))&iNEW);
        NN = round(N*(N/theseBT)); if NN>3.5*N, NN = round(N*3.5);end
        subtree = MST_tree ({subtree}, XR(1:NN), YR(1:NN), ZR(1:NN), bf ,...
            10000, 150000, [], '-b');
        subtree.R(subtree.R==1) = subtree.R(subtree.R==1)*0+length(subtree.rnames)+1;
        subtree.rnames = {'new','soma','apical'};
        
        rb1 = spanning.qdiam{Rapical}(:,1); b1 = randn*std(rb1)+mean(mean(rb1));
        if b1<mean(rb1)-std(rb1), b1 = mean(rb1); end
        rb2 = spanning.qdiam{Rapical}(:,2); b2 = randn*std(rb2)+mean(mean(rb2));
        if b2<mean(rb2)-std(rb2), b2 = mean(rb2); end
        qsubtree = quaddiameter_tree(subtree, b1, b2);
        subtree.D(subtree.R==length(subtree.rnames)) = ...
            qsubtree.D(subtree.R==length(subtree.rnames));
    end
    tree = soma;
    % ALL OTHER REGIONS
    for ward = 1:length(Rother),
        % and same procedure for all other regions (see apical), no
        % dividion between far and close though:
        XT = cat(2,spanning.X{Rother(ward)}{:})';
        YT = cat(2,spanning.Y{Rother(ward)}{:})';
        ZT = cat(2,spanning.Z{Rother(ward)}{:})';
        XT = XT*(randn*spanning.stdxdiff(Rother(ward))+spanning.mxdiff(Rother(ward)))/...
            spanning.mxdiff(Rother(ward));
        YT = YT*(randn*spanning.stdydiff(Rother(ward))+spanning.mydiff(Rother(ward)))/...
            spanning.mydiff(Rother(ward));
        ZT = ZT*(randn*spanning.stdzdiff(Rother(ward))+spanning.mzdiff(Rother(ward)))/...
            spanning.mzdiff(Rother(ward));
        % clean single points:
        flag = 1; lenT = ceil(length(XT)/2);
        while flag,
            SR = round(max([max(XT)-min(XT) max(YT)-min(YT)...
                max(ZT)-min(ZT)])/5);
            if isempty(SR)||(SR==0),
                flag = 0;
            else
                [M dX dY dZ] = gdens_tree ([XT YT ZT],SR,[],'none');
                iM = find(M==1);
                if isempty(iM),
                    flag = 0;
                else
                    oo = [];
                    for te = 1:length(iM),
                        [i1 i2 i3] = ind2sub(size(M),iM(te));
                        o = find((YT>=dY(i1)-SR/2)&(YT<=dY(i1)+SR/2)&...
                            (XT>=dX(i2)-SR/2)&(XT<=dX(i2)+SR/2)&...
                            (ZT>=dZ(i3)-SR/2)&(ZT<=dZ(i3)+SR/2));
                        oo = [oo o];
                    end
                    if isempty(oo),
                        flag = 0;
                    else
                        XT(oo') = []; YT(oo') = []; ZT(oo') = [];
                    end
                end
            end
            if length(XT)<=lenT,
                flag = 0;
            end
        end
        SR = round(max([max(XT)-min(XT) max(YT)-min(YT)...
            max(ZT)-min(ZT)])/30);
        [M dX dY dZ] = gdens_tree ([XT YT ZT],SR,[],'none');
        N = round((randn*spanning.stdnBT(Rother(ward))+spanning.mnBT(Rother(ward))));
        if N>5,
            if N<(spanning.mnBT(Rapical)-spanning.stdnBT(Rother(ward))),
                N = round(spanning.mnBT(Rother(ward)));
            end
            [XR YR ZR] = rpoints_tree (M, 4*N, [], dX, dY, dZ, 0, 'none');
            [tree1 indx] = MST_tree ({tree}, XR(1:N), YR(1:N), ZR(1:N), bf ,...
                10000, 150000, [], '-b');
            iNEW = zeros(size(tree1.dA,1),1); iNEW(indx(indx(:,2)~=0,2)) = 1;
            theseBT = sum((B_tree(tree1)|T_tree(tree1))&iNEW);
            NN = round(N*(N/theseBT)); if NN>3.5*N, NN = round(N*3.5);end
            tree = MST_tree ({tree}, XR(1:NN), YR(1:NN), ZR(1:NN), bf ,...
                10000, 150000, [], '-b');
            tree.R(tree.R==1) = tree.R(tree.R==1)*0+length(tree.rnames)+1;
            tree.rnames = [tree.rnames spanning.regions{Rother(ward)}];
        end
        
        rb1 = spanning.qdiam{Rother(ward)}(:,1); b1 = randn*std(rb1)+mean(mean(rb1));
        if (b1<(mean(rb1)-std(rb1))||b1<=0), b1 = mean(rb1); end
        rb2 = spanning.qdiam{Rother(ward)}(:,2); b2 = randn*std(rb2)+mean(mean(rb2));
        if (b2<(mean(rb2)-std(rb2))||b2<=0), b2 = mean(rb2); end
        qtree = quaddiameter_tree(tree, b1, b2);
        tree.D(tree.R==length(tree.rnames)) = qtree.D(tree.R==length(tree.rnames));
    end
    if exist('subtree','var')
        tree = cat_tree (tree, subtree, isoma, 1, 'none');
    end
    [i1 i2 i3] = unique(tree.R); % eliminate obsolete regions
    tree.R = i3; tree.rnames = {tree.rnames{i1}};
    
    btree = resample_tree(elim0_tree(root_tree(tree)),2,'-d');
    btree = smooth_tree(btree,[],[],[],'none');
   
    rampl = spanning.wriggles(:,1); ampl = randn*std(rampl)+mean(rampl);
    if (ampl<(mean(rampl)-std(rampl)))||(ampl<=0), ampl = mean(rampl); end
    rlambda = spanning.wriggles(:,2); lambda = round(randn*std(rlambda)+mean(rlambda));
    if (lambda<(mean(rlambda)-std(rlambda)))||(lambda<=0),
        lambda = round(mean(rlambda));
    end
    btree = jitter_tree (btree, ampl, lambda, 'none');

    if ~isempty(Rsoma)
        btree = soma_tree(btree, Dmax, Dlen);
    end
    
    ctrees{mation} = btree;
end

if strfind (options, '-w'), % waitbar option: close
    close(HW);
end
