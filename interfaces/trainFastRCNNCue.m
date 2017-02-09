function trainFastRCNNCue(imDataTrain,imDataVal,cue,netdir,cachedir,dbdir)
%TRAINFASTRCNNCUE trains a linear weighting of single phrase cues
%   inputs
%       imDataTrain - an ImageSetData object of the training data
%       imDataVal - an ImageSetData object of the validation data
%       cue - single phrase cue object to train a Fast RCNN
%             detector for
%       netdir - directory with the prototxt files defining the net
%                to train
%       cachedir - directory where the network weights are saved
%       dbdir - directory where the Fast RCNN files roidb and imdb
%               structs are stored
%   outputs
%
    dbfn = sprintf('%strain_db.mat',dbdir);
    [imdb_train,roidb_train] = getCueDataInFastRCNNFormat(imDataTrain,cue,dbfn);
    dbfn = sprintf('%sval_db.mat',dbdir);
    [imdb_val,roidb_val] = getCueDataInFastRCNNFormat(imDataVal,cue,dbfn);
    mean_image = fullfile(pwd,'external','faster_rcnn','models','pre_trained_models','vgg_16layers','mean_image.mat');
    if ~exist(mean_image,'file')
        fetch_model_VGG16;
    end
    fastrcnn_conf = fast_rcnn_config('image_means',mean_image);
    do_val = true;
    solver = fullfile(netdir,'solver.prototxt');
    net = fullfile(pwd,'external','faster_rcnn','models','pre_trained_models','vgg_16layers','vgg16.caffemodel');
    fast_rcnn_train(fastrcnn_conf, {imdb_train},{roidb_train}, ...
            'do_val',           do_val, ...
            'imdb_val',         imdb_val, ...
            'roidb_val',        roidb_val, ...
            'solver_def_file',  solver, ...
            'net_file',         net, ...
            'cache_name',       cachedir,...
            'val_iters',        50);
        
    caffe.reset_all();
end

