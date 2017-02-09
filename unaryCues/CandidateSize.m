classdef CandidateSize < SinglePhraseCue
%CANDIDATESIZE bounding box candidate size cue
%   This class computes the size of each candidate box, and the scoring
%   function returns a MxN matrix, where M is the number of boxes and N is
%   the number of phrase types for every phrase.  Only those phrase types
%   associated with a phrase have nonzero entries.
%
%   Documentation for class member variables and functions not provided
%   here are located in the superclass they are originally defined in.
    methods
        function cue = CandidateSize(cueLabel,classes)
            label = [];
            model = [];
            dictionary = [];
            if nargin > 0
                label = cueLabel;
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
        
        function [scores,boxes] = scorePhrase(cue,imData)
            boxes = [];
            scores = cell(imData.nImages,1);
            for i = 1:imData.nImages
                imDims = imData.imSize(i);
                imSize = imDims(1)*imDims(2);
                bb = imData.getBoxes(i);
                boxSize = 1 - boxSizeFeatures(bb,imSize);
                scores{i} = cell(imData.nSentences(i),1);
                for j = 1:imData.nSentences(i)
                    scores{i}{j} = cell(imData.nPhrases(i,j),1);
                    for k = 1:imData.nPhrases(i,j)
                        phrase = imData.getPhrase(i,j,k);
                        cueClass = cue.getCueCategory(phrase);
                        scores{i}{j}{k} = zeros(size(bb,1),length(cue.dictionary),'single');
                        for c = 1:length(cueClass)
                            scores{i}{j}{k}(:,cueClass(c)) = boxSize;
                        end
                    end
                end
            end
        end
    end
end

