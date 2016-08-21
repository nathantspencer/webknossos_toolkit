% GENE_TREE   String describing tree topology.
% (trees package)
% 
% genes = gene_tree (intrees, options)
% ------------------------------------
% 
% Returns for a cell array of cell arrays of trees intrees, a cell array of
% cell arrays of topological genes (for each tree one). The two-depth of
% the input/output arrays allows the comparison between different groups of
% neuronal trees. The topological gene returns for a sorted labelling of a
% tree (see "sort_tree") for all branches (delimited by topological points)
% the ending point type (termination or branch) and the metric length of
% the branch.
%
% Input
% -----
% - intrees::2-depth cell array:cell array of cell array of trees {DEFAULT:
%     {trees}}
% - options::string: {DEFAULT: ''}
%     '-s' : show
%
% Output
% ------
% - genes::cell array of cell array of 2 horizontal vectors: topology strings.
%
% Example
% -------
% gene = gene_tree ({{sample2_tree}}, '-s'); gene{1}
% % or:
% dLPTCs = load_tree ('dLPTCs.mtr');
% gene = gene_tree (dLPTCs, '-s');
%
% See also BCT_tree isBCT_tree sort_tree
% Uses sort_tree
%
% the TREES toolbox: edit, visualize and analyze neuronal trees
% Copyright (C) 2009  Hermann Cuntz

function  genes = gene_tree (intrees, options)

% trees : contains the tree structures in the trees package
global trees

if (nargin < 1)||isempty(intrees),
    intrees = {trees}; % {DEFAULT trees: trees cell array} 
end;

if (nargin < 2)||isempty(options),
    options = ''; % {DEFAULT: no option}
end

genes = cell(1,1); names = cell(1,1);
counter = 0;
if strfind(options,'-w'), % waitbar option: initialization
    HW = waitbar(0,'sequencing trees...');
    set(HW,'Name','..PLEASE..WAIT..YEAH..');
end
for ward = 1:length(intrees),
    for te = 1:length(intrees{ward}),
        if strfind(options,'-w'), % waitbar option: update
            waitbar(te/length(intrees{ward}),HW);
        end
        counter = counter + 1;
        name = intrees{ward}{te}.name;
        names{counter} = name;
        [gene pathlen] = getgene(intrees{ward}{te});
        genes{counter} = gene;
        if strfind(options,'-s'), % show option
            clen = cumsum(pathlen+5);
            HL = line([[0; clen(1:end-1)], clen-5]',...
                (counter-1 + 2*(ward-1))+zeros(length(clen),2)');
            set(HL,'linewidth',4);
            HT = text (-10, counter-1 + 2*(ward-1), name);
            set(HT,'HorizontalAlignment','right');
            for ce = 1:length(HL),
                if genes{counter}(ce,2)==0,
                    set(HL(ce),'color',[0 0 0]);
                else
                    set(HL(ce),'color',[0 1 0]);
                end
            end
        end
    end
end
if strfind(options,'-w'), % waitbar option: close
    close(HW);
end










% if strfind(options,'-s'), % show option
%     clf; hold on; shine; HP = plot_tree (intree, [0 1 0]); set(HP,'facealpha',.5);
%     T = vtext_tree (intree, typeN, [0 0 0], [0 0 10]); set (T, 'fontsize',14);
%     ydim = ceil(length(typeN)/50);
%     if ischar(typeN),
%         str = reshape([typeN',char(zeros(1,ydim*50-length(typeN)))],50,ydim)';
%     else
%         str = num2str(typeN'); str(isspace(str)) = [];
%         str = reshape([str,char(zeros(1,ydim*50-length(typeN)))],50,ydim)';
%     end
%     T = title (strvcat('branching gene:',str));%('termination points');
%     set (T, 'fontsize',14,'color',[0 0 0]);
%     xlabel ('x [\mum]'); ylabel ('y [\mum]'); zlabel ('z [\mum]');
%     view(2); grid on; axis image;
% end
end

function [gene pathlen] = getgene (tree)
tree = sort_tree(tree,'-LO'); % sort tree to be BCT conform, heavy parts left
iBT = find(~C_tree(tree)); % vector containing termination and branch point indices
ipar = ipar_tree(tree); % parent index structure (see "ipar_tree")
% find index to parent paths only until first branch point:
iparcheck = zeros(size(ipar));
for ce = 1:size(iBT,1),
    iparcheck(ipar==iBT(ce)) = 1;
end
iparcheck(:,1) = 0; iparcheck = cumsum(iparcheck,2)>0;
ipar = ipar.*(1-iparcheck); % cutout those paths
len0 = [0; len_tree(tree)]; % vector containing length values of tree segments [um]
pathlen = sum(len0(ipar+1),2); pathlen = pathlen(iBT); % path length along those paths
typeN = typeN_tree(tree);
typer = typeN(iBT); % branch and termination point number of daughters
M = [pathlen typer]; reshape(M',numel(M),1); gene = M;
end
