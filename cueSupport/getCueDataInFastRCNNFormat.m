function [imdb,roidb] = getCueDataInFastRCNNFormat(imData,cue,dbfn)
%GETCUEDATAINFASTRCNNFORMAT creates the inputs for the faster rcnn
%code for a given cue
%   inputs
%       imData - an ImageSetData object
%       cue - a single phrase cue object to parse into the Faster
%             RCNN format
%       dbfn - filename to save the output data in
%   outputs
%       imdb - struct containing image data in the Faster RCNN format
%       roidb - struct containing bounding box data in the faster
%               RCNN format
    if exist(dbfn,'file')
        load(dbfn,'imdb','roidb');
    else
        imageIdxWithCue = getImagesWithSinglePhraseCue(imData,cue);
        imdb = getIMDB(imData,imageIdxWithCue,cue,dbfn);
        roidb = getROIDB(imData,imageIdxWithCue,cue,dbfn,imdb.num_classes);
        if nargin > 2
            save(dbfn,'imdb','roidb','-v7.3');
        end
    end
end

function roidb = getROIDB(imData,imageIdxWithCue,cue,dbfn,nClasses)
%GETROIDB creates the roidb for the faster rcnn code for a given cue
%   inputs
%       imData - an ImageSetData object
%       imageIdxWithCue - indices of images that contain the input cue
%       cue - a single phrase cue object to parse into the Faster
%             RCNN format
%       dbfn - filename to save the output data in
%       nClasses - number of categories for this cue
%   outputs
%       roidb - struct containing bounding box data in the faster
%               RCNN format
    roidb = [];
    roidb.name = dbfn;
    item = struct('gt',[],'overlap',[],'boxes',[],'feat',[],'class',[]);
    roidb.rois = repmat(item,length(imageIdxWithCue),1);
    stopwords = imData.stopwords;
    isSubjectRestricted = cue.isCueSubjectRestricted;
    for i = 1:length(imageIdxWithCue)
        imIdx = imageIdxWithCue(i);
        gtBoxes = cell(imData.nSentences(imIdx),1);
        class = cell(imData.nSentences(imIdx),1);
        for j = 1:imData.nSentences(imIdx)
            gtBoxes{j} = cell(imData.nPhrases(imIdx,j),1);
            class{j} = cell(imData.nPhrases(imIdx,j),1);
            for k = 1:imData.nPhrases(imIdx,j)
                relationship = imData.getRelationshipForPhrase(imIdx,j,k,isSubjectRestricted);
                phrase = imData.getPhrase(imIdx,j,k);
                cueClass = cue.getCueCategory(phrase,relationship,stopwords);
                if isempty(cueClass),continue,end
                box = imData.getPhraseGT(imIdx,j,k);
                if isempty(box),continue,end
                class{j}{k} = uint8(cueClass);
                gtBoxes{j}{k} = repmat(box,length(cueClass),1);
            end
        end
        
        gtBoxes = vertcat(gtBoxes{:});
        gtBoxes = vertcat(gtBoxes{:});
        class = vertcat(class{:});
        class = vertcat(class{:});
        assert(size(gtBoxes,1) == length(class));
        boxes = imData.getBoxes(imIdx);
        gt = [true(size(gtBoxes,1),1);false(size(boxes,1),1)];
        allBoxes = single([gtBoxes;boxes]);
        overlap = zeros(size(allBoxes,1),nClasses,'single');
        for j = 1:size(gtBoxes,1)
            overlap(:,class(j)) = max(overlap(:,class(j)),getIOU(gtBoxes(j,:),allBoxes));
        end
        roidb.rois(i).gt = gt;
        roidb.rois(i).overlap = overlap;
        roidb.rois(i).class = class;
        roidb.rois(i).boxes = allBoxes;
    end
end

function imdb = getIMDB(imData,imageIdxWithCue,cue,dbfn)
%getIMDB creates the imdb for the faster rcnn code for a given cue
%   inputs
%       imData - an ImageSetData object
%       imageIdxWithCue - indices of images that contain the input cue
%       cue - a single phrase cue object to parse into the Faster
%             RCNN format
%       dbfn - filename to save the output data in
%   outputs
%       imdb - struct containing image data in the Faster RCNN format
    imdb = [];
    imdb.name = dbfn;
    imdb.image_dir = imData.imagedir;
    imdb.image_ids = imData.imagefns(imageIdxWithCue);
    imdb.extension = imData.ext;
    imdb.flip = 0;
    imdb.classes = cue.classLabels;
    imdb.num_classes = length(imdb.classes);
    imdb.class_to_id = containers.Map(imdb.classes, 1:imdb.num_classes);
    imdb.class_ids = 1:imdb.num_classes;
    imdb.roidb_func = @()loadROIDB(dbfn);
    imdb.image_at = @(i)sprintf('%s/%s.%s', imdb.image_dir, imdb.image_ids{i}, imdb.extension);
    imdb.sizes = zeros(length(imageIdxWithCue),2);
    for i = 1:length(imageIdxWithCue)
        imdb.sizes(i,:) = imData.imSize(imageIdxWithCue(i));
    end
end

