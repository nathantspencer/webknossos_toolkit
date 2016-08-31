% ROUNDSHOW a 3D round show of a plot.
% (scheme package)
%
% roundshow (pause)
% -----------------
%
% a 3D round show, simply changes the view in regular intervals.
%
% Input
% -----
% - pause::value: inverse speed {DEFAULT: no pause, fast == 0}
%
% Output
% ------
% none
%
% Example
% -------
% plot_tree (sample_tree); shine ('-p -a');
% roundshow;
%
% See also
% Uses
%
% the TREES toolbox: edit, visualize and analyze neuronal trees
% Copyright (C) 2009  Hermann Cuntz

function roundshow (speed)

if (nargin < 1)||isempty(speed),
    speed = 0; % {DEFAULT: very fast, no pause}
end

for ward = 0 : 5 : 360,
    view([ward-37.5 30]);
    axis vis3d
    if speed ~= 0,
        pause (speed);
    end
    drawnow;
end