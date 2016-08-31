% LOADSL_TREE   Loads a tree from the SpineLab .stxt format.
% (trees package)
%
% [tree, name, path] = loadSL_tree (name, options)
% ----------------------------------------------
%
% loads the metrics and the corresponding directed adjacency matrix to
% create a tree in the trees structure. This is a  specialised import
% function for SpineLab files (from the lab of Gabriel Wittum)
%
% Input
% -----
% - name::string: name of the file to be loaded, including the extension.
%                 {DEFAULT : open gui fileselect, replaces format entry}
%     formats are file extensions: {DEFAULT : '.stxt'}
%     '.stxt': from the SpineLab format stxt. This format first puts down
%     the coordinates attributed to each node. Then the connectivity is
%     described by an undirected edge between two nodes. The node that was
%     previously used in this list becomes the parent node.
% - options::string {DEFAULT : '-r'}
%     '-s' : show
%     '-r' : repair tree, preparing trees for most TREES toolbox functions
%
% Output
% ------
% if no output is declared the tree is added to trees
% - tree:: structured output tree
% - name::string: name of output file; [] no file was selected -> no output
% - path::sting: path of the file, complete string is therefore: [path name]
%
% Example
% -------
% tree = loadSL_tree;
%
% See also load_tree neuron_tree swc_tree start_trees (neu_tree.hoc)
%
% the TREES toolbox: edit, visualize and analyze neuronal trees
% Copyright (C) 2009  Hermann Cuntz

function varargout = loadSL_tree (tname, options)

% trees : contains the tree structures in the trees package
global trees

if (nargin<1)||isempty(tname),
     [tname path] = uigetfile ({'*.stxt', ...
         'SpineLab format (only *.stxt)'}, ...
        'Pick a file', 'multiselect', 'off');
    if tname == 0,
        varargout {1} = []; varargout {2} = []; varargout {3} = [];
        return
    end
else
    path = '';
end
format = tname  (end - 4 : end); % input format from extension:
% extract a sensible name from the filename string:
nstart = unique ([0 strfind(tname, '/') strfind(tname, '\')]);
name   = tname  (nstart (end) + 1 : end - 5);

if (nargin<2)||isempty(options)
    if strcmp (format, '.stxt'),
        options = '-r';
    else
        options = '';
    end
end

switch format,
    case '.stxt' % this is then swc
        if ~exist ([path tname], 'file'),
            error ('no such file...');
        end
        A        = textread ([path tname], '%s', 'delimiter', '\n');
        wline    = str2num (A {1});
        stxt     = [];        
        for ward = 2 : wline (1) + 1,
            stxt = [stxt; str2num(A {ward})];
        end
        Xs       = stxt (:, 2);  % X-locations of nodes on tree
        Ys       = stxt (:, 3);  % Y-locations of nodes on tree
        Zs       = stxt (:, 4);  % Z-locations of nodes on tree
        stxt     = [];
        for ward = wline (1) + 2 : size (A, 1)
            stxt = [stxt; str2num(A {ward})];
        end
        N        = size   (Xs, 1);
        dA = cell (1, 1); iD = cell (1, 1);
        X = cell (1, 1); Y = cell (1, 1); Z = cell (1, 1);
        dA {1}   = [];
        iD {1}   = [1];
        X  {1}   = Xs (1);
        Y  {1}   = Ys (1);
        Z  {1}   = Zs (1);
        i1       = stxt (:, 2) + 1;
        i2       = stxt (:, 3) + 1;
        tree    = cell (1, 1);
        
        for ward = 1 : size (stxt, 1)
            for te = 1 : length (iD)
                indy1 = find (i1 (ward) == iD {te}, 1);
                indy2 = find (i2 (ward) == iD {te}, 1);
                if ~isempty (indy1) || ~isempty (indy2)
                    break
                end
            end
            if ~isempty (indy1)
                X  {te} (end+1) = Xs (i2(ward));
                Y  {te} (end+1) = Ys (i2(ward));
                Z  {te} (end+1) = Zs (i2(ward));
                
                dA {te} (length (X{te}), indy1) = 1;
                iD {te} (end+1) = i2(ward);
            elseif ~isempty (indy2)
                X  {te} (end+1) = Xs (i1(ward));
                Y  {te} (end+1) = Ys (i1(ward));
                Z  {te} (end+1) = Zs (i1(ward));
                
                dA {te} (length (X{te}), indy2) = 1;
                iD {te} (end+1) = i1(ward);                
            else
                iD {end+1}      = [i1(ward) i2(ward)];
                X  {length(iD)} = Xs ([i1(ward) i2(ward)])';
                Y  {length(iD)} = Ys ([i1(ward) i2(ward)])';
                Z  {length(iD)} = Zs ([i1(ward) i2(ward)])';
            end
        end
        for ward = 1 : length (dA)
            dA{ward} = [dA{ward} ...
                zeros(size (dA {ward}, 1), ...
                size (dA {ward}, 1) - size (dA {ward}, 2))];
        end
        for ward = 1 : length (dA)
            tree {ward}.dA = sparse (dA {ward});
            tree {ward}.X  = X {ward}';
            tree {ward}.Y  = Y {ward}';
            tree {ward}.Z  = Z {ward}';
            tree {ward}.D  = X {ward}' * 0 + 1;
            tree {ward}.R  = X {ward}' * 0 + 1;
            tree {ward}.rnames = {'dendrite'};
            tree {ward}.name   = name;
        end
    otherwise
        warning ('TREES:IO', 'format unknown'); varargout {1} = [];
        varargout {2} = tname; varargout {3} = path; return
end

if strfind (options, '-r'),
    if iscell (tree),
        for ward = 1 : length (tree),
            if iscell (tree {ward}),
                for te = 1 : length (tree {ward}),
                    tree{ward}{te} = repair_tree (tree{ward}{te});
                end
            else
                tree {ward} = repair_tree (tree{ward});
            end
        end
    else
        tree = repair_tree (tree);
    end
end

if strfind (options, '-s'),
    clf; hold on; title ('loaded trees');
    if iscell (tree),
        for ward = 1 : length (tree),
            if iscell (tree {ward}),
                for te = 1 : length (tree {ward}),
                    plot_tree (tree{ward}{te});
                end
            else
                plot_tree (tree{ward});
            end
        end
    else
        plot_tree (tree);
    end
    xlabel ('x [\mum]'); ylabel ('y [\mum]'); zlabel ('z [\mum]');
    view (3); grid on; axis image;
end

if (nargout > 0)
    varargout {1} = tree; % if output is defined then it becomes the tree
    varargout {2} = tname; varargout {3} = path;
else
    trees {length (trees) + 1} = tree; % otherwise add to end of trees cell array
end
