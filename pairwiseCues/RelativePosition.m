classdef RelativePosition < PairPhraseCue & DataDefinedClasses
%RELATIVEPOSITION verb and prepositional pair phrase cue
%   This class scores pairs of phrases associated with commonly
%   occurring categories for that cue.
%
%   Documentation for class member variables and functions not provided
%   here are located in the superclass they are originally defined in.
    methods
        function cue = RelativePosition(cueLabel,svm,classes)
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
            classes = containers.Map;
            stopwords = imData.stopwords;
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
                    for k = 1:length(cueClass)
                        relationWords = cue.dictionary.words{cueClass(k)};
                        classLabel = strcatWithDelimiter({leftWords,relationWords{1},rightWords},'_');
                        if classes.isKey(classLabel)
                            item = classes(classLabel);
                        else
                            item = [];
                            item.nInstances = 0;
                            item.classVariants = [];
                            if length(relationWords) > 1
                                item.classVariants = relationWords(2:end);
                            end
                        end
                        
                        item.nInstances = item.nInstances + 1;
                        classes(classLabel) = item;    
                    end
                end
            end

            outfn = fullfile(conf.dictionarydir,strcat(cue.cueLabel,'.txt'));
            writeRestrictedClasses(classes,conf.minNumInstances,outfn);
        end

        function cueClass = getCueCategory(cue,leftPhrase,rightPhrase,relationship,stopwords)
            cueClass = [];
            [leftWords,isLeftPeople] = getPhraseWords(leftPhrase,stopwords);
            if isempty(leftWords),return,end
            rightWords = getPhraseWords(rightPhrase,stopwords);
            if isempty(rightWords),return,end
            
            % skip pairs of phrases being handled by the ClothingBP cue
            clothingBPType = {'clothing','bodyparts'};
            if isLeftPeople && ~isempty(rightPhrase.groupTypeMatches(clothingBPType)),return,end

            relationWords = cue.dictionary.words;
            phraseWords = cue.dictionary.types;
            cueClass = false(length(relationWords),1);
            for i = 1:length(relationWords)
                cueClass(i) = ~isempty(find(cellfun(@(f)~isempty(find(strcmpi(f,relationWords{i}),1)),relationship.words),1));
                if isempty(phraseWords) || isempty(phraseWords{i}),continue,end
                if ~cueClass(i),continue,end
                cueClass(i) = strcmp(phraseWords{i}{1},leftWords);
                if ~cueClass(i),continue,end
                cueClass(i) = strcmp(phraseWords{i}{2},rightWords);
            end

            cueClass = find(cueClass);
        end
    end
end

