# Phrase Localization and Visual Relationship Detection with Comprehensive Image-Language Cues

**pl-clc** contains the implementation for our [paper](https://arxiv.org/abs/1611.06641) which has several implementation improvements over the initial arXiv submission.  If you find this code useful in your research, please consider citing:

    @inproceedings{plummerPLCLC2017,
        Author = {Bryan A. Plummer and Arun Mallya and Christopher M. Cervantes and Julia Hockenmaier and Svetlana Lazebnik},
        Title = {Phrase Localization and Visual Relationship Detection with Comprehensive Image-Language Cues},
        booktitle = {ICCV},
        Year = {2017}
    }


### Phrase Localization Evaluation Demo

This code was tested using Matlab R2016a on a system with Ubuntu 14.04.

1. Clone the pl-clc repository

    ```Shell
    git clone --recursive https://github.com/BryanPlummer/pl-clc.git
    ```

2. Follow installation requirements for external code which includes:

    1. [Faster RCNN](https://github.com/ShaoqingRen/faster_rcnn)
    2. [Edge Boxes](https://github.com/pdollar/edges)
    3. [LIBSVM](https://github.com/cjlin1/libsvm)
    4. [HGLMM Fisher Vectors](https://owncloud.cs.tau.ac.il/index.php/s/vb7ys8Xe8J8s8vo)

   On the system this code was tested on only Caffe (in Faster RCNN) and LIBSVM required any compiling to use the evaluation script.

3. Optional, download the [Stanford Parser](http://nlp.stanford.edu/software/lex-parser.shtml), putting the code in the `external` folder naming it `stanford-parser`.  Note that the version of the Stanford Parser used for the precomputed data was 3.4.1.

4. Download the precomputed data (8.3G): [pl-clc models](https://drive.google.com/file/d/0B_PL6p-5reUAcDBiTTV5WUNyYUE/view?usp=sharing)

5. Get the [Flickr30k Entities dataset](http://web.engr.illinois.edu/~bplumme2/Flickr30kEntities/) and put it in the `datasets` folder.  The code also assumes the images have been placed in `datasets/Flickr30kEntities/Images`.

6. After unpacking the precomputed data you can run our evaluation code

    ```Shell
    >> evalAllCuesFlickr30K
    ```

    This step took about 45 minutes using a single Tesla K40 GPU on a system with an Intel(R) Xeon(R) CPU E5-2687W v2 processor.

### Training new models

There are example scripts that was used to create all the precomputed data in the `trainScripts` folder.  Training these models from scratch requires about 100G of memory.  This can be reduced by simply removing some parfor loops, but training the CCA model requires about 70G memory by itself.


