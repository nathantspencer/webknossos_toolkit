% SPREAD_TREE   Extracts coordinates to display trees separately.
% (trees package)
%
% [DD outtrees] = spread_tree (intrees, dX, dY, options)
% ------------------------------------------------------
%
% creates a cell array DD same organization as intrees which gives X Y and
% Z coordinates to display trees spread over the surface of a graph. DD is
% then an input to most functions in the "graphical" folder of the TREES
% toolbox (see "plot_tree" for example). If nesting level is 2 deep trees
% are separated in groups additionally.
%
% Input
% -----
% - intrees::integer:cell array of trees. {DEFAULT: cell array trees}
% - dX::value: horizontal spacing {DEFAULT: 50um}
% - dY::value: vertical spacing {DEFAULT: 50um}
% - options::string: {DEFAULT ''}
%     '-s' : show
%
% Output
% ------
% - DD::cell array of 3-tupels: X Y Z coordinates. Organization same as
%     intrees
% - outtrees::cell array of trees: trees with applied translations
%
% Example
% -------
% spread_tree ({sample_tree hsn_tree hss_tree sample2_tree}, [], [], '-s');
%
% See also plot_tree xplore_tree
% Uses X,Y,Z
%
% the TREES toolbox: edit, visualize and analyze neuronal trees
% Copyright (C) 2009  Hermann Cuntz

function [DD outtrees] = spread_tree (intrees, dX, dY, options)

% trees : contains the tree structures in the trees package
global trees

if (nargin < 1)||isempty(intrees),
    intrees = trees; % {DEFAULT: trees cell array}
end;

if (nargin < 2)||isempty(dX),
    dX = 50; % {DEFAULT: trees are 50 um apart horizontally}
end;

if (nargin < 3)||isempty(dY),
    dY = 50; % {DEFAULT: trees are 50 um apart vertically}
end;

if (nargin <4)||isempty(options),
    options = ''; % {DEFAULT: no option}
end

if isstruct (intrees),
    level = 0;
else
    level = 1;
    for ward = 1 : length (intrees),
        if ~isstruct (intrees {ward}),
            level = 2;
        end
    end
end
if (nargout > 1)
    outtrees = intrees;
end
switch level
    case 2
        superY = 0;
        DD = cell (1, length (intrees));
        for te = 1 : length (intrees),
            lent = length (intrees {te});
            X  = zeros (lent, 1);  Y = zeros (lent, 1);  Z = zeros (lent, 1); % minimum positions
            mX = zeros (lent, 1); mY = zeros (lent, 1); mZ = zeros (lent, 1); % position ranges
            for ward = 1 : lent,
                X (ward)  = min (intrees {te}{ward}.X); % minimum positions
                Y (ward)  = max (intrees {te}{ward}.Y);
                Z (ward)  = min (intrees {te}{ward}.Z);
                mX (ward) = max (intrees {te}{ward}.X) - min (intrees{te}{ward}.X); % widths..
                mY (ward) = max (intrees {te}{ward}.Y) - min (intrees{te}{ward}.Y);
                mZ (ward) = max (intrees {te}{ward}.Z) - min (intrees{te}{ward}.Z);
            end
            % sqrtN gives a maximum deflection in X
            sqrtN = sum (mX + dX) ./ sqrt (length (mX)); % make the layout sort of square
            % divide summed up X ranges (+dX) by sqrtN and collect
            % remainder in DDX:
            DDX     = mod ([0; cumsum(mX + dX)], sqrtN); cY = floor ([0; cumsum(mX + dX)] / sqrtN);
            DDX     = DDX (1 : end - 1); cY = cY (1 : end - 1);
            % take from DDX the first empty bit in each line:
            dDDX    = DDX ([1; diff(cY)] > 0); DDX = DDX - dDDX (cY + 1);
            % add in Y the maximum Y-deflection in each line:
            ucY     = unique (cY); mmY = zeros (length (ucY), 1);
            for ward  = 1 : length (ucY), mmY (ward) = max (mY (cY == ucY (ward))); end
            % DDY becomes the cumulative sum of these maximum deflections (+DY)
            mmY     = [0; -cumsum(mmY + dY)]; DDXYZ = [DDX mmY(cY + 1)];
            % DDZ is kept zero, but for each cell:
            dDD     = [DDXYZ zeros(size (DDXYZ, 1), 1)] - [X Y-superY Z];
            DD {te} = num2cell (dDD, 2)';
            superY = superY + dDD (end, 2);
            if (nargout > 1)
                for ward = 1 : length (intrees {te}),
                    outtrees{te}{ward} = tran_tree (intrees{te}{ward}, DD{te}{ward});
                end
            end
        end
    case 1
        lent = length (intrees); % number of trees
        % initialization
        X  = zeros (lent, 1);  Y = zeros (lent, 1);  Z = zeros (lent, 1); % minimum positions
        mX = zeros (lent, 1); mY = zeros (lent, 1); mZ = zeros (lent, 1); % position ranges
        for ward = 1 : lent, % walk through all trees
            X  (ward) = min (intrees {ward}.X); % minimum positions
            Y  (ward) = max (intrees {ward}.Y);
            Z  (ward) = min (intrees {ward}.Z);
            mX (ward) = max (intrees {ward}.X) - min (intrees {ward}.X); % widths etc..
            mY (ward) = max (intrees {ward}.Y) - min (intrees {ward}.Y);
            mZ (ward) = max (intrees {ward}.Z) - min (intrees {ward}.Z);
        end
        % sqrtN gives a maximum deflection in X
        sqrtN   = sum (mX + dX) ./ sqrt (length (mX)); % make the layout sort of square
        % divide summed up X ranges (+dX) by sqrtN and collect remainder in DDX:
        DDX     = mod([0; cumsum(mX + dX)], sqrtN); cY = floor([0; cumsum(mX + dX)] / sqrtN);
        DDX     = DDX(1:end-1); cY = cY(1:end-1);
        % take from DDX the first empty bit in each line:
        dDDX    = DDX([1; diff(cY)] > 0); DDX = DDX - dDDX (cY + 1);
        % add in Y the maximum Y-deflection in each line:
        ucY     = unique (cY); mmY = zeros (length (ucY), 1);
        for ward  = 1 : length (ucY); mmY (ward) = max (mY (cY == ucY (ward))); end
        % DDY becomes the cumulative sum of these maximum deflections (+DY)
        mmY     = [0; -cumsum(mmY + dY)]; DDXYZ = [DDX mmY(cY + 1)];
        % DDZ is kept zero, but for each cell:
        dDD     = [DDXYZ zeros(size(DDXYZ,1),1)] - [X Y Z];
        DD      = num2cell (dDD, 2)';
        if (nargout > 1)
            for ward = 1 : length (intrees),
                outtrees {ward} = tran_tree (intrees {ward}, DD {ward});
            end
        end
    case 0
        DD = [0 0 0];
        if (nargout > 1)
            outtrees = tran_tree (intrees);
        end
end

if strfind (options, '-s'),
    clf;
    switch level
        case 2
            for te = 1 : length (intrees)
                for ward = 1 : length (intrees {te}),
                    plot_tree (intrees{te}{ward}, [], DD{te}{ward});
                end
            end
        case 1
            clf;
            for ward = 1 : lent,
                plot_tree (intrees {ward}, [], DD{ward});
            end
        case 0
            plot_tree (intrees);
    end
    title  ('spread trees');
    xlabel ('x [\mum]'); ylabel ('y [\mum]'); zlabel ('z [\mum]');
    view (2); grid on; axis image;
end

