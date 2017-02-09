function imageIdxWithCue = getImagesWithSinglePhraseCue(imData,cue)
%GETIMAGESWITHSINGLEPHRASECUE finds images that contain a single
%phrase cue
%   inputs
%       imData - an ImageSetData object
%       cue - a single phrase cue object
%   outputs
%       imageIdxWithCue - image indexes in imageInfo which contain 
%                         a single phrase cue
    imageIdxWithCue = false(imData.nImages,1);
    stopwords = imData.stopwords;
    isSubjectRestricted = cue.isCueSubjectRestricted;
    parfor i = 1:imData.nImages
        for j = 1:imData.nSentences(i)
            for k = 1:imData.nPhrases(i,j)
                box = imData.getPhraseGT(i,j,k);
                if isempty(box),continue,end
                relationship = imData.getRelationshipForPhrase(i,j,k,isSubjectRestricted);
                phrase = imData.getPhrase(i,j,k);
                imageIdxWithCue(i) = ~isempty(cue.getCueCategory(phrase,relationship,stopwords));
                if imageIdxWithCue(i),break,end
            end
            
            if imageIdxWithCue(i),break,end
        end
    end

    imageIdxWithCue = find(imageIdxWithCue);
end

