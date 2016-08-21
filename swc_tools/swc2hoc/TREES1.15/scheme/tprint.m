% TPRINT   Simplified printing.
% (scheme package)
%
% [name path] = tprint (name, options, fsize, options)
% ----------------------------------------------------
%
% prints the current figure to a file.
%
% Input
% -----
% - name::string: name of the output-file without extension
%     {DEFAULT : open gui fileselect} spaces and other weird symbols not
%     allowed!
% - options::string: {DEFAULT '-R -jpg'}
%    '-SHR'  1200 dpi
%    '-HR'   600  dpi
%    '-R'    300  dpi 
%    '-LR'   150  dpi
%    '-jpg'  as jpg
%    '-tif'  as tif
%    '-eps'  as eps  (more than one output format is possible!)
% - fsize::2-tupel: fixed size in cm [horiz. x vertical] {DEFAULT 15cm x 10cm}
% - options::string: {DEFAULT: ''} , see shine
%    '-a'  : axis invisible
%    '-f'  : full axis
%    '-s'  : scalebar in um
%    '-p'  : camlight and lighting gouraud
%    '-3d' : 3D view
%
% Output
% ------
% - name::string: name of output file; [] no file was selected -> no output
% - path::sting: path of the file, complete string is therefore: [path name]
%
% Example
% -------
% plot_tree (sample_tree); tprint;
%
% See also
% Uses shine
%
% the TREES toolbox: edit, visualize and analyze neuronal trees
% Copyright (C) 2009  Hermann Cuntz

function [tname tpath] = tprint (tname, options, fsize, shineoptions)

if (nargin < 1)||isempty(tname),
     [tname, tpath] = uiputfile ('.*','print figure content','fig');
     if tname == 0,
        tname = [];
        return
     end
else
    tpath = '';
end
nstart = unique ([0 strfind(tname, '/') strfind(tname, '\')]);
if nstart (end) > 0,
    tpath = [tpath tname(1 : nstart (end))];
    tname(1 : nstart (end)) = '';
end

if (nargin<2)||isempty(options),
    options = '-R -jpg';
end

if (nargin<3)||isempty(fsize),
    fsize = [15 10];
end

if (nargin<4)||isempty(shineoptions),
    shineoptions = 'none';
end

if     strfind (options, '-HR'),
    res = 600;
elseif strfind (options, '-SHR'),
    res = 1200;
elseif strfind (options, '-LR'),
    res = 150;
else
    res = 300;
end

set (gcf, 'units', 'centimeters', 'PaperUnits', 'centimeters', ...
    'papersize', fsize, 'PaperPosition', [0 0 fsize]);

if ~strcmp (shineoptions, 'none'),
    shine (shineoptions);
end

if strfind (options, '-jpg'),
    print ('-djpeg', ['-r' num2str(res)], [tpath tname '.jpg']);
end
if strfind(options,'-tif'),
    print ('-dtiff', ['-r' num2str(res)], [tpath tname '.tif']);
end
if strfind(options,'-eps'),
    print ('-depsc2', [tpath tname '.eps']);
end
