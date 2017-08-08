function [weights,trainLossValue] = trainPairCueWeights(conf,imData,spcScores,ppc)
%TRAINPAIRCUEWEIGHTS trains a linear weighting of single phrase cues
%   inputs
%       conf - configuration settings (e.g. output of plClcConfig)
%       imData - an ImageSetData object
%       spcScores - single phrase cue scores for all phrases in the
%                   sentence
%       ppc - cell array of the pair phrase cues to learn weights over
%   outputs
%       weights - learned linear weighting of the N cues
%       trainLossValue - value of the training loss function
    ppcScores = cell(length(ppc),1);
    for i = 1:length(ppc)
        ppcScores{i} = ppc{i}.scoreRelationship(imData,spcScores);
    end

    [labels,scores] = getPairScoresForTraining(conf,imData,spcScores,ppc,ppcScores); 
    
    % ignore the first two scores as they are the single phrase cue
    % scores for the two phrases in the relationship
    nFeatures = size(scores{1},2) - 2;
    x = zeros(nFeatures,conf.nLearningIterations);
    fval = zeros(conf.nLearningIterations,1);
    parfor i = 1:conf.nLearningIterations
        x0 = rand(nFeatures,1);
        [x(:,i),fval(i)] = fminsearch(@(f)accuracyLossPairs(f,scores,labels),x0);
    end

    [trainLossValue,weightIdx] = min(fval);
    weights = x(:,weightIdx);
end

function [labels,scores] = getPairScoresForTraining(conf,imData,spcScores,ppc,ppcScores)
%GETPAIRSCORESFORTRAINING puts the single and pair phrase cue scores into
%the format used for training the pair score's weights
%       conf - configuration settings (e.g. output of plClcConfig)
%       imData - an ImageSetData object
%       spcScores - single phrase cue scores for all phrases in the
%                   sentence
%       ppc - cell array of the pair phrase cues to learn weights over
%       ppcScores - pair phrase cue scores for all phrases in the
%                   sentence
%   outputs
%       labels - cell array of indicators of the number of correctly 
%                localized phrases for the associated scores (i.e. 0, 1, 
%                or 2)
%       scores - cell array of scores for the single and pair phrase cues
    scores = cell(imData.nImages,1);
    labels = cell(imData.nImages,1);
    parfor i = 1:imData.nImages
        bb = imData.getBoxes(i);
        scores{i} = cell(imData.nSentences(i),1);
        labels{i} = cell(imData.nSentences(i),1);
        for j = 1:imData.nSentences(i)
            scores{i}{j} = cell(imData.nRelationships(i,j),1);
            labels{i}{j} = cell(imData.nRelationships(i,j),1);
            for k = 1:imData.nRelationships(i,j)
                relationship = imData.getRelationship(i,j,k);
                gtLeft = imData.getPhraseGT(i,j,relationship.leftPhrase);
                if isempty(gtLeft),continue,end
                gtRight = imData.getPhraseGT(i,j,relationship.rightPhrase);
                if isempty(gtRight),continue,end
                pairScores = cell(length(ppc),1);
                for c = 1:length(ppc)
                    if isempty(ppcScores{c}{i}{j}{k}),continue,end
                    pairScores{c} = reshape(ppcScores{c}{i}{j}{k}',[],1);
                end
                
                hasScore = find(~cellfun(@isempty,pairScores),1);
                if isempty(hasScore),continue,end

                nBoxes = length(pairScores{hasScore});
                for c = 1:length(ppc)
                    if ~isempty(pairScores{c}),continue,end
                    pairScores{c} = zeros(nBoxes,1,'single');
                end
                
                pairScores = horzcat(pairScores{:});
                boxesLeft = bb(spcScores{i}{j}(relationship.leftPhrase).boxIdx,:);
                overlapLeft = getIOU(gtLeft,boxesLeft) >= conf.posThresh;
                boxesRight = bb(spcScores{i}{j}(relationship.rightPhrase).boxIdx,:);
                overlapRight = getIOU(gtRight,boxesRight) >= conf.posThresh;

                [X,Y] = meshgrid(1:size(boxesLeft,1),1:size(boxesRight,1));
                X = X(:);
                Y = Y(:);
                scoresLeft = spcScores{i}{j}(relationship.leftPhrase).scores(X);
                scoresRight = spcScores{i}{j}(relationship.rightPhrase).scores(Y);
                scores{i}{j}{k} = [scoresLeft,scoresRight,pairScores];
                labels{i}{j}{k} = sum([overlapLeft(X),overlapRight(Y)],2);
            end
        end
    end

    scores = vertcat(scores{:});
    scores = vertcat(scores{:});
    del = cellfun(@isempty,scores);
    scores(del) = [];

    labels = vertcat(labels{:});
    labels = vertcat(labels{:});
    labels(del) = [];
end

function acc = accuracyLossPairs(x,Xtest,Ytest)
    acc = 0;
    for i = 1:length(Xtest)
        % first two indices are single phrase cue scores, while the rest
        % are the pair phrase cues to learn weights for
        [~,idx] = min(Xtest{i}(:,1) + Xtest{i}(:,2) + Xtest{i}(:,3:end)*x);
        acc = acc + Ytest{i}(idx);
    end
    % each pair has a total possible contribution of 2
    acc = acc/(length(Xtest)*2);
    acc = 1-acc;
end



