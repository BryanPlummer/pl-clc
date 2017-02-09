function [weights,trainLossValue] = trainCueWeights(conf,imData,boxes,scores)
%TRAINCUEWEIGHTS trains a linear weighting of single phrase cues
%   inputs
%       conf - configuration settings (e.g. output of plClcConfig)
%       imData - an ImageSetData object
%       boxes{i}{j}{k} - K x 4 matrix of boxes in the [x1, y1, x2, y2] 
%                        for image i, sentence j, at phrase k
%       scores - M x N cell array where scores{i,j} has the scores
%                for image i and cue j 
%   outputs
%       weights - learned linear weighting of the N cues
%       trainLossValue - value of the training loss function
    scores = imData.scoreMatrix2Features(scores,boxes);
    scores = vertcat(scores{:});
    scores = vertcat(scores{:});
    
    labels = imData.isBoxPositive(conf,boxes);
    labels = vertcat(labels{:});
    labels = vertcat(labels{:});
    
    noBox = cellfun(@isempty,labels);
    labels(noBox) = [];
    scores(noBox) = [];
    
    nFeatures = size(scores{1},2);
    x = zeros(nFeatures,conf.nLearningIterations);
    fval = zeros(conf.nLearningIterations,1);
    parfor i = 1:conf.nLearningIterations
        x0 = rand(nFeatures,1);
        [x(:,i),fval(i)] = fminsearch(@(f)accuracyLoss(f,scores,labels),x0);
    end

    [trainLossValue,weightIdx] = min(fval);
    weights = x(:,weightIdx);
end



function acc = accuracyLoss(x,Xtest,Ytest)
    acc = 0;
    for i = 1:length(Xtest)
        [~,idx] = min(Xtest{i}*x);
        acc = acc + Ytest{i}(idx);
    end
    acc = acc/length(Xtest);
    acc = 1-acc;
end



