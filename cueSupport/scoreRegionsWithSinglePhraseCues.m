function scores = scoreRegionsWithSinglePhraseCues(conf,imData,weights,cueScores,boxes,addBestCandidate)
%SCOREREGIONSWITHSINGLEPHRASECUES keeps the top K instances for each phrase 
%after scoring the regions using all the single phrase cues and mixture weights
%   inputs
%       conf - configuration settings (e.g. output of plClcConfig)
%       imData - an ImageSetData object instance
%       weights - the weights used to mix each single phrase cue
%       cueScores - cell array where each phrase contains the scores for
%                   each cue for each phrase
%       boxes - updated candidate boxes for each phrase
%       addBestCandidate - when true the candidate with the highest overlap 
%                          with the ground truth box is always in the output
%   outputs
%       scores - single phrase cue scores for each phrase
    scores = cell(imData.nImages,1);
    parfor i = 1:imData.nImages
        scores{i} = cell(imData.nSentences(i),1);
        bb = imData.getBoxes(i);
        for j = 1:imData.nSentences(i)
            scores{i}{j} = repmat(struct('boxIdx',[],'scores',[]),imData.nPhrases(i,j),1);
            for k = 1:imData.nPhrases(i,j)
                box = imData.getPhraseGT(i,j,k);
                if isempty(box),continue,end

                phraseScores = cueScores{i}{j}{k}*weights;
                if isempty(boxes)
                    phraseBoxes = [bb,phraseScores];
                else
                    phraseBoxes = [boxes{i}{j}{k},phraseScores];
                end

                if addBestCandidate
                    overlap = getIOU(box,phraseBoxes);
                    [~,bestCandidate] = max(overlap);
                else
                    bestCandidate = [];
                end

                assert(size(phraseBoxes,2) == 5);

                pick = nms_iou(phraseBoxes,conf.nmsThresh);
                if ~isempty(bestCandidate)
                    pick(pick == bestCandidate) = [];
                end

                if length(pick) > conf.maxNumInstances
                    [~,order] = sort(phraseBoxes(pick,end),'ascend');
                    pick = pick(order(1:conf.maxNumInstances));
                end
                
                pick = [bestCandidate;pick];
                boxIdx = imData.phraseBoxToImageBox(i,phraseBoxes(:,1:4));
                scores{i}{j}(k).boxIdx = boxIdx(pick);
                scores{i}{j}(k).scores = phraseBoxes(pick,end);
            end
        end
    end
end