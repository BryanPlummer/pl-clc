function selectedCandidates = refineCandidatesWithPairPhraseCues(conf,imData,ppcWeights,ppc,spcScores)
%REFINECANDIDATESWITHPAIRPHRASECUES
%   inputs
%       conf - configuration settings (e.g. output of plClcConfig)
%       imData - an ImageSetData object instance
%       ppcWeights - the weights used to mix each pair phrase cue
%       ppc - cell array of pair phrase cues
%       spcScores - single phrase cue scores (e.g. the output of 
%                   scoreRegionsWithSinglePhraseCues)
%   outputs
%       selectedCandidates - top candidate for each phrase
    ppcScores = cell(length(ppc),1);
    for i = 1:length(ppc)
        ppcScores{i} = scoreCue(conf,imData,ppc{i},spcScores);
    end

    selectedCandidates = cell(imData.nImages,1);
    parfor i = 1:imData.nImages
        warning('off','all');
        bb = imData.getBoxes(i);
        selectedCandidates{i} = cell(imData.nSentences(i),1);
        for j = 1:imData.nSentences(i)
            [H,f,Aeq,beq,labels] = getQuadProgArgs(conf,imData,i,j,spcScores,ppcScores,ppcWeights);
            if isempty(labels),continue,end
            lb = zeros(length(f),1);
            ub = ones(length(f),1);
            A = [];
            b = [];
            opts = optimset('Algorithm','active-set','MaxIter',10000);
            x = quadprog(H,f,A,b,Aeq,beq,lb,ub,[],opts);
            x = x > 1e-2;
            featIdx = [0;cumsum(cellfun(@length,labels))];
            
            selectedCandidates{i}{j} = zeros(imData.nPhrases(i,j),1);
            for k = 1:length(labels)
                selected = x(featIdx(k)+1:featIdx(k+1));
                selectedLabels = labels{k}(selected);
                if length(selectedLabels) > 1
                    phrasef = f(featIdx(k)+1:featIdx(k+1));
                    [~,idx] = min(phrasef(selected));
                    selectedLabels = selectedLabels(idx);
                    candidateIdx = spcScores{i}{j}(k).boxIdx(selected);
                    selectedCandidates{i}{j}(k) = candidateIdx(idx);
                else
                    selectedCandidates{i}{j}(k) = spcScores{i}{j}(k).boxIdx(selected);
                end
                assert(length(selectedLabels) == 1);
            end
        end
        warning('on','all');
    end
end

function [H,f,Aeq,beq,labels] = getQuadProgArgs(conf,imData,imNumber,sentNumber,spcScores,ppcScores,ppcWeights)
    bb = imData.getBoxes(imNumber);
    f = cell(imData.nPhrases(imNumber,sentNumber),1);
    labels = cell(imData.nPhrases(imNumber,sentNumber),1);
    fPhrases = cell(imData.nPhrases(imNumber,sentNumber),1);
    for i = 1:imData.nPhrases(imNumber,sentNumber)
        box = imData.getPhraseGT(imNumber,sentNumber,i);
        if isempty(box),continue,end
        f{i} = spcScores{imNumber}{sentNumber}(i).scores;
        labels{i} = getIOU(box,bb(spcScores{imNumber}{sentNumber}(i).boxIdx,:));
        labels{i} = labels{i} >= conf.posThresh;
        fPhrases{i} = ones(length(f{i}),1)*i;
    end
    
    f = vertcat(f{:});
    if isempty(f)
        H = [];
        Aeq = [];
        beq = [];
        return;
    end
    f = f + (rand(length(f),1)/1e5);
    fPhrases = vertcat(fPhrases{:});
    labels(cellfun(@isempty,labels)) = [];
    featIdx = [0;cumsum(cellfun(@length,labels))];
    Aeq = zeros(length(labels),length(f));
    for k = 1:length(labels)
        Aeq(k,featIdx(k)+1:featIdx(k+1)) = 1;
    end
    beq = ones(length(labels),1);
    H = zeros(length(f));
    for i = 1:imData.nRelationships(imNumber,sentNumber)
        relationship = imData.getRelationship(imNumber,sentNumber,i);
        if isempty(relationship.leftPhrase) || isempty(relationship.rightPhrase),continue,end
        leftIdx = find(relationship.leftPhrase == fPhrases);
        if isempty(leftIdx),continue,end
        rightIdx = find(relationship.rightPhrase == fPhrases);
        if isempty(rightIdx),continue,end
        for c = 1:length(ppcScores)
            if isempty(ppcScores{c}{imNumber}{sentNumber}{i}),continue,end
            pScores = ppcScores{c}{imNumber}{sentNumber}{i}*ppcWeights(c);
            H(leftIdx,rightIdx) = H(leftIdx,rightIdx) + pScores;
            H(rightIdx,leftIdx) = H(rightIdx,leftIdx) + pScores';
        end
    end
    
    f = double(f);
end

function scores = scoreCue(conf,imData,cue,spcScores)
    cachedir = fullfile(conf.cachedir,imData.split);
    if conf.cacheCueScores
        scores = cue.loadCueScores(cachedir);
    else
        scores = [];
    end

    saveFile = isempty(scores) && conf.cacheCueScores;
    if isempty(scores)
        scores = cue.scoreRelationship(imData,spcScores);
    end

    if saveFile
        cue.saveCueScores(cachedir,scores);
    end
end

