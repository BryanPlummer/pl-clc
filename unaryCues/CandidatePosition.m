classdef CandidatePosition < SinglePhraseCue
%CANDIDATEPOSITION bounding box candidate position cue
%   This class scores region proposal's affinity to a phrase type from an
%   svm from the candidate's centroid, aspect ratio, and the percent of the
%   image it covers. 
%
%   Documentation for class member variables and functions not provided
%   here are located in the superclass they are originally defined in.
    methods
        function cue = CandidatePosition(cueLabel,cueModel,classes)
            label = [];
            model = [];
            dictionary = [];
            if nargin > 0
                label = cueLabel;
                model = cueModel;
                dictionary = classes;
            end
            
            cue = cue@SinglePhraseCue(label,model,dictionary);
        end
        
        function cueClass = getCueCategory(cue,phrase,relationship,stopwords)
            if strcmp('notvisual',phrase.groupType)
                cueClass = [];
            else
                cueClass = cellfun(@(f)find(strcmp(f,cue.dictionary),1),phrase.groupType);
            end
        end

        function trainModel(cue,imData,maxTrainSamples,trainPosThresh)
            features = cell(imData.nImages,1);
            parfor i = 1:imData.nImages
                imDims = imData.imSize(i);
                bb = imData.getBoxes(i);
                boxPosition = boxPositionFeatures(bb,imDims);
                features{i} = cell(imData.nSentences(i),1);
                for j = 1:imData.nSentences(i)
                    features{i}{j} = cell(imData.nPhrases(i,j),1);
                    for k = 1:imData.nPhrases(i,j)
                        phrase = imData.getPhrase(i,j,k);
                        cueClass = cue.getCueCategory(phrase);
                        if isempty(cueClass),continue,end
                        box = imData.getPhraseGT(i,j,k);
                        if isempty(box),continue,end
                        overlap = getIOU(box,bb);
                        features{i}{j}{k} = cell(1,length(cue.dictionary));
                        for c = 1:length(cueClass)
                            class = cueClass(c);
                            features{i}{j}{k}{class} = [boxPosition,overlap];
                        end
                    end
                end
            end

            cue.model = trainLibSVMClassifier(features,maxTrainSamples,trainPosThresh);
        end
        
        function [scores,boxes] = scorePhrase(cue,imData)
            boxes = [];
            scores = cell(imData.nImages,1);
            parfor i = 1:imData.nImages
                imDims = imData.imSize(i);
                bb = imData.getBoxes(i);
                boxPosition = sparse(double(boxPositionFeatures(bb,imDims)));
                modelScores = zeros(size(bb,1),length(cue.dictionary),'single');
                labels = zeros(size(boxPosition,1),1);
                for c = 1:length(cue.dictionary)
                    svmScores = svmpredict(labels,boxPosition,cue.model{c}.svm,'-q');
                    modelScores(:,c) = predict(cue.model{c}.prob,svmScores);
                end

                scores{i} = cell(imData.nSentences(i),1);
                for j = 1:imData.nSentences(i)
                    scores{i}{j} = cell(imData.nPhrases(i,j),1);
                    for k = 1:imData.nPhrases(i,j)
                        phrase = imData.getPhrase(i,j,k);
                        cueClass = cue.getCueCategory(phrase);
                        if ~isempty(cueClass)
                            % adds an eps so we avoid taking log of zero
                            scores{i}{j}{k} = mean(modelScores(:,cueClass),2) + eps('single');
                            scores{i}{j}{k} = -log(scores{i}{j}{k});
                        else
                            scores{i}{j}{k} = zeros(size(modelScores,1),1,'single');
                        end
                    end
                end
            end
        end
    end
end

