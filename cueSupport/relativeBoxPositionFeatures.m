function features = relativeBoxPositionFeatures(box1,box2)
%RELATIVEBOXPOSITIONFEATURES returns the relative position of
%corresponding pairs of boxes
%   inputs
%       box1 - M x 4 matrix of boxes in the [x1, y1, x2, y2] format
%       box2 - M x 4 matrix of boxes in the [x1, y1, x2, y2] format
%   outputs
%       features - M x 4 matrix of the relative position of the
%                  corresponding boxes in the input boxes
    w1 = box1(:,3) - box1(:,1);
    h1 = box1(:,4) - box1(:,2);
    w2 = box2(:,3) - box2(:,1);
    h2 = box2(:,4) - box2(:,2);
    features = [(box1(:,1)-box2(:,1))./w1,(box1(:,2)-box2(:,2))./h1,w2./w1,h2./h1];
end

