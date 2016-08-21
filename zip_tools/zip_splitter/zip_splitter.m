function zip_splitter(zip_file)
%% zip_splitter(): cell separation tool for volumetric WebKnossos data
%
%   Pass the name of the zip file containing the cell data as an argument
%   to the cellsplitter. Cellsplitter will create multiple zips from this
%   data: precisely one for each cell contained in the original zip. 
%
%   EX: zip_splitter('zip_for_many_cells.zip')
%
%   Created June 2016 by Nathan Spencer
%
%--------------------------------------------------------------------------

%% Setup and declarations

zip_file_name = zip_file(1:length(zip_file)-4);
unzip(zip_file);
raws = glob('*.raw');

x_pattern = '[a-zA-z_0-9]+mag1_x([0-9]+)_y[0-9]+_z[0-9]+.raw';
y_pattern = '[a-zA-z_0-9]+mag1_x[0-9]+_y([0-9]+)_z[0-9]+.raw';
z_pattern = '[a-zA-z_0-9]+mag1_x[0-9]+_y[0-9]+_z([0-9]+).raw';

x = zeros(numel(raws),1);
y = zeros(numel(raws),1);
z = zeros(numel(raws),1);

cube = cell(numel(raws),1);
temp_cube = cell(numel(raws),1);
cube_size = [128 128 128];
max_cell_in_cube = zeros(numel(raws),1);

%--------------------------------------------------------------------------
%% Read raw files from zip into cubes

for i=1:numel(raws)
    
    s = regexp(raws(i), x_pattern, 'tokens');
    x(i,1) = str2double(s{1}{1});
    s = regexp(raws(i), y_pattern, 'tokens');
    y(i,1) = str2double(s{1}{1});
    s = regexp(raws(i), z_pattern, 'tokens');
    z(i,1) = str2double(s{1}{1});
    
    fid = fopen(raws{i});
    cube{i}{1} = fread(fid, 'uint16=>uint16');
    cube{i}{1} = reshape(cube{i}{1}, cube_size);
    fclose(fid);
    max_cell_in_cube(i,1) = max(max(max(cube{i}{1})));
    
end

number_of_cells = max(max_cell_in_cube);

for i=1:numel(raws)
    delete(raws{i});
end

%--------------------------------------------------------------------------
%% Write raw files for each cell and zip separately

for j=1:number_of_cells
    for i=1:numel(raws)
        voxel_ind = find(cube{i}{1} == j);
        voxel_sub = cell(length(voxel_ind),1);
        temp_cube{i}{1} = zeros(128, 128, 128);
        for k=1:length(voxel_ind)
           [a, b, c] = ind2sub(cube_size, voxel_ind(k,1));
           voxel_sub{k} = [a b c];
           temp_cube{i}{1}(voxel_sub{k}(1), voxel_sub{k}(2), ...
               voxel_sub{k}(3)) = 1;
        end
        if (~isempty(voxel_sub))
           fid = fopen(raws{i}, 'w');
           fwrite(fid, temp_cube{i}{1}, 'uint16');
           fclose(fid);
        end
    end
    current_raws = glob('*.raw');
    if(~isempty(current_raws))
        zip(strcat(zip_file_name, '_part1', int2str(j)), current_raws')
    end
    for k=1:length(current_raws)
       delete(current_raws{k});
    end
end

%--------------------------------------------------------------------------
