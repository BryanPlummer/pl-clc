function boxPosition = boxPositionFeatures(boxes,imDims)
%BOXPOSITIONFEATURES computes features used for the candidate position cue
%   inputs
%       boxes - a M x 4 matrix of M boxes in [x1 y1 x2 y2] format
%       imDims - 2 dimensional array of the source image's [height,width]
%   outputs
%       boxPosition - M x 4 matrix containing the position consisting
%                     of the centroid, size, and aspect ratio of a box
    [boxSize,boxWidth,boxHeight] = boxSizeFeatures(boxes,imDims(1)*imDims(2));
    AR = boxWidth./boxHeight;
    xCenter = boxes(:,1) + boxWidth/2;
    yCenter = boxes(:,2) + boxHeight/2;
    imHalfWidth = imDims(2)/2;
    imHalfHeight = imDims(1)/2;
    xOffCenter = (imHalfWidth - xCenter)./imHalfWidth;
    yOffCenter = (imHalfHeight - yCenter)./imHalfHeight;
    boxPosition = [xOffCenter,yOffCenter,boxSize,AR];
end

