classdef Phrase < handle
%PHRASE base class containing functions and member variables shared between
%the Entity and Relationship classes
    properties (SetAccess = private)
        % cell array of strings containing the words of this phrase in
        % order of their appearance in the sentence
        words = {};
        
        % parts of speech of each of the words in this phrase
        pos = {};
        
        % scalar indicating the position of this phrase in the sentence
        sentencePosition = [];
    end
    
    methods
        function phrase = Phrase(words,pos,sentencePosition)
            if nargin > 0
                phrase.pos = pos;
                phrase.words = words;
                phrase.sentencePosition = sentencePosition;
            end
        end
        
        function words = getPhraseString(phrase,stopwords,tag)
        %GETPHRASESTRING returns a character array representation of this phrase
        %   inputs
        %       phrase - this phrase instance
        %       stopwords - optional, cell array of stopwords to remove
        %       tag - optional, cell array of POS tags to keep
        %   outputs
        %       words - character array representation of this phrase,
        %               where the individual words are delimited by a '+'
            if nargin < 2
                words = strcatWithDelimiter(phrase.words,'+');
            else
                if isempty(stopwords) || length(phrase.words) == 1
                    notStopwords = true(length(phrase.words),1);
                else
                    notStopwords = cellfun(@(f)isempty(find(strcmpi(f,stopwords),1)),phrase.words);
                end

                words = phrase.words(notStopwords);
                if nargin > 2 || isempty(find(notStopwords,1))
                    if nargin < 3
                        tag = {'JJ','NN'};
                    end

                    pos = phrase.pos(notStopwords);
                    if isempty(pos)
                        pos = phrase.pos;
                        words = phrase.words;
                    end
  
                    isTag = false(length(pos),1);
                    for i = 1:length(pos)
                        for j = 1:length(tag)
                            isTag(i) = strncmp(pos{i},tag{j},length(tag{j}));
                            if isTag(i),break,end
                        end
                    end

                    words = words(isTag);
                end
                
                words = strcatWithDelimiter(words,'+');
            end
            
            if ~isempty(words)
                words = lower(words);
            end
        end
    end
    
end

