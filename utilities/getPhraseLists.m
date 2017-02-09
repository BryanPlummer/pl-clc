function phraseList = getPhraseLists(imData,groupNames)
%GETPHRASELISTS creates the categories the cue will learn
%   inputs
%       imData - an instance of ImageSetData
%       groupNames - cell array of phrase types
%   outputs
%       phraseList - a containers.map object where the keys are
%                    phrases and the values are all the bounding
%                    box annotations for that phrase
    phraseList = containers.Map;
    for i = 1:imData.nImages
        for j = 1:imData.nSentences(i)
            for k = 1:imData.nPhrases(i,j)
                p = imData.getPhrase(i,j,k).getPhraseString(imData.stopwords);
                if isempty(p)
                    p = 'NO_VALID_WORDS';
                end

                box = imData.getPhraseGT(i,j,k);
                if isempty(box),continue,end        
                if phraseList.isKey(p)
                    phraseBoxes = phraseList(p);
                else
                    phraseBoxes = [];
                end
                item = [];
                item.imageID = imData.imagefns{i};
                item.box = box;
                item.type = imData.getPhrase(i,j,k).groupTypeMatches(groupNames);
                
                phraseBoxes = [phraseBoxes;item];
                phraseList(p) = phraseBoxes;
            end
        end
    end
end
