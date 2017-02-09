function [relationship,phrase] = sentenceParse(inArgs)
%SENTENCEPARSE parses the input sentences using the Stanford parser
%   inputs
%       inArgs - struct containing the data to identify the sentences to
%                parse
%   outputs
%       relationship - cell array containing the pair phrase relationships
%                      in the parsed sentences
%       phrase - cell array of Entity objects containing the noun phrases
%                in the parsed sentences
    parser = StanfordParser;
    flickrSent = FlickrSentenceData(inArgs.annodir);
    [phrases,entityID,groups,sentence] = flickrSent.getTextAnnotations(inArgs.imageID);
    relationship = cell(length(phrases),1);
    phrase = cell(length(phrases),1);
    for i = 1:length(phrases)
        relationship{i} = cell(length(sentence{i}),1);
        phrase{i} = cell(length(sentence{i}),1);
        for j = 1:length(sentence{i})
            [relationship{i}{j},phrase{i}{j}] = parser.extractAllSentenceData(sentence{i}{j},phrases{i}{j},entityID{i}{j},groups{i}{j});
        end
    end

    relationship = addPronounCoref(inArgs.imageID,flickrSent,relationship,inArgs.pronounFile);
end

