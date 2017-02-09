classdef PairPhraseCue < Cue
%PAIRPHRASECUE generic base class for pair phrase cues
%   This class contains shared code across all apir phrase cues as well as
%   functions with the assumed interface across all these cues.
%
%   Documentation for class member variables and functions not provided
%   here are located in the superclass they are originally defined in.
    methods
        function ppc = PairPhraseCue(cueLabel,svm,classes)
            label = [];
            model = [];
            dictionary = [];
            if nargin > 0
                label = cueLabel;
                model = svm;
                dictionary = classes;
            end

            ppc = ppc@Cue(label,model,dictionary);
        end

        function trainModel(cue,imData,spcScores,maxTrainSamples,trainPosThresh)
        %trainModel(cue,imageInfo,spcScores,maxTrainSamples,trainPosThresh)
        %   Trains svm and platt scaling models for the instance's cue
        %   categories.
        %      cue - PairPhraseCue instance
        %      imData - ImageSetData instance with the training set's data
        %      spcScores - contains the single phrase cue scores for all
        %                  phrases in the dataset (see pairPhraseCueFeatures
        %                  for format)
        %      maxTrainSamples - maximum number of positive or negative
        %                        samples to use during training
        %      trainPosThresh - minimum IOU threshold for a sample to be 
        %                       considered a positive example
            features = cell(imData.nImages,1);
            parfor i = 1:imData.nImages
                features{i} = cell(imData.nSentences(i),1);
                for j = 1:imData.nSentences(i)
                    features{i}{j} = cell(imData.nRelationships(i,j),1);
                    for k = 1:imData.nRelationships(i,j)
                        relationship = imData.getRelationship(i,j,k);
                        leftPhrase = imData.getPhrase(i,j,relationship.leftPhrase);
                        rightPhrase = imData.getPhrase(i,j,relationship.rightPhrase);
                        cueClass = cue.getCueCategory(leftPhrase,rightPhrase,relationship,imData.stopwords);
                        if isempty(cueClass),continue,end
                        gtLeft = imData.getPhraseGT(i,j,relationship.leftPhrase);
                        if isempty(gtLeft),continue,end
                        gtRight = imData.getPhraseGT(i,j,relationship.rightPhrase);
                        if isempty(gtRight),continue,end
                        relativePosition = pairPhraseCueFeatures(imData,relationship,spcScores,i,j,gtLeft,gtRight);
                        features{i}{j}{k} = cell(1,length(cue.dictionary.words));
                        for c = 1:length(cueClass)
                            class = cueClass(c);
                            features{i}{j}{k}{class} = relativePosition;
                        end
                    end
                end
            end
            
            cue.model = trainLibSVMClassifier(features,maxTrainSamples,trainPosThresh);
        end

        function scores = scoreRelationship(cue,imData,spcScores)
        %SCORERELATIONSHIP scores all relationships for this cue
        %   inputs
        %       cue - this instance of a SinglePhraseCue object
        %       imData - ImageSetData instance
        %       spcScores - cell array of the single phrase cue scores of 
        %                   all phrases of the imageInfo object
        %   outputs
        %       scores - cell array containing the scores of every
        %                relationship in the imageInfo instance
            scores = cell(imData.nImages,1);
            parfor i = 1:imData.nImages
                scores{i} = cell(imData.nSentences(i),1);
                for j = 1:imData.nSentences(i)
                    scores{i}{j} = cell(imData.nRelationships(i,j),1);
                    for k = 1:imData.nRelationships(i,j)
                        relationship = imData.getRelationship(i,j,k);
                        leftPhrase = imData.getPhrase(i,j,relationship.leftPhrase);
                        rightPhrase = imData.getPhrase(i,j,relationship.rightPhrase);
                        cueClass = cue.getCueCategory(leftPhrase,rightPhrase,relationship,imData.stopwords);
                        if isempty(cueClass),continue,end
                        relativePosition = pairPhraseCueFeatures(imData,relationship,spcScores,i,j);
                        relativePosition = sparse(double(relativePosition));
                        labels = zeros(size(relativePosition,1),1);
                        modelScores = zeros(size(relativePosition,1),length(cueClass),'single');
                        for c = 1:length(cueClass)
                            svmScores = svmpredict(labels,relativePosition,cue.model{c}.svm,'-q');
                            modelScores(:,c) = predict(cue.model{c}.prob,svmScores);
                        end

                        modelScores = mean(modelScores,2) + eps('single');
                        modelScores = -log(modelScores);
                        nLeft = length(spcScores{i}{j}(relationship.leftPhrase).boxIdx);
                        scores{i}{j}{k} = reshape(modelScores,[],nLeft)';
                    end
                end
            end
        end
    end

    methods (Abstract)
        cueClass = getCueCategory(cue,phraseLeft,phraseRight,relationship,stopwords);
        %GETCUECATEGORY returns the cue classes which are applicable to a
        % pair of phrases
        %   inputs
        %       cue - this instance of a PairPhraseCue object
        %       phraseLeft - an Entity instance of the left phrase of the
        %                    relationship
        %       phraseRight - an Entity instance of the right phrase of the
        %                     relationship
        %       relationship - pair phrase relationship to check if a cue
        %                      is applicable to
        %       stopwords - cell array of stopwords
        %   outputs
        %       cueClass - array of cue categories applicable to the input
        %                  relationship
    end
end

