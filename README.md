# Phrase Localization and Visual Relationship Detection with Comprehensive Linguistic Cues

**pl-clc** contains the implementation for our paper which has several implementation improvements over the initial arXiv version of the paper.  If you find this code useful in your research, please consider citing:

    @article{plummerPLCLC2016,
        Author = {Bryan A. Plummer and Arun Mallya and Christopher M. Cervantes and Julia Hockenmaier and Svetlana Lazebnik},
        Title = {Phrase Localization and Visual Relationship Detection with Comprehensive Linguistic Cues},
        Journal = {arXiv:1611.06641},
        Year = {2016}
    }


### Phrase Localization Evaluation Demo

This code was tested using Matlab R2016a on a system with Ubuntu 14.04.

1. Clone the pl-clc repository

    ```Shell
    git clone --recursive https://github.com/BryanPlummer/pl-clc.git
    ```

2. Follow installation requirements for external code which includes:

    A. [Faster RCNN](https://github.com/ShaoqingRen/faster_rcnn)
    B. [Edge Boxes](https://github.com/pdollar/edges)
    C. [LIBSVM](https://github.com/cjlin1/libsvm)
    D. [HGLMM Fisher Vectors](https://owncloud.cs.tau.ac.il/index.php/s/vb7ys8Xe8J8s8vo)
    E. [Stanford Parser](http://nlp.stanford.edu/software/lex-parser.shtml)

  Note that the version of the Stanford Parser in this repo is 3.4.1.  On the system this code was tested on only caffe (in Faster RCNN) and LIBSVM required any compiling to use the evaluation script.

3. Download the precomputed data (8.3G): [pl-clc models](https://drive.google.com/file/d/0B_PL6p-5reUAcDBiTTV5WUNyYUE/view?usp=sharing)

4. Get the [Flickr30k Entities dataset](http://web.engr.illinois.edu/~bplumme2/Flickr30kEntities/) and put it in the `datasets` folder.  The code also assumes the images have been placed in `datasets/Flickr30kEntities/Images`.

5. After unpacking the precomputed data you can run our evaluation code

    ```Shell
    >> evalAllCuesFlickr30K
    ```

    This step took about 45 minutes using a single Tesla K40 GPU on a system with an Intel(R) Xeon(R) CPU E5-2687W v2 processor.

### Training new models

There are example scripts that was used to create all the precomputed data in the `trainScripts` folder.  Training these models from scratch requires about 100G of RAM.  This can be reduced by simply removing some parfor loops, but training the CCA model requires about 70G RAM by itself.


