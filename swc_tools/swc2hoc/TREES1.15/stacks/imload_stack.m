% IMLOAD_STACK   load image into a 3D matrix.
% (trees package)
%
% [stack name path] = imload_stack (name, options)
% ------------------------------------------------
%
% loads image from file. As in "save_stack" the data stack is in the
% following form:
% stack.M::cell-array of 3D-matrices: n tiled image stacks containing
%    fluorescent image
% stack.sM::cell-array of string, 1xn: names of individual stacks
% stack.coord::matrix nx3: x,y,z coordinates of starting points of each
%    stack
% stack.voxel::vector 1x3: xyz size of a voxel
%
% Input
% -----
% - name::string: name of file including the extension
%     {DEFAULT : open gui fileselect} spaces and other weird symbols not
%     allowed!
% - options::string: {DEFAULT: ''}
%     '-s' : show
%   
% Output
% ------
% - stack::struct: image stacks in structure form (see above)
% - name::string: name of output file; [] no file was selected -> no output
% - path::sting: path of the file, complete string is therefore: [path name]
%
% Example
% -------
% stack = imload_stack ([],'-s')
%
% See also load_stack loaddir_stack loadtifs_stack save_stack show_stack
% Uses
%
% the TREES toolbox: edit, visualize and analyze neuronal trees
% Copyright (C) 2009  Hermann Cuntz

function [stack tname path] = imload_stack (tname, options)

if (nargin<1)||isempty(tname),
    [tname path] = uigetfile ({'*.jpg;*.tif;*.bmp','any image type'}, ...
        'Pick a file', 'multiselect', 'off');
    if tname  == 0,
        stack = [];
        return
    end
else
    path = '';
end
% extract a sensible name from the filename string:
nstart = unique ([0 strfind(tname, '/') strfind(tname, '\')]);
name   = tname  (nstart (end) + 1 : end - 4);
if nstart (end) > 0,
    path = [path tname(1 : nstart (end))];
    tname (1 : nstart (end)) = '';
end

if (nargin<2)||isempty(options),
    options = ''; % {DEFAULT: no option}
end

stack.M = {}; stack.sM = {};
stack.sM{1} = name;
stack.coord = [0 0 0]; stack.voxel = [1 1 1];
stack.M{1}  = imread ([path tname]);

if strfind (options, '-s'), % show option
    clf; hold on; show_stack (stack);
    xlabel ('x [\mum]'); ylabel ('y [\mum]'); zlabel ('z [\mum]');
    view (3); grid on; axis image;
end