classdef SinglePhraseCue < Cue
%SINGLEPHRASECUE generic base class for single phrase cues
%   This class contains shared code across all single phrase cues as well
%   as functions with the assumed interface across all these cues.
%
%   Documentation for class member variables and functions not provided
%   here are located in the superclass they are originally defined in.
    methods
        function cue = SinglePhraseCue(cueLabel,cueModel,classes)
            label = [];
            model = [];
            dictionary = [];
            if nargin > 0
                label = cueLabel;
                model = cueModel;
                dictionary = classes;
            end

            cue = cue@Cue(label,model,dictionary);
        end
        
        function labels = classLabels(cue)
        %CLASSLABELS(cue) returns a cell array of category labels for a cue
            if iscell(cue.dictionary)
                if iscell(cue.dictionary{1})
                    labels = cellfun(@(f)f{1},cue.dictionary,'UniformOutput',false);
                else
                    labels = cue.dictionary;
                end
            else
                labels = cell(length(cue.dictionary.words),1);
                for i = 1:length(cue.dictionary.words)
                    labels{i} = cue.dictionary.words{i}{1};
                    if ~isempty(cue.dictionary.types) && ~isempty(cue.dictionary.types{i})
                        isSubjectRestricted = cue.isCueSubjectRestricted();
                        if isempty(isSubjectRestricted) || isSubjectRestricted
                            labels{i} = strcat(cue.dictionary.types{i},'_',labels{i});
                        else
                            labels{i} = strcat(labels{i},'_',cue.dictionary.types{i});
                        end
                    end
                end
            end
        end
        
        function isSubjectRestricted = isCueSubjectRestricted(cue)
        %isCueSubjectRestricted(cue) returns if the cue is limited to
        %   the subject in a relational phrase (used in VerbDetector)
            isSubjectRestricted = [];
        end

        function catchall = isCueCategoryCatchall(cue,cueClass)
        %isCueCategoryCatchall(cue) returns if the cue class was meant
        %   to be used on phrases for which a phrase-specific model wasn't
        %   trained for (e.g. as used in VerbDetector)
            catchall = false(length(cueClass),1);
        end
    end

    methods (Abstract)
        cueClass = getCueCategory(cue,phrase,relationship,stopwords);
        %GETCUECATEGORY returns the cue classes which are applicable to a
        % particular phrase
        %   inputs
        %       cue - this instance of a SinglePhraseCue object
        %       phrase - phrase to check if a cue is applicable
        %       relationship - pair phrases returned from parsing the 
        %                      phrase's associated sentence
        %       stopwords - cell array of stopwords
        %   outputs
        %       cueClass - array of cue categories applicable to the input
        %                  phrase
        
        [scores,boxes] = scorePhrase(cue,imData);
        %SCOREPHRASE scores all phrases for this cue and also returns any
        % updated boxes the cue may provide.
        %   inputs
        %       cue - this instance of a SinglePhraseCue object
        %       imData - ImageSetData instance 
        %   outputs
        %       scores - cell array containing the scores of every phrase
        %                in the imageInfo instance
        %       boxes - cell array containing any updated boxes for the
        %               associated scores
    end
end

