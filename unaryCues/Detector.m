classdef Detector < SinglePhraseCue
%DETECTOR generic fast rcnn-based detector cue
%   This class takes each phrase and scores any appropriate detectors on
%   their bounding boxes.  If multiple detectors are suitable, the average
%   detector score is returned.
%
%   Documentation for class member variables and functions not provided
%   here are located in the superclass they are originally defined in.
    properties (SetAccess = protected)
        % Full file path for the prototxt used for this detector model.
        % the weight file name is stored in the "model" variable.
        def = [];
    end

    methods
        function cue = Detector(cueLabel,net,def,classes)
            label = [];
            model = [];
            dictionary = [];
            if nargin > 0
                label = cueLabel;
                model = net;
                dictionary = classes;
            end

            cue = cue@SinglePhraseCue(label,model,dictionary);
            cue.def = def;
        end

        function [cueClass,wordMap] = getCueCategory(cue,phrase,relationship,stopwords)
            classes = cue.dictionary.words;
            phraseTypes = cue.dictionary.types;
            cueClass = false(length(classes),1);
            wordMap = zeros(length(phrase.words),1);
            for i = 1:length(classes)
                isCue = find(cellfun(@(f)~isempty(find(strcmpi(f,classes{i}),1)),phrase.words));
                prevMap = wordMap(isCue);
                wordMap(isCue) = i;
                cueClass(i) = ~isempty(isCue);
                if cueClass(i) && ~isempty(phraseTypes) && ~isempty(phraseTypes{i})
                    cueClass(i) = ~isempty(find(strcmpi(phraseTypes{i},phrase.groupType),1));
                    if ~cueClass(i)
                        wordMap(isCue) = prevMap;
                    end
                end
            end

            cueClass = find(cueClass);
        end

        function [scores,boxes] = scorePhrase(cue,imData) 
            [caffeNet,conf,maxROIS] = fastRCNNInit(cue.model,cue.def);
            stopwords = imData.stopwords;
            isSubjectRestricted = cue.isCueSubjectRestricted;
            scores = cell(imData.nImages,1);
            boxes = cell(imData.nImages,1);
            for i = 1:imData.nImages
                if mod(i,100) == 0
                    fprintf('%s: %i of %i\n',cue.cueLabel,i,imData.nImages);
                end
                scores{i} = cell(imData.nSentences(i),1);
                boxes{i} = cell(imData.nSentences(i),1);
                imScores = [];
                imBoxes = [];
                for j = 1:imData.nSentences(i)
                    scores{i}{j} = cell(imData.nPhrases(i,j),1);
                    boxes{i}{j} = cell(imData.nPhrases(i,j),1);
                    for k = 1:imData.nPhrases(i,j)
                        relationship = imData.getRelationshipForPhrase(i,j,k,isSubjectRestricted);
                        phrase = imData.getPhrase(i,j,k);
                        [cueClass,wordMap] = cue.getCueCategory(phrase,relationship,stopwords);
                        if ~isempty(cueClass)
                            catchall = cue.isCueCategoryCatchall(cueClass);
                            if ~isempty(find(~catchall,1))
                                if length(cueClass) == length(wordMap) && ...
                                        isempty(find(cueClass ~= wordMap,1))
                                    wordMap(catchall) = [];
                                end
                                cueClass(catchall) = [];
                            end
                            
                            if isempty(imScores)
                                im = imData.readImage(i);
                                [imBoxes,imScores] = fast_rcnn_im_detect(conf,caffeNet,im,imData.getBoxes(i),maxROIS);
                            end
                            
                            if nargout > 1
                                if length(cueClass) > 1
                                    class = wordMap(find(wordMap,1,'last'));
                                    assert(~isempty(find(class == cueClass,1)));
                                    cueClass = class;
                                end
                                    
                                boxes{i}{j}{k} = imBoxes(:,(cueClass-1)*4+1:cueClass*4);
                            end

                            scores{i}{j}{k} = zeros(size(imBoxes,1),length(cueClass),'single');
                            for c = 1:length(cueClass)
                                scores{i}{j}{k}(:,c) = imScores(:,cueClass(c));
                            end
                            
                            % adds an eps so we avoid taking log of zero
                            scores{i}{j}{k} = -log(mean(scores{i}{j}{k},2) + eps('single'));
                        else
                            bb = imData.getBoxes(i);
                            if nargout > 1
                                boxes{i}{j}{k} = bb;
                            end
                            scores{i}{j}{k} = zeros(size(bb,1),1,'single');
                        end
                    end
                end
            end
            
            caffe.reset_all();
        end
    end
end

