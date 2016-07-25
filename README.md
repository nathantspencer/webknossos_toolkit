# **webknossos_toolkit**

You might know `.nml` files from your favorite online skeletonizing application: webKnossos. You might have pockets full of `.zip` files of raw image data from your tracings. On the other hand, you might not know what to do with them. Look no further! This toolkit contains several tools to manipulate and make use of `.nml` and `.zip` files from webKnossos.

## **table of contents**

#### [nml_tools](https://github.com/nathantspencer/webknossos_toolkit#nml_tools-1)
* [nml_merger](https://github.com/nathantspencer/webknossos_toolkit#nml_merger)
* [nml_splitter](https://github.com/nathantspencer/webknossos_toolkit#nml_splitter)
* [nml2swc](https://github.com/nathantspencer/webknossos_toolkit#nml2swc)
* [swc_corrector](https://github.com/nathantspencer/webknossos_toolkit#swc_corrector)
* [swc2obj](https://github.com/nathantspencer/webknossos_toolkit#swc2obj)
* [swc_segmenter](https://github.com/nathantspencer/webknossos_toolkit#swc_segmenter)

#### [zip_tools](https://github.com/nathantspencer/webknossos_toolkit#zip_tools-1)
* [zip_splitter](https://github.com/nathantspencer/webknossos_toolkit#zip_splitter)


## **nml_tools**


### *nml_merger*
The python script `nml_merger.py` takes multiple `.nml` files and merges them into one master file containing the skeleton data of all of its components. The resulting `.nml` can be uploaded to webKnossos and viewed as one skeleton. The script takes as arguments first the directory containing the files to be merged, and then the full path to the output file.

**EX:** `$ python nml_merger.py 'path\to\nml\directory' 'path\to\output.nml'`

Compatability with Knossos files is a known limitation of this script. As it stands, it is only capable of merging files from WebKnossos. The file format of Knossos files is slightly different and is not yet accounted for. Knossos files will be skipped and display a warning message, but will not terminate the merging process.

### *nml_splitter*
The python script `nml_splitter.py` takes one or more `.nml` files as arguments and splits them into multiple skeletons. Each `<thing>` in the file will become its own `.nml`, with branchpoints and comments preserved.  Output files will retain their original file name with a numbering appended, e.g. `output.nml` will become `output1.nml`, `output2.nml`, etc. A usage example is shown below.

**EX:** `$ python nml_splitter.py 'path\to\master.nml' 'path\to\another.nml'`


### *nml2swc*
The python script `nml2swc.py` can be used to convert all `.nml` files in a directory into `.swc` files with a given radius. The script takes two arguments: the full path to the directory containing your `.nml`s, and the integer radius you'd like to assign to each node of the resulting `.swc`s. A directory named `/SWCs` is added to the directory from which the script is called and is populated as the skeletons are converted.

**EX:** `$ python nml2swc.py 'path\to\nml\directory' 15`

The example above converts all `.nml` files contained in `path\to\nml\directory` to `.swc` files with radii of 15. 

### *swc_corrector*
The python script `swc_corrector.py` can be used to enforce proper ordering of an `.swc` file's vertices. For example, if you use `nml2swc.py` to create an `.swc` from a WebKnossos skeleton whose nodes are not ordered as consecutive natural numbers, the ordering of the resulting file will need to be standardized. This can be done by running placing the `.swc` files in need of correction in the `/swcs_to_correct` directory, and then running the script as shown below.

**EX:** `$ python swc_corrector.py`

The files will then be overwritten by their corrected versions and are ready to be viewed or passed through `swc_segmenter.py`.
### *swc2obj*
The python script `swc2obj.py` will convert a given `.swc` into a point cloud `.obj` file for viewing in MeshLab, Blender, and other similar tools. It takes as an argument the full path to the `.swc` file of interest, and places the resulting `.obj` file alongisde the input file in its parent directory. A usage example is given below.

**EX:** `$ python swc2obj.py 'path\to\swc\file.swc'`

Following the command given above, `file.obj` will be created in the same directory as the input file.
### *swc_segmenter*
This script is still under construction! Check back soon for details.

## **zip_tools**

### *zip_splitter*
The MATLAB script `zip_splitter.m` can be used to take a webKnossos `.zip` containing multiple cells and split it into multiple files corresponding to each cell. The `.zip` should be placed in `/zip_splitter`. The output files will be created in this directory as well. A usage example is shown below.

**EX:** `zip_splitter('multi_cells.zip')`

The output files will be named `multi_cells_part1.zip`, `multi_cells_part2.zip`, etc. The number at the end of the ouput file corresponds to the cell number used in webKnossos.

