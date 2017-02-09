function inSequence = isRelationInSequence(relation1,relation2)
%ISRELATIONINSEQUENCE returns an indicator if the two input relationships
%directly follow each other in the sentence
    isLeftSame =  arePhrasesSame(relation1.leftPhrase,relation2.leftPhrase);
    isRightSame =  arePhrasesSame(relation1.rightPhrase,relation2.rightPhrase);
    isSamePhrases = isLeftSame && isRightSame;
    if relation1.sentencePosition < relation2.sentencePosition
        inSequence = and(isSamePhrases,relation1.sentencePosition+length(relation1.words) == relation2.sentencePosition);
    else
        inSequence = and(isSamePhrases,relation2.sentencePosition+length(relation2.words) == relation1.sentencePosition);
    end
end

function isPhraseSame = arePhrasesSame(phrase1,phrase2)
    if isempty(phrase1)
        isPhraseSame = isempty(phrase2);
    elseif isempty(phrase2)
        isPhraseSame = false;
    else
        isPhraseSame = phrase1 == phrase2;
    end
end


