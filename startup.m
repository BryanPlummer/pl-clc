function startup()
% startup()
% modified version of external/faster_rcnn startup.m

    curdir = fileparts(mfilename('fullpath'));

    addpath(fullfile(curdir, 'external', 'hglmm_fv','fv'));
    addpath(fullfile(curdir, 'external', 'hglmm_fv','utilities'));
    addpath(fullfile(curdir, 'external', 'hglmm_fv','FastICA_25'));
    if ispc
        addpath(fullfile(curdir, 'external', 'hglmm_fv','fv', 'HGLMM_win'));
        addpath(fullfile(curdir, 'external', 'hglmm_fv','fv', 'LMM_win'));
    else
        addpath(fullfile(curdir, 'external', 'hglmm_fv','fv', 'HGLMM_linux'));
        addpath(fullfile(curdir, 'external', 'hglmm_fv','fv', 'LMM_linux'));
    end

    addpath(genpath(fullfile(curdir, 'external', 'hglmm_fv', 'cca')));
    run(fullfile(curdir,'external','hglmm_fv','vlfeat-0.9.18','toolbox','vl_setup'));

    % Force matlab to load the mex file to get around TLS loading bug.
    % May only work when matlab's GUI isn't loaded on startup.
    try
        encoding = HybridFV(0, 0, 0, 0, 0, 0, 0, 0);
    catch ME
        if strcmp(ME.identifier,'MATLAB:invalidMEXFile')
            warning(['Error loading fisher vector code.  Try loading matlab'...
                     ' without the GUI if you want to use the CCA model.']);
        else
            rethrow(ME);
        end
    end
    addpath(genpath(fullfile(curdir, 'datasets', 'Flickr30kEntities')));
    addpath(genpath(fullfile(curdir, 'parsing')));
    addpath(genpath(fullfile(curdir, 'unaryCues')));
    addpath(genpath(fullfile(curdir, 'pairwiseCues')));
    addpath(genpath(fullfile(curdir, 'imdb')));
    addpath(genpath(fullfile(curdir, 'cueSupport')));
    addpath(genpath(fullfile(curdir, 'interfaces')));
    addpath(genpath(fullfile(curdir, 'utilities')));
    addpath(genpath(fullfile(curdir, 'trainScripts')));
    addpath(fullfile(curdir, 'external'));
    addpath(genpath(fullfile(curdir, 'external', 'faster_rcnn', 'utils')));
    addpath(genpath(fullfile(curdir, 'external', 'faster_rcnn', 'functions')));
    addpath(genpath(fullfile(curdir, 'external', 'faster_rcnn', 'bin')));
    addpath(genpath(fullfile(curdir, 'external', 'faster_rcnn', 'experiments')));
    addpath(genpath(fullfile(curdir, 'external', 'faster_rcnn', 'imdb')));
    addpath(genpath(fullfile(curdir, 'external', 'faster_rcnn', 'fetch_data')));
    addpath(genpath(fullfile(curdir, 'external', 'libsvm', 'matlab')));
    addpath(genpath(fullfile(curdir, 'external', 'edges')));
    addpath(genpath(fullfile(curdir, 'external', 'toolbox')));

    mkdir_if_missing(fullfile(curdir, 'external', 'faster_rcnn', 'datasets'));
    mkdir_if_missing(fullfile(curdir, 'external', 'faster_rcnn', 'external'));

    caffe_path = fullfile(curdir, 'external', 'faster_rcnn', 'external', 'caffe', 'matlab');
    if exist(caffe_path, 'dir') == 0
        error('matcaffe is missing from external/caffe/matlab; See faster_rcnn README.md');
    end
    addpath(genpath(caffe_path));

    mkdir_if_missing(fullfile(curdir, 'imdb', 'cache'));

    mkdir_if_missing(fullfile(curdir, 'output'));

    mkdir_if_missing(fullfile(curdir, 'models'));
    mkdir_if_missing(fullfile(curdir, 'data'));
    mkdir_if_missing(fullfile(curdir, 'datasets'));

    fprintf('pl-clc startup done\n');
end
