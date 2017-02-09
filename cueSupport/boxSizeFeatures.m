function [boxSize,boxWidth,boxHeight] = boxSizeFeatures(boxes,imSize)
%BOXSIZEFEATURES computes features used for the candidate size cue
%   inputs
%       boxes - a M x 4 matrix of M boxes in [x1 y1 x2 y2] format
%       imSize - area of the source image for the boxes
%   outputs
%       boxSize -  vector of length M containing the percent of the image 
%                  covered by a box
%       boxWidth - vector of length M containing the width of each input
%                  box
%       boxHeight - vector of length M containing the height of each input
%                   box
    boxWidth = boxes(:,3) - boxes(:,1);
    boxHeight = boxes(:,4) - boxes(:,2);
    boxSize = (boxWidth.*boxHeight)./imSize;
end

