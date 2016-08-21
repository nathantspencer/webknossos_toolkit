# **webknossos_toolkit**

You might know `.nml` files from your favorite online skeletonizing application: webKnossos. You might have pockets full of `.zip` files of raw image data from your tracings. On the other hand, you might not know what to do with them. Look no further! This toolkit contains several tools to manipulate and make use of `.nml` and `.zip` files directly from webKnossos, as well as file types like `.swc` that can be created from webKnossos files.

# **table of contents**

#### [nml_tools](https://github.com/nathantspencer/webknossos_toolkit#nml_tools-1)
* [nml_merger](https://github.com/nathantspencer/webknossos_toolkit#nml_merger)
* [nml_splitter](https://github.com/nathantspencer/webknossos_toolkit#nml_splitter)
* [nml2swc](https://github.com/nathantspencer/webknossos_toolkit#nml2swc)

### [swc_tools](https://github.com/nathantspencer/webknossos_toolkit#swc_tools-1)
* [swc_corrector](https://github.com/nathantspencer/webknossos_toolkit#swc_corrector)
* [swc2obj](https://github.com/nathantspencer/webknossos_toolkit#swc2obj)

#### [zip_tools](https://github.com/nathantspencer/webknossos_toolkit#zip_tools-1)
* [zip_splitter](https://github.com/nathantspencer/webknossos_toolkit#zip_splitter)


# **nml_tools**

### nml_merger
The python script `nml_merger.py` takes multiple `.nml` files and merges them into one master file containing the skeleton data of all of its components. The resulting `.nml` can be uploaded to webKnossos and viewed as one skeleton. The script takes as arguments first the directory containing the files to be merged, and then the full path to the output file.

**EX:** `$ python nml_merger.py 'path\to\nml\directory' 'path\to\output.nml'`

Compatability with Knossos files is a known limitation of this script. As it stands, it is only capable of merging files from WebKnossos. The file format of Knossos files is slightly different and is not yet accounted for. Knossos files will be skipped and display a warning message, but will not terminate the merging process.

### nml_splitter
The python script `nml_splitter.py` takes an `.nml` file or a directory containing `.nml` files as an argument and splits them into multiple skeletons. Each `<thing>` in the file will become its own `.nml`, with branchpoints and comments preserved.  Output files will retain their original file name with a numbering appended, e.g. `output.nml` will become `output_1.nml`, `output_2.nml`, etc. Usage examples are shown below.

**EX:** `$ python nml_splitter.py 'path\to\master.nml'`

**EX:** `$ python nml_splitter.py 'path\to\nml\directory'`


### nml2swc
The python script `nml2swc.py` can be used to convert all `.nml` files in a directory into `.swc` files with a given radius. The script takes one or two arguments: the full path to the file or directory containing your `.nml`s, and the optional integer radius you'd like to assign to each node of the resulting `.swc`s. If the second argument is left out, radii for each node of the skeleton will be taken from the input `.nml`. Usage examples are shown below.

**EX:** `$ python nml2swc.py 'path\to\nml\directory' 15`

**EX:** `$ python nml2swc.py 'path\to\nml\file.nml'`

Note that in the second usage example, the radius for each node will be taken from the `.nml` file given as the first argument because no second argument was given.

# **swc_tools**

### swc2hoc
The python script `swc2hoc.py` takes as an argument the path to an `.swc` file or a directory containing `.swc` files. A `.hoc` file will be created in the same directory as the `.swc` file. Note that this script requires MATLAB and the [MATLAB engine for python](http://www.mathworks.com/help/matlab/matlab-engine-for-python.html), which are used to make calls to functions in the [TREES Toolbox](http://www.treestoolbox.org/).

It is also worth noting that this script assumes the first branch in your `.swc` file to be the soma, with the following branches representing a dendrite. If this is not the case, simple edits to the script will be necessary to change the categories of sections. Usage examples are given below.

**EX:** `$ python swc2hoc.py 'path\to\swc\file.swc'`

**EX:** `$ python swc2hoc.py 'path\to\swc\directory'`

### swc2obj
The python script `swc2obj.py` will convert a given `.swc` into a point cloud `.obj` file for viewing in MeshLab, Blender, and other similar tools. It takes as an argument the full path to the `.swc` file of interest or to a directory containing `.swc` files, and places the resulting `.obj` file(s) alongisde the input file in its parent directory. Usage examples are given below.

**EX:** `$ python swc2obj.py 'path\to\swc\file.swc'`

**EX:** `$ python swc2obj.py 'path\to\swc\directory'`

Following the command given in the first example, `file.obj` will be created in the same directory as the input file. In the second example, `.obj`s will be created in `\directory`.

# **zip_tools**

### zip_splitter
The MATLAB script `zip_splitter.m` can be used to take a webKnossos `.zip` containing multiple cells and split it into multiple files corresponding to each cell. The `.zip` should be placed in `/zip_splitter`. The output files will be created in this directory as well. A usage example is shown below.

**EX:** `zip_splitter('multi_cells.zip')`

The output files will be named `multi_cells_part1.zip`, `multi_cells_part2.zip`, etc. The number at the end of the ouput file corresponds to the cell number used in webKnossos.

