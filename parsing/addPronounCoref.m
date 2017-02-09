function relationship = addPronounCoref(imagefns,sentenceData,relationship,pronounFile)
%ADDPRONOUNCOREF parses a csv file with pronoun coreference information 
%and adds this information to pair phrase relationship objects
%   inputs
%       imagefns - a cell array of image identifiers, elements should be
%                  in the same order as the relationship variable
%       sentenceData - a FlickrSentenceData object
%       relationship - cell array of pair phrase relationship objects
%       pronounFile - csv file with the coreference information, see 
%                     data/flickr30k/pronomCoref_v1.csv for format
%   outputs
%       relationship - updated pair phrase relationships
    corefs = strsplit(fileread(pronounFile),'\n');
    corefs(cellfun(@isempty,corefs)) = [];
    % first index is a header
    corefs(1) = [];
    corefs = cellfun(@(f)strsplit(f,','),corefs,'UniformOutput',false);
    corefFN = cellfun(@(f)strsplit(f{1},'#'),corefs,'UniformOutput',false);
    sentNum = cellfun(@(f)str2double(f{2})+1,corefFN);
    corefFN = cellfun(@(f)strrep(f{1},'.jpg',''),corefFN,'UniformOutput',false);

    corefMatches = cellfun(@(f)~isempty(find(strcmp(f,imagefns),1)),corefFN);
    corefFN = corefFN(corefMatches);
    sentNum = sentNum(corefMatches);
    corefs = corefs(corefMatches);
    
    corefPronounWords = 2;
    corefPronounIdx = 4;
    corefReferenceWords = 6;
    corefReferenceIdx = 8;
    for i = 1:length(corefFN)
        proIdxStr = corefs{i}{corefPronounIdx};
        proWords = corefs{i}{corefPronounWords};
        proIdx = getPhraseIdx(proIdxStr,proWords,sentenceData,corefFN{i},sentNum(i));
        if isempty(proIdx),continue,end
        refIdxStr = corefs{i}{corefReferenceIdx};
        refWords = corefs{i}{corefReferenceWords};
        refIdx = getPhraseIdx(refIdxStr,refWords,sentenceData,corefFN{i},sentNum(i));
        if isempty(refIdx),continue,end

        imIdx = find(strcmp(corefFN{i},imagefns));
        for j = 1:length(relationship{imIdx}{sentNum(i)})
            relationship{imIdx}{sentNum(i)}(j).setCoref(proIdx,refIdx);
        end
    end
end

function phraseIdx = getPhraseIdx(tokenIdxStr,phrase,sentenceData,imageID,sentNum)
    tokenIdx = str2double(tokenIdxStr)+1;
    [phraseIdx,expectedPhrase] = sentenceData.findPhraseByWordTokenIdx(tokenIdx,imageID,sentNum);
    if ~strcmpi(expectedPhrase,phrase)
        phraseIdx = [];
    end
end



