function vec = vgg_image_file_to_features(image_file_name)

    try
        im = imread(image_file_name);
    catch err
        fprintf('ERROR reading %s: %s\n', image_file_name, err.message);
        vec = [];
        return;
    end

    % this is a workaround for grayscale images (input for the vgg network
    % must be a rgb image)
    if size(im,3) < 3

        fprintf('handling gray image: %s\n', image_file_name);

        new_im = zeros(size(im,1) , size(im,2) , 3);

        % duplicate to "rgb"
        for j = 1:3
            new_im(:,:,j) = im(:,:,1);
        end

        im = new_im;
    end

    vec = vgg_feature_extract(im);
    
end
