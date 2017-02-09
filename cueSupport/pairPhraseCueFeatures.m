function features = pairPhraseCueFeatures(imData,relationship,spcScores,imIdx,sentIdx,gtLeft,gtRight)
%PAIRPHRASECUEFEATURES computes relative box position features
%   inputs
%       imData - an ImageSetData object
%       relationship - a Relationship object to compute features for
%       spcScores - single phrase cue scores for all phrases in the
%                   sentence
%       imIdx - the index of the image to compute features for
%       sentIdx - the index of the sentence the relationship is from
%       gtLeft - ground truth boxing box for the left phrase of a
%                relationship
%       gtRight - ground truth boxing box for the right phrase of a
%                 relationship
%   outputs
%       features - M*N x 6 dimensional feature vector for all
%                  pairs of boxes, where M is the number of boxes
%                  for the left phrase and N is the number of boxes
%                  for the right phrase
    bb = imData.getBoxes(imIdx);
    boxesLeft = bb(spcScores{imIdx}{sentIdx}(relationship.leftPhrase).boxIdx,:);
    boxesRight = bb(spcScores{imIdx}{sentIdx}(relationship.rightPhrase).boxIdx,:);
    [X,Y] = meshgrid(1:size(boxesLeft,1),1:size(boxesRight,1));
    X = X(:);
    Y = Y(:);
    features = relativeBoxPositionFeatures(boxesLeft(X,:),boxesRight(Y,:));
    scoresLeft = spcScores{imIdx}{sentIdx}(relationship.leftPhrase).scores(X);
    scoresRight = spcScores{imIdx}{sentIdx}(relationship.rightPhrase).scores(Y);
    features = [features,scoresLeft,scoresRight];
    if nargin > 6
        overlapLeft = getIOU(gtLeft,boxesLeft);
        overlapRight = getIOU(gtRight,boxesRight);
        overlap = min(overlapLeft(X),overlapRight(Y));
        features = [features,overlap];
    end
end

