# nml_toolkit
You might know `.nml` files from your favorite online skeletonizing application: WebKnossos. On the other hand, you might not know what to do with them. Look no further! This toolkit contains several tools to manipulate and make use of `.nml` files from WebKnossos.
## nml2swc
The python script `nml2swc.py` can be used to convert all `.nml` files in a directory into `.swc` files with a given radius. The script takes two arguments: the full path to the directory containing your `.nml`s, and the integer radius you'd like to assign to each node of the resulting `.swc`s. A directory named `/SWCs` is added to the directory from which the script is called and is populated as the skeletons are converted.

**EX:** `$ python nml2swc.py 'path\to\nml\directory' 15`

The example above converts all `.nml` files contained in `path\to\nml\directory` to `.swc` files with radii of 15. 

## swc_corrector
The python script `swc_corrector.py` can be used to enforce proper ordering of an `.swc` file's vertices. For example, if you use `nml2swc.py` to create an `.swc` from a WebKnossos skeleton whose nodes are not ordered as consecutive natural numbers, the ordering of the resulting file will need to be standardized. This can be done by running placing the `.swc` files in need of correction in the `/swcs_to_correct` directory, and then running the script as shown below.

**EX:** `$ python swc_corrector.py`

The files will then be overwritten by their corrected versions and are ready to be viewed or passed through `swc_segmenter.py`.


### swc_segmenter
This script is still under construction! Check back soon for details.

