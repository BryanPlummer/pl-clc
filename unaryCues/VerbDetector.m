classdef VerbDetector < Detector & DataDefinedClasses
%VERBDETECTOR subject-verb and verb-object single phrase cue
%   This class scores any suitable phrase's bounding boxes for the
%   subject-verb and verb-object single phrase cues.
%
%   Documentation for class member variables and functions not provided
%   here are located in the superclass they are originally defined in.
    properties (SetAccess = private)
        % flag identifying if an instance is a subject-verb or verb-object
        % detector
        isSubjectVerb = [];
    end
    
    methods
        function cue = VerbDetector(isSubjectVerb,cueLabel,net,def,classes)
            label = [];
            model = [];
            dictionary = [];
            modelDef = [];
            if nargin > 1
                label = cueLabel;
                model = net;
                modelDef = def;
                dictionary = classes;
            end

            cue = cue@Detector(label,model,modelDef,dictionary);
            if nargin > 0
                cue.isSubjectVerb = isSubjectVerb;
            end
        end
        
        function makeClasses(cue,conf,imData)
            phrase = vertcat(imData.phrase{:});
            relationship = vertcat(imData.relationship{:});
            stopwords = imData.stopwords;
            classes = containers.Map;
            for i = 1:length(relationship)
                for j = 1:length(relationship{i})
                    if cue.isCueSubjectRestricted()
                        relationPhrase = phrase{i}(relationship{i}(j).leftPhrase);
                    else
                        relationPhrase = phrase{i}(relationship{i}(j).rightPhrase);
                    end

                    if isempty(relationPhrase),continue,end

                    cueClass = cue.getCueCategory(relationPhrase,relationship{i}(j),stopwords);
                    if isempty(cueClass),continue,end
                    % increment instance counts, using first verb for each
                    % class in the dictionary as the label
               
                    for k = 1:length(cueClass)
                        verbs = cue.dictionary.words{cueClass(k)};
                        for l = 1:length(relationPhrase.groupType)
                            type = relationPhrase.groupType{l};
                            if cue.isCueSubjectRestricted()
                                classLabel = strcat(type,'_',verbs{1});
                            else
                                classLabel = strcat(verbs{1},'_',type);
                            end
                            if classes.isKey(classLabel)
                                item = classes(classLabel);
                            else
                                item = [];
                                item.nInstances = 0;
                                item.classVariants = [];
                                if length(verbs) > 1
                                    item.classVariants = verbs(2:end);
                                end
                            end
                            
                            item.nInstances = item.nInstances + 1;
                            classes(classLabel) = item;
                        end
                    end
                end
            end

            outfn = fullfile(conf.dictionarydir,strcat(cue.cueLabel,'.txt'));
            nClasses = writeRestrictedClasses(classes,conf.maxNumInstances,outfn,cue.dictionary.words);
            if cue.isCueSubjectRestricted()
                writeFastRCNNProto(nClasses,conf.subjectVerbProtodir);
            else
                writeFastRCNNProto(nClasses,conf.verbObjectProtodir);
            end
        end

        function isSubjectRestricted = isCueSubjectRestricted(cue)
            isSubjectRestricted = cue.isSubjectVerb;
        end

        function catchall = isCueCategoryCatchall(cue,cueClass)
            if isempty(cue.dictionary.types)
                catchall = false(length(cueClass),1);
            else
                catchall = cellfun(@isempty,cue.dictionary.types(cueClass));
            end
        end

        function [cueClass,wordMap] = getCueCategory(cue,phrase,relationship,stopwords)
            if isempty(relationship)
                cueClass = [];
                wordMap = [];
                return;
            end
            verbs = cue.dictionary.words;
            phraseTypes = cue.dictionary.types;
            cueClass = false(length(verbs),1);
            for i = 1:length(verbs)
                if ~isempty(phraseTypes) && ~isempty(phraseTypes{i})
                    cueClass(i) = ~isempty(find(strcmpi(phraseTypes{i},phrase.groupType),1));
                    if ~cueClass(i),continue,end
                end
                for j = 1:length(relationship)
                    cueClass(i) = ~isempty(find(cellfun(@(f)~isempty(find(strcmpi(f,verbs{i}),1)),relationship(j).words),1));
                    if cueClass(i),break,end
                end
            end

            cueClass = find(cueClass);
            % There isn't a head noun for these categories so any ordering
            % on wordMap isn't very useful, so just using the default.
            wordMap = cueClass;
        end
    end
end

