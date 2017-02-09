classdef RegionPhraseCCA < SinglePhraseCue
%REGIONPHRASECCA phrase-region model cue using a cca embedding
%   This class scores bounding boxes using a cca embedding between image
%   and text features.
%
%   Documentation for class member variables and functions not provided
%   here are located in the superclass they are originally defined in.
    properties (SetAccess = public)
        % Full file path for the weights used to compute features for this
        % cca model.
        featModel = [];
        
        % Full file path for the prototxt used to compute features for this
        % cca model.
        featDef = [];
    end
    
    methods
        function cue = RegionPhraseCCA(cueLabel,cca_m,featModel,featDef)
            label = [];
            model = [];
            dictionary = [];
            if nargin > 0
                cca_m.set_apply_r(true);
                label = cueLabel;
                model = cca_m;
            end

            cue = cue@SinglePhraseCue(label,model,dictionary);
            
            if nargin > 2
                cue.featModel = featModel;
                cue.featDef = featDef;
            end
        end

        function cueClass = getCueCategory(cue,phrase,relationship,stopwords)
            cueClass = 1;
        end

        function [scores,boxes] = scorePhrase(cue,imData)
            boxes = [];
            batchSize = 5000;
            nBatches = ceil(imData.nImages/batchSize);
            scores = cell(nBatches,1);
            for batch = 1:batchSize:imData.nImages
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
                
                phraseWords = batchData.getPhraseWords();
                uniquePhrases = vertcat(phraseWords{:});
                uniquePhrases = vertcat(uniquePhrases{:});
                uniquePhrases(cellfun(@isempty,uniquePhrases)) = [];
                uniquePhrases = unique(uniquePhrases);
                textFeats = getHGLMMFeatures(strrep(uniquePhrases,'+',' '));
                
                % adding a column of zeros for empty phrases
                textFeats = [textFeats,zeros(size(textFeats,1),1)];
                textFeats = cue.model.map(textFeats, true, true)';
                
                imageFeats = getFastRCNNFeatures(batchData,cue.featModel,cue.featDef);
                scores{batch} = cell(batchData.nImages,1);
                for i = 1:batchData.nImages
                    if mod(i,100) == 0
                        fprintf('cca batch %i of %i: processing %i of %i\n',batch,nBatches,i,batchData.nImages);
                    end
                    imFeats = imageFeats{i};
                    imFeats = cue.model.map(imFeats, false, true)';
                    scores{batch}{i} = cell(batchData.nSentences(i),1);
                    for j = 1:batchData.nSentences(i)
                        scores{batch}{i}{j} = cell(batchData.nPhrases(i,j),1);
                        for k = 1:batchData.nPhrases(i,j)
                            words = phraseWords{i}{j}{k};
                            if isempty(words)
                                wordFeats = textFeats(end,:);
                            else
                                wordFeats = textFeats(strcmp(words,uniquePhrases),:);
                            end
                            
                            scores{batch}{i}{j}{k} = pdist2(imFeats,wordFeats,'cosine');
                        end
                    end
                end
            end

            scores = vertcat(scores{:});
            assert(length(scores) == imData.nImages);
        end
    end
end

