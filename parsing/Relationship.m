classdef Relationship < Phrase
%RELATIONSHIP subject-verb and verb-object single phrase cue
%   This class scores any suitable phrase's bounding boxes for the
%   subject-verb and verb-object single phrase cues.
%
%   Documentation for class member variables and functions not provided
%   here are located in the superclass they are originally defined in.
    properties (SetAccess = public)
        leftPhrase = [];
        rightPhrase = [];
        leftPronoun = [];
        rightPronoun = [];
    end
    
    methods
        function relationship = Relationship(inWords,inPos,firstWordIdx,leftPhraseIdx,rightPhraseIdx)
            words = [];
            pos = [];
            sentencePosition = [];
            if nargin > 0
                pos = inPos;
                words = inWords;
                sentencePosition = firstWordIdx;
            end
            relationship = relationship@Phrase(words,pos,sentencePosition);
            if nargin > 0
                relationship.leftPhrase = leftPhraseIdx;
                relationship.rightPhrase = rightPhraseIdx;
            end
        end
        
        function isCoref = isPronounCoref(relationship,leftPhrase)
            if nargin < 2 || isempty(leftPhrase) || leftPhrase
                isCoref = ~isempty(relationship.leftPronoun);
                if nargin < 2 || isempty(leftPhrase)
                    isCoref = or(isCoref,~isempty(relationship.rightPronoun));
                end
            else
                isCoref = ~isempty(relationship.rightPronoun);
            end
        end

        function setCoref(relationship,pronoun,reference)
            if and(~isempty(relationship.leftPhrase),relationship.leftPhrase == pronoun)
                relationship.leftPhrase = reference;
                relationship.leftPronoun = pronoun;
            end
            if and(~isempty(relationship.rightPhrase),relationship.rightPhrase == pronoun)
                relationship.rightPhrase = reference;
                relationship.rightPronoun = pronoun;
            end
        end
    end
end

