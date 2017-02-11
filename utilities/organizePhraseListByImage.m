function imData = organizePhraseListByImage(imData,phraseList)
%ORGANIZEPHRASELISTBYIMAGE takes the output of getPHraseLists function and
%reorganizes it by image
%   inputs
%       imData - an ImageSetData object
%       phraseList - containers.Map object where each key is a phrase and
%                    the values are the imageIDs and boxes associated with
%                    the phrase
%   outputs
%       imData - an ImageSetData object where its boxes have been
%                replaced with those from the phrase list
    imData.boxes = cell(imData.nImages,1);
    phrase = phraseList.keys();
    for i = 1:length(phrase)
        instances = phraseList(phrase{i});
        for j = 1:length(instances)
            imageID = instances(j).imageID;
            imIdx = find(strcmp(imageID,imData.imagefns),1);
            assert(~isempty(imIdx));

            imData.boxes{imIdx} = unique([imData.boxes{imIdx};instances(j).box],'rows');
        end
    end

    noBoxes = cellfun(@isempty,imData.boxes);
    imData.boxes(noBoxes) = [];
    imData.imagefns(noBoxes) = [];
    imData.annotations(noBoxes) = [];
    imData.phrase(noBoxes) = [];
    imData.relationship(noBoxes) = [];
end

