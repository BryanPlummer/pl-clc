classdef ClothingBP < PairPhraseCue & DataDefinedClasses
%CLOTHINGBP clothing and body part attachment cue
%   This class scores how likely a pair of boxes hold a clothing and body
%   part attachment relationship with a person box.
%
%   Documentation for class member variables and functions not provided
%   here are located in the superclass they are originally defined in.
    methods
        function cue = ClothingBP(cueLabel,svm,classes)
            label = [];
            model = [];
            dictionary = [];
            if nargin > 0
                label = cueLabel;
                model = svm;
                dictionary = classes;
            end
            
            cue = cue@PairPhraseCue(label,model,dictionary);
        end
    end

    methods
        function makeClasses(cue,conf,imData)
            phrase = vertcat(imData.phrase{:});
            relationship = vertcat(imData.relationship{:});
            stopwords = imData.stopwords;
            classes = containers.Map;
            for i = 1:length(relationship)
                for j = 1:length(relationship{i})
                    leftPhrase = phrase{i}(relationship{i}(j).leftPhrase);
                    if isempty(leftPhrase),continue,end
                    rightPhrase = phrase{i}(relationship{i}(j).rightPhrase);
                    if isempty(rightPhrase),continue,end
                    cueClass = cue.getCueCategory(leftPhrase,rightPhrase,relationship{i}(j),stopwords);
                    if isempty(cueClass),continue,end
                    
                    leftWords = getPhraseWords(leftPhrase,stopwords);
                    rightWords = getPhraseWords(rightPhrase,stopwords);
                    classLabel = strcat(leftWords,'_',rightWords);
                    if classes.isKey(classLabel)
                        item = classes(classLabel);
                    else
                        item = [];
                        item.nInstances = 0;
                        item.classVariants = [];
                    end
                    
                    item.nInstances = item.nInstances + 1;
                    classes(classLabel) = item;    
                end            
            end
           
            outfn = fullfile(conf.dictionarydir,strcat(cue.cueLabel,'.txt'));
            writeRestrictedClasses(classes,conf.minNumInstances,outfn);
        end

        function cueClass = getCueCategory(cue,leftPhrase,rightPhrase,relationship,stopwords)
            cueClass = [];
            peopleType = {'people'};
            if isempty(leftPhrase) || isempty(leftPhrase.groupTypeMatches(peopleType)),return,end
            clothingBPType = {'clothing','bodyparts'};
            if isempty(rightPhrase) || isempty(rightPhrase.groupTypeMatches(clothingBPType)),return,end

            if isempty(cue.dictionary)
                cueClass = 1;
                return;
            end
            rightWords = getPhraseWords(rightPhrase,stopwords);
            attachmentWords = cue.dictionary.words;
            cueClass = false(length(attachmentWords),1);
            for i = 1:length(attachmentWords)
                cueClass(i) = ~isempty(find(strcmpi(rightWords,attachmentWords{i}),1));
            end

            cueClass = find(cueClass);
        end
    end
end

