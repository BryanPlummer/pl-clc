function [words,isPeople] = getPhraseWords(phrase,stopwords)
%GETPHRASEWORDS returns all the string representation for a phrase
%   inputs
%       phrase - Entity instance to extract the character representation of
%       stopwords - cell array of common words to remove
%   outputs
%       words - string representation fo the Entity instance
%       isPeople - indicator of whether this is a person Entity
    if isempty(phrase)
        words = [];
        isPeople = [];
        return;
    end
    personType = 'people';
    nounTag = {'NN'};
    adjectiveTag = {'JJ'};
    falseTags = {'VB','FW','RB'};
    isPeople = ~isempty(phrase.groupTypeMatches(personType));
    if isPeople
        words = personType;
    else
        if length(phrase.words) == 1
            words = lower(phrase.words{1});
        else
            words = phrase.getPhraseString([],nounTag);
            if isempty(words)
                words = phrase.getPhraseString([],falseTags);
                if isempty(words)
                    words = phrase.getPhraseString([],adjectiveTag);
                    if isempty(words)
                        words = phrase.getPhraseString(stopwords);
                    end
                end
            end
        end
    end
end