% RAD2DEG   Transposes from radians to degrees.
% (scheme package)
%
% result = rad2deg (x)
% --------------------
%
% simple equation: result = mod ((x / (2 * pi)) * 360, 360)
%
% Input
% -----
% - x ::vector: vector of values in radian
%
% Output
% ------
% - result ::vector: vector of values in degrees
%
% Example
% -------
% rad2deg (pi)
%
% See also deg2rad
% Uses
%
% the TREES toolbox: edit, visualize and analyze neuronal trees
% Copyright (C) 2009  Hermann Cuntz

function result = rad2deg (x)

result = mod ((x / (2 * pi)) * 360, 360);