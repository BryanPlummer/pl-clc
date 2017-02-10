function imageFeats = getFastRCNNFeatures(imData,net,def)
%GETFASTRCNNFEATURES
%   inputs
%       imData - an ImageSetData object or a containers.map object with
%                bounding box data
%       net - file name including the path of the saved weights for
%             a network
%       def - file name including the path of the network definition
%   outputs
%       imageFeats - cell array of features for each image in imageInfo
    [caffe_net,fastrcnn_conf,max_rois_num_in_gpu] = fastRCNNInit(net,def);
    if isa(imageBoxMap,'containers.Map')
        imageKeys = imageBoxMap.keys();
        imageFeats = cell(length(imageKeys),1);
        for i = 1:length(imageKeys)
            if mod(i,100) == 0
                fprintf('getFastRCNNFeatures: %i of %i processed\n',i,length(imageKeys));
            end

            boxes = single(imageBoxMap(imageKeys{i}));
            im = imData.readImage(find(strcmp(imageKeys{i},imData.imagefns),1));
            imageFeats{i} = fast_rcnn_im_features(fastrcnn_conf,caffe_net,im,boxes,max_rois_num_in_gpu);
        end
    else
        imageFeats = cell(imData.nImages,1);
        for i = 1:imData.nImages
            if mod(i,100) == 0
                fprintf('getFastRCNNFeatures: %i of %i processed\n',i,imData.nImages);
            end
            boxes = imData.getBoxes(i);
            boxes = single(boxes(:,1:4));
            im = imData.readImage(i);
            imageFeats{i} = fast_rcnn_im_features(fastrcnn_conf,caffe_net,im,boxes,max_rois_num_in_gpu);
        end    
    end
    
    caffe.reset_all();
end

function scores = fast_rcnn_im_features(fastrcnn_conf, caffe_net, im, boxes, max_rois_num_in_gpu)
% [pred_boxes, scores] = fast_rcnn_im_detect(conf, caffe_net, im, boxes, max_rois_num_in_gpu)
% --------------------------------------------------------
% Fast R-CNN
% Reimplementation based on Python Fast R-CNN (https://github.com/rbgirshick/fast-rcnn)
% Copyright (c) 2015, Shaoqing Ren
% Licensed under The MIT License [see LICENSE for details]
% --------------------------------------------------------

    [im_blob, rois_blob, ~] = get_blobs(fastrcnn_conf, im, boxes);
    
    % When mapping from image ROIs to feature map ROIs, there's some aliasing
    % (some distinct image ROIs get mapped to the same feature ROI).
    % Here, we identify duplicate feature ROIs, so we only compute features
    % on the unique subset.
    [~, index, inv_index] = unique(rois_blob, 'rows');
    rois_blob = rois_blob(index, :);
    boxes = boxes(index, :);
    
    % permute data into caffe c++ memory, thus [num, channels, height, width]
    im_blob = im_blob(:, :, [3, 2, 1], :); % from rgb to brg
    im_blob = permute(im_blob, [2, 1, 3, 4]);
    im_blob = single(im_blob);
    rois_blob = rois_blob - 1; % to c's index (start from 0)
    rois_blob = permute(rois_blob, [3, 4, 2, 1]);
    rois_blob = single(rois_blob);
    
    total_rois = size(rois_blob, 4);
    total_scores = cell(ceil(total_rois / max_rois_num_in_gpu), 1);
    for i = 1:ceil(total_rois / max_rois_num_in_gpu)
        
        sub_ind_start = 1 + (i-1) * max_rois_num_in_gpu;
        sub_ind_end = min(total_rois, i * max_rois_num_in_gpu);
        sub_rois_blob = rois_blob(:, :, :, sub_ind_start:sub_ind_end);
        
        net_inputs = {im_blob, sub_rois_blob};

        % Reshape net's input blobs
        caffe_net.reshape_as_input(net_inputs);
        output_blobs = caffe_net.forward(net_inputs);

        scores = output_blobs{1};
        scores = squeeze(scores);
        
        total_scores{i} = scores;
    end 
    
    scores = cell2mat(total_scores);

    % Map scores and predictions back to the original set of boxes
    scores = scores(:,inv_index);
end

function [data_blob, rois_blob, im_scale_factors] = get_blobs(fastrcnn_conf, im, rois)
    [data_blob, im_scale_factors] = get_image_blob(fastrcnn_conf, im);
    rois_blob = get_rois_blob(fastrcnn_conf, rois, im_scale_factors);
end

function [blob, im_scales] = get_image_blob(fastrcnn_conf, im)
    [ims, im_scales] = arrayfun(@(x) prep_im_for_blob(im, fastrcnn_conf.image_means, x, fastrcnn_conf.test_max_size), fastrcnn_conf.test_scales, 'UniformOutput', false);
    im_scales = cell2mat(im_scales);
    blob = im_list_to_blob(ims);    
end

function [rois_blob] = get_rois_blob(conf, im_rois, im_scale_factors)
    [feat_rois, levels] = map_im_rois_to_feat_rois(conf, im_rois, im_scale_factors);
    rois_blob = single([levels, feat_rois]);
end

function [feat_rois, levels] = map_im_rois_to_feat_rois(fastrcnn_conf, im_rois, scales)
    im_rois = single(im_rois);
    
    if length(scales) > 1
        widths = im_rois(:, 3) - im_rois(:, 1) + 1;
        heights = im_rois(:, 4) - im_rois(:, 2) + 1;
        
        areas = widths .* heights;
        scaled_areas = bsxfun(@times, areas(:), scales(:)'.^2);
        [~, levels] = min(abs(scaled_areas - 224.^2), [], 2); 
    else
        levels = ones(size(im_rois, 1), 1);
    end
    
    feat_rois = round(bsxfun(@times, im_rois-1, scales(levels))) + 1;
end

function boxes = clip_boxes(boxes, im_width, im_height)
    % x1 >= 1 & <= im_width
    boxes(:, 1:4:end) = max(min(boxes(:, 1:4:end), im_width), 1);
    % y1 >= 1 & <= im_height
    boxes(:, 2:4:end) = max(min(boxes(:, 2:4:end), im_height), 1);
    % x2 >= 1 & <= im_width
    boxes(:, 3:4:end) = max(min(boxes(:, 3:4:end), im_width), 1);
    % y2 >= 1 & <= im_height
    boxes(:, 4:4:end) = max(min(boxes(:, 4:4:end), im_height), 1);
end

