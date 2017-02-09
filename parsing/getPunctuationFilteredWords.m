function words = getPunctuationFilteredWords(words,maxNumWords,removeFromEnd)
    words = parseTreeToken2Words(words);
    words = cellfun(@removePunctuation,words,'UniformOutput',false);
    nWords = min(length(words),maxNumWords);
    if removeFromEnd
        words = words(1:nWords);
    else
        words = words(end-nWords+1:end);
    end
end