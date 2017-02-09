function conf = plClcConfig(varargin)
%PLCLCCONFIG settings used to run the current project
    ip = inputParser;
    % logical indicating if gpus should be used for the neural networks
    ip.addParamValue('use_gpu',gpuDeviceCount > 0,@islogical);
    
    % directory where the category information for the different cues are
    % being stored
    ip.addParamValue('dictionarydir','dictionaries',@ischar);
    
    % directory where the Flickr30k Entities dataset is located
    ip.addParamValue('datadir',fullfile('datasets','Flickr30kEntities'),@ischar);
    
    % file extension used by the images in the dataset
    ip.addParamValue('imExt','jpg',@ischar);
    
    % location of the cached models used by the different cues
    ip.addParamValue('modeldir','models',@ischar);
    
    % number of parallel threads to use when parsing sentences
    ip.addParamValue('nParseThreads',feature('numCores'),@isscalar);
    
    % file to store the training set's data
    ip.addParamValue('trainData',fullfile('data','flickr30k','trainData.mat'),@ischar);
    
    % file to store the testing set's data
    ip.addParamValue('testData',fullfile('data','flickr30k','testData.mat'),@ischar);
    
    % file to store the validation set's data
    ip.addParamValue('valData',fullfile('data','flickr30k','valData.mat'),@ischar);
    
    % directory used to cache individual cue scores
    ip.addParamValue('cachedir',fullfile('output','flickr30k'),@ischar);
    
    % logical indicating if cue scores should be cached to cachedir
    ip.addParamValue('cacheCueScores',true,@islogical); 
    
    % file with pronoun coreference information
    ip.addParamValue('pronounFile',fullfile('data','flickr30k','pronomCoref_v1.csv'),@ischar);
    
    % maximum number of Edge Boxes to compute per image
    ip.addParamValue('nEdgeBoxes',200,@isscalar);
    
    % maximum number of candidates kept per phrase after considering all
    % single phrase cues
    ip.addParamValue('maxNumInstances',30,@isscalar);
    
    % non-maximum suppression IOU threshold used on the single phrase cues
    % used in this run
    ip.addParamValue('nmsThresh',0.8,@isfloat);
    
    % threshold used to identify if a candidate is a positive example
    ip.addParamValue('posThresh',0.5,@isfloat);
    
    % maximum number of region examples per phrase used to train a CCA
    % model
    ip.addParamValue('ccaMaxSamplesPerPhrase',10,@isscalar);
    
    % regularization parameter used to train a CCA model
    ip.addParamValue('ccaETA',0.0001,@isfloat);
    
    % CNN model weights used to compute image features for the CCA model
    ip.addParamValue('featModel',fullfile('models','voc_2007_trainvaltest_2012_trainval','vgg16_fast_rcnn_iter_100000.caffemodel'),@ischar);

    % CNN definition used to compute image features for the CCA model
    ip.addParamValue('featDef',fullfile('models','fastrcnn_feat.prototxt'),@ischar);
    
    % file with the weights variable used to mix the single phrase cues
    ip.addParamValue('spcWeights',fullfile('models','learnedWeights','detCCASizeAdjSubObjPosSingleWeightsDefault.mat'),@ischar);

    % file with the weights varaible used to mix the pair phrase cues
    ip.addParamValue('ppcWeights',fullfile('models','learnedWeights','verbPrepClbpPairWeightsDefault.mat'),@ischar);

     % number of iterations used when learning weights for cues
    ip.addParamValue('nLearningIterations',20,@isscalar);
    
    ip.parse(varargin{:});
    conf = ip.Results;

    % phrase types used in the Flickr30k Entities dataset
    conf.phraseTypes = {'people';'clothing';'bodyparts';'animals';'vehicles';...
                        'instruments';'scene';'other';'notvisual'};
end

