% addpath to your matcaffe mex file
% addpath(...);

% enable/disable using the gpu
use_gpu = true;

model_def_file = 'VGG_ILSVRC_19_layers_deploy.feature_extarct.prototxt';

% this file is not included in this package (too large) so you have to
% download it
model_file = 'VGG_ILSVRC_19_layers.caffemodel';

matcaffe_init(use_gpu, model_def_file, model_file);
