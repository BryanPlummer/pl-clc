function overlaps = getIOU(box,boxes)
%GETIOU computes the intersection over union between the input boxes
%   inputs
%       box - single bounding box in the [x1 y1 x2 y2] format
%       boxes - M x 4 matrix of bounding boxes in the same format as the
%               box input
%   outputs
%       overlaps - array of length M with IOU overlap between the box and
%                  boxes input
    x1 = max(box(1),boxes(:,1));
    y1 = max(box(2),boxes(:,2)); 
    x2 = min(box(3),boxes(:,3)); 
    y2 = min(box(4),boxes(:,4));
    w = x2-x1+1;
    h = y2-y1+1;
    boxArea = (box(3)-box(1)+1)*(box(4)-box(2)+1);
    boxesArea = (boxes(:,3)-boxes(:,1)+1).*(boxes(:,4)-boxes(:,2)+1);
    intersectArea = w.*h;
    idx = (double(w > 0) + double(h > 0)) == 2;
    overlaps = zeros(size(boxes,1),1);
    overlaps(idx) = intersectArea(idx)./(boxesArea(idx) - intersectArea(idx) + boxArea);
end

