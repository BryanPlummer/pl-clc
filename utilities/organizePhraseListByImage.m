function imageList = organizePhraseListByImage(phraseList)
%ORGANIZEPHRASELISTBYIMAGE takes the output of getPHraseLists function and
%reorganizes it by image
%   inputs
%       phraseList - containers.Map object where each key is a phrase and
%                    the values are the imageIDs and boxes associated with
%                    the phrase
%   outputs
%       imageList - containers.Map object where each key is an imageID and
%                   the values are the bounding boxes associated with that
%                   image
    imageList = containers.Map;
    phrase = phraseList.keys();
    for i = 1:length(phrase)
        instances = phraseList(phrase{i});
        for j = 1:length(instances)
            imageID = instances(j).imageID;
            if imageList.isKey(imageID)
                boxes = imageList(imageID);
            else
                boxes = [];
            end

            imageList(imageID) = unique([boxes;instances(j).box],'rows');
        end
    end
end

