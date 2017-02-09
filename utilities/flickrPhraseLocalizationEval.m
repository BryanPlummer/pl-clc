function [acc,oracleAcc] = flickrPhraseLocalizationEval(imData,boxes,boxIdx,posThresh,spc,ppc,outfn,groupOrder)
%FLICKRPHRASELOCALIZATIONEVAL performs the phrase localization evaluation, 
%only the first three inputs are required
%   inputs
%       imData - an instance of ImageSetData of testing data
%       boxes - cell array boxes for each phrase in the imageInfo instance
%       boxIdx - cell array indices of the best scoring region for each 
%                phrase
%       posThresh - minimum IOU threshold a candidate box must have with
%                   the ground truth for it to be deemed a success 
%       spc - cell array of the single phrase cues used to score each box
%       ppc - cell array of the pair phrase cues used to score each box
%       outfn - a csv filename to output detailed performance information
%       groupOrder - desired order of the phrase types used in the output 
%                    file
%   outputs
%       acc - Recall@1 performance
%       oracleAcc - upper bound performance given the input boxes
    predictedOverlaps = cell(imData.nImages,1);
    oracleSuccess = 0;
    if nargin > 4
        groupSuccess = containers.Map;
        confused = containers.Map;
        confusedFail = 0;
        predictedEnclosedFail = 0;
        gtEnclosedFail = 0;
        lowOverlapFail = cell(imData.nImages,1);
        spcSuccess = cell(imData.nImages,1);
        ppcSuccess = cell(imData.nImages,1);
        stopwords = imData.stopwords;
    end

    for i = 1:imData.nImages
        if mod(i,100) == 0
            fprintf('Eval %i of %i\n',i,imData.nImages);
        end
        predictedOverlaps{i} = cell(imData.nSentences(i),1);
        if nargin > 3
            lowOverlapFail{i} = cell(imData.nSentences(i),1);
            spcSuccess{i} = cell(imData.nSentences(i),1);
            ppcSuccess{i} = cell(imData.nSentences(i),1);
        end

        bb = imData.getBoxes(i);
        for j = 1:imData.nSentences(i)
            gtBoxes = imData.getPhraseGT(i,j);

            if ~isempty(find(cellfun(@(f)(size(f,1) ~= 1),gtBoxes),1))
                error('flickrPhraseLocationEval: assumes each phrase has a ground truth box, run ImageSetData/filterNonvisualPhrases');
            end
            
            gtBoxes = vertcat(gtBoxes{:});
            predictedOverlaps{i}{j} = zeros(imData.nPhrases(i,j),1);
            if nargin > 4
                lowOverlapFail{i}{j} = cell(imData.nPhrases(i,j),1);
                % +1 is for pronouns which don't have their own feature
                spcSuccess{i}{j} = cell(imData.nPhrases(i,j),length(spc)+1);
                ppcSuccess{i}{j} = cell(imData.nPhrases(i,j),length(ppc)+1);
            end

            for k = 1:imData.nPhrases(i,j)
                overlaps = getIOU(gtBoxes(k,:),boxes{i}{j}{k});
                predictedOverlaps{i}{j}(k) = getIOU(gtBoxes(k,:),bb(boxIdx{i}{j}(k),:));
                isHighestOverlapSuccessful = max(overlaps) >= posThresh;
                oracleSuccess = oracleSuccess + isHighestOverlapSuccessful;
                if nargin < 5,continue,end

                phrase = imData.getPhrase(i,j,k);
                if predictedOverlaps{i}{j}(k) < posThresh
                    predictedBox = bb(boxIdx{i}{j}(k),:);
                    gtOverlaps = getIOU(predictedBox,gtBoxes);
                    [bestOverlap,gtIdx] = max(gtOverlaps);
                    if bestOverlap >= posThresh
                        confusedFail = confusedFail + 1;
                        confusedGroup = imData.getPhrase(i,j,gtIdx).groupType;
                        for type = 1:length(phrase.groupType)
                            group = phrase.groupType{type};
                            cg = confusedGroup;
                            if confused.isKey(group)
                                cg = [cg;confused(group)];
                            end
                            
                            confused(group) = cg;
                        end
                    else
                        predEnclosed = isContained(predictedBox,gtBoxes(k,:));
                        predictedEnclosedFail = predictedEnclosedFail + predEnclosed;
                        gtEnclosed = isContained(gtBoxes(k,:),predictedBox);
                        gtEnclosedFail = gtEnclosedFail + gtEnclosed;
                        if ~gtEnclosed && ~predEnclosed
                            lowOverlapFail{i}{j}{k} = predictedOverlaps{i}{j}(k);
                        end
                    end
                end

                success = [predictedOverlaps{i}{j}(k),isHighestOverlapSuccessful];
                for type = 1:length(phrase.groupType)
                    group = phrase.groupType{type};
                    items = success;
                    if groupSuccess.isKey(group)
                        items = [items;groupSuccess(group)];
                    end
                    
                    groupSuccess(group) = items;
                end

                for cue = 1:length(spc)
                    isSubjectRestricted = spc{cue}.isCueSubjectRestricted;
                    relationship = imData.getRelationshipForPhrase(i,j,k,isSubjectRestricted);
                    if ~isempty(spc{cue}.getCueCategory(phrase,relationship,stopwords))
                        spcSuccess{i}{j}{k,cue} = predictedOverlaps{i}{j}(k);
                        if ~isempty(isSubjectRestricted) && isempty(spcSuccess{i}{j}{k,end})
                            for r = 1:length(relationship)
                                if relationship(r).isPronounCoref(isSubjectRestricted)
                                    spcSuccess{i}{j}{k,end} = predictedOverlaps{i}{j}(k);
                                    break;
                                end
                            end
                        end
                    end
                end

                leftPronoun = false;
                rightPronoun = false;
                for cue = 1:length(ppc)
                    relationship = imData.getRelationshipForPhrase(i,j,k);
                    leftFound = false;
                    rightFound = false;
                    for r = 1:length(relationship)
                        if isempty(relationship(r).leftPhrase) || isempty(relationship(r).rightPhrase),continue,end
                        isLeftPhrase = relationship(r).leftPhrase == k;
                        if isLeftPhrase && leftFound,continue,end
                        leftPhrase = imData.getPhrase(i,j,relationship(r).leftPhrase);
                        rightPhrase = imData.getPhrase(i,j,relationship(r).rightPhrase);
                        if ~isempty(ppc{cue}.getCueCategory(leftPhrase,rightPhrase,relationship(r),stopwords))
                            if isLeftPhrase
                                if ~leftFound
                                    leftFound = true;
                                    ppcSuccess{i}{j}{k,cue} = [ppcSuccess{i}{j}{k,cue};{predictedOverlaps{i}{j}(k),[]}];
                                end

                                if ~leftPronoun && relationship(r).isPronounCoref(isLeftPhrase)
                                    leftPronoun = true;
                                    ppcSuccess{i}{j}{k,end} = [ppcSuccess{i}{j}{k,end};{predictedOverlaps{i}{j}(k),[]}];
                                end
                            else
                                if ~rightFound
                                    rightFound = true;
                                    ppcSuccess{i}{j}{k,cue} = [ppcSuccess{i}{j}{k,cue};{[],predictedOverlaps{i}{j}(k)}];
                                end

                                if ~rightPronoun && relationship(r).isPronounCoref(isLeftPhrase)
                                    rightPronoun = true;
                                    ppcSuccess{i}{j}{k,end} = [ppcSuccess{i}{j}{k,end};{[],predictedOverlaps{i}{j}(k)}];
                                end
                            end
                        end

                        if leftFound && rightFound && leftPronoun && rightPronoun,break,end
                    end
                end
            end
        end
    end

    predictedOverlaps = vertcat(predictedOverlaps{:});
    predictedOverlaps = vertcat(predictedOverlaps{:});
    overallCorrect = sum(predictedOverlaps >= posThresh);
    acc = overallCorrect/length(predictedOverlaps);
    oracleAcc = oracleSuccess/length(predictedOverlaps);
    if nargin < 5,return,end
    fileID = fopen(outfn,'w');
    groupKeys = groupSuccess.keys();
    if nargin > 6 && ~isempty(groupOrder)
        order = sort(cellfun(@(f)find(strcmp(f,groupOrder),1),groupKeys));
        groupKeys = groupOrder(order);
    end
    format = strcat(',',repmat('%s,',1,length(groupKeys)),'OverallPerformance\nR@1,');
    fprintf(fileID,format,groupKeys{:});
    for i = 1:length(groupKeys)
        predictions = groupSuccess(groupKeys{i});
        nCorrect = sum(predictions(:,1) >= posThresh);
        fprintf(fileID,'%.2f,',dec2percent(nCorrect/size(predictions,1)));
    end

    fprintf(fileID,'%.2f\nOracle,',dec2percent(acc));
    for i = 1:length(groupKeys)
        predictions = groupSuccess(groupKeys{i});
        nCorrect = sum(predictions(:,2));
        fprintf(fileID,'%.2f,',dec2percent(nCorrect/size(predictions,1)));
    end

    fprintf(fileID,'%.2f\nnInstances,',dec2percent(oracleAcc));

    for i = 1:length(groupKeys)
        predictions = groupSuccess(groupKeys{i});
        fprintf(fileID,'%i,',size(predictions,1));
    end

    brackets = posThresh:0.1:0.9;
    fprintf(fileID,'%i\n\nSuccessful Breakdown',length(predictedOverlaps));
    for i = 1:length(brackets)
        if i ~= length(brackets)
            fprintf(fileID,',>= %1.2f and < %1.2f',brackets(i),brackets(i+1));
        else
            fprintf(fileID,',>= %1.2f\n%% of Correct Predictions',brackets(i));
        end
    end

    for i = 1:length(brackets)
        if i ~= length(brackets)
            nCorrect = and(predictedOverlaps >= brackets(i),predictedOverlaps < brackets(i+1));
            fprintf(fileID,',%.2f',dec2percent(sum(nCorrect)/overallCorrect));
        else
            nCorrect = sum(predictedOverlaps >= brackets(i));
            fprintf(fileID,',%.2f\n\n',dec2percent(sum(nCorrect)/overallCorrect));
        end
    end

    fprintf(fileID,['Failure Breakdown,>= 0.5 IOU with another ' ...
                    'phrase,gt enclosed by predicted box, predicted ' ...
                    'box enclosed by gt,(remaining failure) low ' ...
                    'overlaps -']);

    brackets = 0:0.1:posThresh;

    for i = 1:length(brackets)-1
        fprintf(fileID,',>= %1.2f and < %1.2f',brackets(i),brackets(i+1));
    end

    nIncorrect = length(predictedOverlaps)-overallCorrect;
    cfp = dec2percent(confusedFail/nIncorrect);
    gpb = dec2percent(gtEnclosedFail/nIncorrect);
    pgb = dec2percent(predictedEnclosedFail/nIncorrect);
    fprintf(fileID,'\n%% of Incorrect Predictions,%.2f,%.2f,%.2f,',cfp,gpb,pgb);

    for i = 1:length(brackets)-1
        nCorrect = and(predictedOverlaps >= brackets(i),predictedOverlaps < brackets(i+1));
        fprintf(fileID,',%.2f',dec2percent(sum(nCorrect)/overallCorrect));
    end

    fprintf(fileID,'\n\nConfused Phrase Failure Breakdown By Type\n');
    format = strcat(repmat('Phrase Type Localized x Confused Phrase Type,%s',1,length(groupKeys)),'\n');
    fprintf(fileID,format,groupKeys{:});
    for i = 1:length(groupKeys)
        confusedTypes = confused(groupKeys{i});
        [uniqueTypes,~,typeIdx] = unique(confusedTypes);
        occurances = histc(typeIdx,1:length(uniqueTypes));
        typeOrder = cellfun(@(f)find(strcmp(f,groupKeys),1),uniqueTypes);
        confusedCount = zeros(length(groupKeys),1);
        confusedCount(typeOrder) = occurances;
        format = strcat('%s',repmat(',%i',1,length(groupKeys)),'\n');
        fprintf(fileID,format,groupKeys{i},confusedCount(:));
    end

    fprintf(fileID,'\nPerformance of Phrases Affected by Cue\n\nSingle Phrase Cue');
    cellfun(@(f)fprintf(fileID,',%s',f.cueLabel),spc);
    fprintf(fileID,',pronouns\n');
    spcSuccess = vertcat(spcSuccess{:});
    spcSuccess = vertcat(spcSuccess{:});
    nItems = zeros(size(spcSuccess,2),1);
    for i = 1:size(spcSuccess,2)
        cueSuccess = vertcat(spcSuccess{:,i});
        if isempty(cueSuccess)
            fprintf(fileID,',0');
        else
            cueSuccess = cueSuccess >= posThresh;
            nCueCorrect = sum(cueSuccess);
            nItems(i) = length(cueSuccess);
            fprintf(fileID,',%.2f',dec2percent(nCueCorrect/nItems(i)));
        end
    end
    
    format = strcat('\nnInstances',repmat(',%i',1,length(nItems)),'\n');
    fprintf(fileID,format,nItems);
    
    fprintf(fileID,'\nPair Phrase Cue');
    cellfun(@(f)fprintf(fileID,',%s,',f.cueLabel),ppc);
    fprintf(fileID,strcat(',pronouns,\n,',repmat('Left,Right,',1,length(ppc)),'Left,Right\n'));
    ppcSuccess = vertcat(ppcSuccess{:});
    ppcSuccess = vertcat(ppcSuccess{:});
    nItems = zeros(size(ppcSuccess,2),2);
    for i = 1:size(ppcSuccess,2)
        cueSuccess = vertcat(ppcSuccess{:,i});
        if isempty(cueSuccess)
            fprintf(fileID,',0,0');
        else
            successLeft = vertcat(cueSuccess{:,1}) >= posThresh;
            successRight = vertcat(cueSuccess{:,2}) >= posThresh;
            nItems(i,:) = [length(successLeft),length(successRight)];
            leftCorrect = dec2percent(sum(successLeft)/nItems(i,1));
            rightCorrect = dec2percent(sum(successRight)/nItems(i,2));
            fprintf(fileID,',%.2f,%.2f',leftCorrect,rightCorrect);
        end
    end
    
    nItems = reshape(nItems',[],1);
    format = strcat('\nnInstances',repmat(',%i',1,length(nItems)),'\n');
    fprintf(fileID,format,nItems);
    fclose(fileID);
end

function percentage = dec2percent(dec,nAfterPeriod)
    if nargin < 2
        nAfterPeriod = 2;
    end
    
    percentage = round(dec*100,nAfterPeriod);
end
    

function isContainedWithin = isContained(testBox,referenceBox)
    isContainedWithin = isempty(find(testBox(1:2) < referenceBox(1:2),1)) ...
        && isempty(find(testBox(3:4) > referenceBox(3:4),1));
end
