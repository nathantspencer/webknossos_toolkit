% GAUSS   Gauss function output.
% (scheme package)
%
% y = gauss (x, mu, sigma)
% ------------------------
%
% simple equation:
% y = (1 / (sigma * (sqrt (2 * pi)))) * ...
%               exp (-((x - mu).^2) ./ (2 * sigma * sigma))
%
% Input
% -----
% - x ::vector: x values
% - mu ::value: center of gauss curve
% - sigma ::value: variance of gauss curve
%
% Output
% ------
% - y ::vector: y values corresponding to x, what should I say...
%
% Example
% -------
% x = -10:.1:20; plot (x, gauss (x, 5, 5), 'k-')
%
% See also
% Uses
%
% the TREES toolbox: edit, visualize and analyze neuronal trees
% Copyright (C) 2009  Hermann Cuntz

function y = gauss (x, mu, sigma)

y = (1 / (sigma * (sqrt (2 * pi)))) * ...
    exp (-((x - mu).^2) ./ (2 * sigma * sigma));