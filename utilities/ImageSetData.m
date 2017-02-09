classdef ImageSetData < handle
%IMAGESETDATA This class contains all the dataset's annotations and support
%functions
    
    properties (SetAccess = public)
        % identifier for this instance as a train/test/val split
        split = [];
        
        % list of images in this split
        imagefns = [];

        % path where the data's images are located
        imagedir = [];

        % extension used by the images in the dataset
        ext = [];

        % cell array containing an Entity object for each annotationed
        % phrase
        phrase = [];

        % cell array containing the extracted pair phrase relationships in
        % the dataset
        relationship = [];

        % cell array where each element contains the proposals for an image
        boxes = [];

        % cell array of stopwords
        stopwords = [];

        % array of struct outputs of the getAnnotations function from
        % Flickr30k dataset's functions
        annotations = [];
    end

    methods
        function imData = ImageSetData(split,imagefns,imagedir,ext,stopwords)
            imData.split = split;
            imData.imagefns = imagefns;
            imData.imagedir = imagedir;
            imData.ext = ext;
            imData.stopwords = stopwords;
        end

        function computeSetData(imData,nThreads,annodir,pronounFile,nEdgeBoxes)
        %COMPUTESETDATA creates the categories the cue will learn
        %   inputs
        %       imData - this instance of an ImageSetData object
        %       nThreads - number of threads used to parse the dataset's
        %                  sentences
        %       annodir - Flickr30k Entities Annotations directory
        %       pronounFile - csv file with pronoun reference information,
        %                     see data/flickr30k/pronomCoref_v1.csv for
        %                     expected format information
        %       nEdgeBoxes - maximum number of edge box proposals per image
            if nargin > 1 && ~isempty(annodir)
                [imData.relationship,imData.phrase] = batchSentenceParse(imData.imagefns,annodir,nThreads,pronounFile);
                imData.annotations = cellfun(@(f)getAnnotations(fullfile(annodir,'Annotations',strcat(f,'.xml'))),imData.imagefns);
            end
            if nargin > 4 && ~isempty(nEdgeBoxes)
                eb = EdgeBoxInterface;
                eb.opts.maxBoxes = nEdgeBoxes;
                imData.boxes = cell(imData.nImages,1);
                for i = 1:imData.nImages
                    if mod(i,100) == 0
                        fprintf('EdgeBox Proposals: %i of %i\n',i,imData.nImages);
                    end
                    im = imData.readImage(i);
                    bb = eb.computeProposals(im);
                    imData.boxes{i} = unique(bb(:,1:4),'rows');
                end
            end
        end

        function box = getPhraseGT(imData,imNumber,sentNumber,phraseNumber)
        %GETPHRASEGT returns ground truth bounding box annotations for a
        %phrase
        %   inputs
        %       imData - this instance of an ImageSetData object
        %       imNumber - index of the image of the desired phrase(s)
        %       sentNumber - index of the desired phrase(s)
        %       phraseNumber - optional, exact phrase to obtain annotations
        %                      for
        %   outputs
        %       box - ground truth annotations for a phrase, if no
        %             phraseNumber is provided, the output is a cell array
        %             with all the annotations for that sentence 
           if nargin > 3 && isempty(phraseNumber)
                box = [];
                return;
            end
            imAnno = imData.annotations(imNumber);
            if nargin > 3
                phrase = imData.getPhrase(imNumber,sentNumber,phraseNumber);
                box = phrase.getGTBox(imAnno);
            else
                box = cell(imData.nPhrases(imNumber,sentNumber),1);
                for i = 1:imData.nPhrases(imNumber,sentNumber)
                    box{i} = imData.getPhraseGT(imNumber,sentNumber,i);
                end
            end
        end
        
        function concatenateGTBoxes(imData)
        %CONCATENATEGTBOXES adds all the ground truth boxes for an image to
        %the boxes member variable
        %   inputs
        %       imData - this instance of an ImageSetData object
            for i = 1:imData.nImages
                gtBoxes = cell(imData.nSentences(i),1);
                for j = 1:imData.nSentences(i)
                    gtBoxes{j} = imData.getPhraseGT(i,j);
                end
                
                boxes = imData.getBoxes(i);
                gtBoxes = vertcat(gtBoxes{:});
                boxes = vertcat(gtBoxes{:},boxes);
                imData.boxes{i} = unique(boxes,'rows');
            end
        end

        function nIm = nImages(imData)
            nIm = length(imData.imagefns);
        end
        
        function nSent = nSentences(imData,imNumber)
            nSent = length(imData.phrase{imNumber});
        end

        function nPhr = nPhrases(imData,imNumber,sentNumber)
            nPhr = length(imData.phrase{imNumber}{sentNumber});
        end

        function nRel = nRelationships(imData,imNumber,sentNumber)
            nRel = length(imData.relationship{imNumber}{sentNumber});
        end

        function relationship = getRelationship(imData,imNumber,sentNumber,relationNumber)
            relationship = imData.relationship;
            if nargin > 1
                relationship = relationship{imNumber};
                if nargin > 2
                    relationship = relationship{sentNumber};
                    if nargin > 3
                        relationship = relationship(relationNumber);
                    end
                end
            end
        end

        function relationship = getRelationshipForPhrase(imData,imNumber,sentNumber,phraseNumber,leftPhrase)
        %GETRELATIONSHIPFORPHRASE returns any pair phrase relationships for
        %a particular phrase
        %   inputs
        %       imData - this instance of an ImageSetData object
        %       imNumber - index of the image of the desired phrase
        %       sentNumber - index of the desired phrase
        %       phraseNumber - desired phrase relationships
        %       leftPhrase - optional, logical identifying a restriction on
        %                    the returned relationships being on the left
        %                    or right side of the phrase
        %   outputs
        %       relationship - identified relationships where the desired
        %                      phrase is one of the phrases in the
        %                      relationship
            relationship = imData.getRelationship(imNumber,sentNumber);
            if isempty(relationship),return,end
            if nargin < 5 || isempty(leftPhrase) || leftPhrase
                phraseIdx = {relationship.leftPhrase};
                hasPhrase = false(length(phraseIdx),1);
                noIdx = cellfun(@isempty,phraseIdx);
                phraseIdx = vertcat(phraseIdx{:});
                hasPhrase(~noIdx) = phraseIdx == phraseNumber;
                if nargin < 5 || isempty(leftPhrase)
                    phraseIdx = {relationship.rightPhrase};
                    noIdx = cellfun(@isempty,phraseIdx);
                    phraseIdx = vertcat(phraseIdx{:});
                    if ~isempty(phraseIdx)
                        hasPhrase(~noIdx) = or(hasPhrase(~noIdx),phraseIdx == phraseNumber);
                    end
                end
            else
                phraseIdx = {relationship.rightPhrase};
                hasPhrase = false(length(phraseIdx),1);
                noIdx = cellfun(@isempty,phraseIdx);
                phraseIdx = vertcat(phraseIdx{:});
                hasPhrase(~noIdx) = phraseIdx == phraseNumber;
            end

            relationship = relationship(hasPhrase);
        end

        function phrase = getPhrase(imData,imNumber,sentNumber,phraseNumber)
            phrase = imData.phrase;
            if nargin > 1
                phrase = phrase{imNumber};
                if nargin > 2
                    phrase = phrase{sentNumber};
                    if nargin > 3
                        phrase = phrase(phraseNumber);
                    end
                end
            end
        end

        function im = readImage(imData,imNumber)
            fn = fullfile(imData.imagedir,strcat(imData.imagefns{imNumber},'.',imData.ext));
            im = imread(fn);
            if size(im,3) == 1
                im = cat(3,im,im,im);
            end
        end

        function imDims = imSize(imData,imNumber)
            fn = fullfile(imData.imagedir,strcat(imData.imagefns{imNumber},'.',imData.ext));
            info = imfinfo(fn);
            imDims = [info.Height,info.Width];
        end

        function boxes = getBoxes(imData,imNumber)
            boxes = single(imData.boxes{imNumber}(:,1:4));
        end

        function phraseWords = getPhraseWords(imData)
        %GETPHRASEWORDS returns all the phrases in this object instance
        %   inputs
        %       imData - this instance of an ImageSetData object
        %   outputs
        %       phraseWords - cell array containing every phrase in this
        %                     object instance
            phraseWords = cell(imData.nImages,1);
            for i = 1:imData.nImages
                phraseWords{i} = cell(imData.nSentences(i),1);
                for j = 1:imData.nSentences(i)
                    phraseWords{i}{j} = cell(imData.nPhrases(i,j),1);
                    for k = 1:imData.nPhrases(i,j)
                        phraseWords{i}{j}{k} = imData.getPhrase(i,j,k).getPhraseString(imData.stopwords);
                    end
                end
            end
        end
        
        function labels = isBoxPositive(imData,conf,boxes)
        %ISBOXPOSITIVE finds if a candidate box is a good box for a phrase
        %   inputs
        %       imData - this instance of an ImageSetData object
        %       conf - configuration settings (e.g. output of plClcConfig)
        %       boxes - candidate boxes for every phrase of the imData
        %               instance
        %   outputs
        %       labels - cell array where every phrase index is a logical
        %                value of whether it is a good candidate box for a
        %                phrase
            labels = cell(imData.nImages,1);
            parfor i = 1:imData.nImages
                bb = imData.getBoxes(i);
                labels{i} = cell(imData.nSentences(i),1);
                for j = 1:imData.nSentences(i)
                    labels{i}{j} = cell(imData.nPhrases(i,j),1);
                    for k = 1:imData.nPhrases(i,j)
                        box = imData.getPhraseGT(i,j,k);
                        if isempty(box),continue,end
                        boxIdx = imData.phraseBoxToImageBox(i,boxes{i}{j}{k});
                        phraseBox = bb(boxIdx,:);
                        labels{i}{j}{k} = getIOU(box,phraseBox) >= conf.posThresh;
                    end
                end
            end
        end

        function imageBoxIdx = phraseBoxToImageBox(imData,imNumber,phraseBoxes)
        %PHRASEBOXTOIMAGEBOX returns a mapping from a phrase candidate box
        %to the list of boxes in the member variable for that image
        %   inputs
        %       imData - this instance of an ImageSetData object
        %       imNumber - index of the desired image to provide a mapping
        %                  for
        %       phraseBoxes - candidate boxes for a phrase
        %   outputs
        %       imageBoxIdx - indices of the boxes member variable for each
        %                     box in phraseBoxes
            bb = imData.getBoxes(imNumber);
            if size(bb,1) == size(phraseBoxes,1) || isempty(phraseBoxes)
                imageBoxIdx = 1:size(bb,1);
                return;
            end
            imageBoxIdx = zeros(size(phraseBoxes,1),1);
            for b = 1:size(phraseBoxes)
                [~,~,imageBoxIdx(b)] = intersect(phraseBoxes(b,:),bb,'rows');
                assert(isempty(find(phraseBoxes(b,:) ~= bb(imageBoxIdx(b),:),1)));
            end
        end
        
        function features = scoreMatrix2Features(imData,scores,boxes)
        %SCOREMATRIX2FEATURES takes scores computed over different cues and
        %combines them into a single matrix
        %   inputs
        %       imData - this instance of an ImageSetData object
        %       scores - M x N cell array where M is the number of images
        %                and N is the number of cues
        %       boxes - candidate boxes for each phrase
        %   outputs
        %       features - condensed version of scores, where each cue is
        %                  combined (i.e. returns a M x 1 cell array)
            batchSize = 2000;
            nBatches = ceil(imData.nImages/batchSize);
            features = cell(nBatches,1);
            for batch = 1:batchSize:imData.nImages
                fprintf('scoreMatrix2Features: batch %i of %i\n',batch,nBatches);
                batchEnd = min(batch+batchSize-1,imData.nImages);
                imagefns = imData.imagefns(batch:batchEnd);
                imagedir = imData.imagedir;
                ext = imData.ext;
                stopwords = imData.stopwords;
                batchData = ImageSetData(imData.split,imagefns,imagedir,ext,stopwords);
                batchData.phrase = imData.phrase(batch:batchEnd);
                batchData.relationship = imData.phrase(batch:batchEnd);
                batchData.annotations = imData.annotations(batch:batchEnd);
                batchData.boxes = imData.boxes(batch:batchEnd);
                batchScores = scores(batch:batchEnd,:);
                batchBoxes = [];
                if ~isempty(boxes)
                    batchBoxes = boxes(batch:batchEnd);
                end
                batchFeatures = cell(batchData.nImages,1);
                parfor i = 1:batchData.nImages
                    batchFeatures{i} = cell(batchData.nSentences(i),1);
                    for j = 1:batchData.nSentences(i)
                        batchFeatures{i}{j} = cell(batchData.nPhrases(i,j),1);
                        for k = 1:batchData.nPhrases(i,j)
                            phraseFeatures = cell(size(batchScores,2),1);
                            boxIdx = batchData.phraseBoxToImageBox(i,batchBoxes{i}{j}{k});
                            for f = 1:size(batchScores,2)
                                s = batchScores{i,f}{j}{k};
                                if length(boxIdx) == length(s)
                                    phraseFeatures{f} = s;
                                else
                                    phraseFeatures{f} = s(boxIdx,:);
                                end
                            end
                            
                            batchFeatures{i}{j}{k} = horzcat(phraseFeatures{:});
                        end
                    end
                end

                features{batch} = batchFeatures;
            end

            features = vertcat(features{:});
            assert(length(features) == imData.nImages);
        end

        function filterNonvisualPhrases(imData)
        %FILTERNONVISUALPHRASES removes phrases and relationships from this
        %instance which do not have a ground truth bounding box
        %   inputs
        %       imData - this instance of an ImageSetData object
            noVisualPhrases = false(imData.nImages,1);
            for i = 1:imData.nImages
                for j = 1:imData.nSentences(i)
                    visualPhrase = false(imData.nPhrases(i,j),1);
                    for k = 1:imData.nPhrases(i,j)
                        visualPhrase(k) = ~isempty(imData.getPhraseGT(i,j,k));
                    end

                    if isempty(imData.relationship),continue,end

                    visualPhrase = find(visualPhrase);
                    newPhraseIdx = zeros(1,imData.nPhrases(i,j));
                    newPhraseIdx(visualPhrase) = 1:length(visualPhrase);
                    imData.phrase{i}{j} = imData.phrase{i}{j}(visualPhrase);
                    keepRelationship = true(imData.nRelationships(i,j),1);
                    for k = 1:imData.nRelationships(i,j)
                        leftIdx = newPhraseIdx(imData.relationship{i}{j}(k).leftPhrase);
                        if leftIdx > 0
                            imData.relationship{i}{j}(k).leftPhrase = leftIdx;
                        else
                            imData.relationship{i}{j}(k).leftPhrase = [];
                            imData.relationship{i}{j}(k).leftPronoun = [];
                        end

                        rightIdx = newPhraseIdx(imData.relationship{i}{j}(k).rightPhrase);
                        if rightIdx > 0
                            imData.relationship{i}{j}(k).rightPhrase = rightIdx;
                        else
                            imData.relationship{i}{j}(k).rightPhrase = [];
                            imData.relationship{i}{j}(k).rightPronoun = [];
                        end

                        keepRelationship(k) = ~isempty(imData.relationship{i}{j}(k).leftPhrase) || ~isempty(imData.relationship{i}{j}(k).rightPhrase);
                    end

                    imData.relationship{i}{j} = imData.relationship{i}{j}(keepRelationship);
                end
                
                noVisualPhrases(i) = isempty(find(~cellfun(@isempty,imData.phrase{i}),1));
            end
            
            imData.imagefns(noVisualPhrases) = [];
            imData.phrase(noVisualPhrases) = [];
            if ~isempty(imData.relationship)
                imData.relationship(noVisualPhrases) = [];
            end
            if ~isempty(imData.annotations)
                imData.annotations(noVisualPhrases) = [];
            end
            if ~isempty(imData.boxes)
                imData.boxes(noVisualPhrases) = [];
            end
        end
    end
end

