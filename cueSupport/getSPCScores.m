function [imData,scores,boxes] = getSPCScores(conf,imData,spc,updateBoxes)
%GETSPCSCORES scores the images in imData using the given single phrase cues
%   inputs
%       conf - configuration settings (e.g. output of plClcConfig)
%       imData - an ImageSetData object instance
%       spc - a cell array of single phrase cues
%       updateBoxes - logical array the same length of spc that is true 
%                     when that cue updates the initial set of candidate 
%                     boxes
%   outputs
%       imData - an ImageSetData object instance which may have updated 
%                member variables
%       scores - a M x N cell array of cue scores where M is the number of 
%                images and N is the number of cues
%       boxes - a cell array which contains the candidate boxes for each
%               phrase
    imData.filterNonvisualPhrases;
    boxUpdateCues = find(updateBoxes);
    if length(boxUpdateCues) > 1
        error('getSPCScores: current code assumes that, at most, one cue updates boxes');
    end
    scores = cell(imData.nImages,length(spc));
    if ~isempty(boxUpdateCues)
        [scores(:,boxUpdateCues),boxes] = scoreCue(conf,imData,spc{boxUpdateCues});
        for i = 1:length(imData.imagefns)
            allBoxes = vertcat(boxes{i}{:});
            allBoxes = unique(vertcat(allBoxes{:}),'rows');
            imData.boxes{i} = allBoxes;
        end
    else
        boxes = [];
    end
    
    for i = 1:length(spc)
        if updateBoxes(i),continue,end
        scores(:,i) = scoreCue(conf,imData,spc{i});
    end
    
    scores = imData.scoreMatrix2Features(scores,boxes);
end

function [scores,boxes] = scoreCue(conf,imData,cue)
    cachedir = fullfile(conf.cachedir,imData.split);
    if conf.cacheCueScores
        [scores,boxes] = cue.loadCueScores(cachedir);
    else
        scores = [];
        boxes = [];
    end

    saveFile = isempty(scores) && conf.cacheCueScores;
    if isempty(scores)
        [scores,boxes] = cue.scorePhrase(imData);
    end

    if saveFile
        cue.saveCueScores(cachedir,scores,boxes);
    end
end

