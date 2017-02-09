function [caffe_net,fastrcnn_conf,max_rois_num_in_gpu] = fastRCNNInit(net,def,image_means)
%FASTRCNNINIT initializes a caffe network
%   inputs
%       net - file name including the path of the saved weights for
%             a network
%       def - file name including the path of the network definition
%       image_means - optional input with the mean image for a network
%   outputs
%       caffe_net - initialized caffe network
%       fastrcnn_conf - configuration information for a caffe network for
%                       use in the faster rcnn codebase
%       max_rois_num_in_gpu - number of boxes that can be fit into the
%                             gpu's memory
    if nargin < 3
        image_means = reshape([102.9801, 115.9465, 122.7717], [1 1 3]);
    end
    use_gpu = true;

    gpuInfo = gpuDevice();
    fastrcnn_conf = [];
    fastrcnn_conf.image_means = image_means;
    fastrcnn_conf.test_max_size = 1000;
    fastrcnn_conf.test_scales = 600;
    fastrcnn_conf.max_size = 1000;
    fastrcnn_conf.test_binary = false;

    caffe_net = caffe.Net(def, 'test');
    caffe_net.copy_from(net);
    if use_gpu
        caffe.set_mode_gpu();
    else
        caffe.set_mode_cpu();
    end

    max_rois_num_in_gpu = check_gpu_memory(fastrcnn_conf, caffe_net);
end

function max_rois_num = check_gpu_memory(fastrcnn_conf, caffe_net)
%%  try to determine the maximum number of rois

    max_rois_num = 0;
    for rois_num = 500:500:5000
        % generate pseudo testing data with max size
        im_blob = single(zeros(fastrcnn_conf.max_size, fastrcnn_conf.max_size, 3, ...
                               1));
        rois_blob = single(repmat([0; 0; 0; fastrcnn_conf.max_size-1; ...
                            fastrcnn_conf.max_size-1], 1, rois_num));
        rois_blob = permute(rois_blob, [3, 4, 1, 2]);

        net_inputs = {im_blob, rois_blob};

        % Reshape net's input blobs
        caffe_net.reshape_as_input(net_inputs);

        caffe_net.forward(net_inputs);
        gpuInfo = gpuDevice();

        max_rois_num = rois_num;

        if gpuInfo.FreeMemory < 2 * 10^9  % 2GB for safety
            break;
        end
    end

end

