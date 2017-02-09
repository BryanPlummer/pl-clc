classdef FlickrSentenceData < handle
%FLICKRSENTENCEDATA sentence data from Flickr30k Entities
%   This class reads and stores the text annotations from Flickr30k
%   Entities and provides some variations on the accessor methods to that
%   data.
    properties
        textAnnotations = containers.Map;
        annodir = [];
    end
    
    methods
        function flickrSent = FlickrSentenceData(annodir)
            flickrSent.annodir = annodir;
        end
        
        function textAnnos = getTextAnnotations2(flickrSent,imageID)
        %GETTEXTANNOTATIONS2 returns the sentence data for a particular
        %image in the Flickr30k Entities dataset
        %   inputs
        %       flickrSent - this instance of the FlickrSentenceData object
        %       imageID - an identifier for an image in the Flickr30k
        %                 Entities dataset
        %   outputs
        %       textAnnos - the structs from the getSentenceData function
        %                   from the released version of Flickr30k Entities
        %flickrSent.setTextAnnotations({imageID});
            if ~flickrSent.textAnnotations.isKey(imageID)
                annofn = fullfile(flickrSent.annodir,'Sentences',strcat(imageID,'.txt'));
                flickrSent.textAnnotations(imageID) = getSentenceData(annofn);
            end
            textAnnos = flickrSent.textAnnotations(imageID);
        end

        function [phraseIdx,phrase] = findPhraseByWordTokenIdx(flickrSent,tokenIdx,imageID,sentNum)
        %FINDPHRASEBYWORDTOKENIDX returns the sentence data for a particular
        %image in the Flickr30k Entities dataset
        %   inputs
        %       flickrSent - this instance of the FlickrSentenceData object
        %       tokenIdx - index of the token of the first word of a phrase
        %       imageID - an identifier for an image in the Flickr30k
        %                 Entities dataset
        %       sentNum - the sentence number (1-5) where the desired
        %                 phrase is in
        %   outputs
        %       phraseIdx - the index of the noun phrase in the annotated
        %                   phrases (i.e. the index in the sentence data
        %                   structure in the list of phrases)
        %       phrase - a character representation of the desired phrase
            textAnnos = flickrSent.getTextAnnotations2(imageID);
            textAnnos = textAnnos(sentNum);
            phraseIdx = find(tokenIdx == textAnnos.phraseFirstWordIdx);
            if length(phraseIdx) == 1
                phrase = strcatWithDelimiter(textAnnos.phrases{phraseIdx});
            else
                phraseIdx = [];
                phrase = [];
            end
        end

        function [phrases,entityID,groups,sentence] = getTextAnnotations(flickrSent,imageIDs)
            textAnnos = cellfun(@(f)flickrSent.getTextAnnotations2(f),imageIDs,'UniformOutput',false);
            phrases = cellfun(@(f){f.phrases},textAnnos,'UniformOutput',false);
            entityID = cellfun(@(f){f.phraseID},textAnnos,'UniformOutput',false);
            groups = cellfun(@(f){f.phraseType},textAnnos,'UniformOutput',false);
            sentence = cellfun(@(f){f.sentence},textAnnos,'UniformOutput',false);
        end

        function setTextAnnotations(flickrSent,imageIDList)
            notSet = cellfun(@(f)~flickrSent.textAnnotations.isKey(f),imageIDList);
            imageIDList = imageIDList(notSet);
            for i = 1:length(imageIDList)
                imageID = imageIDList{i};
                annofn = fullfile(flickrSent.annodir,'Sentences',strcat(imageID,'.txt'));
                flickrSent.textAnnotations(imageID) = getSentenceData(annofn);
            end
        end
    end 
end

