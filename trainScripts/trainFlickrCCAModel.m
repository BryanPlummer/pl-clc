function cca_m = trainFlickrCCAModel()
%TRAINFLICKRCCAMODEL trains the phrase-region CCA model
    conf = plClcConfig;
    load(conf.trainData,'imData');
    phraseList = getPhraseLists(imData,conf.phraseTypes);
    phraseList = subsamplePhraseList(phraseList,conf.ccaMaxSamplesPerPhrase);
    disp('phrase lists complete');
    textFeats = getHGLMMFeatures(strrep(phraseList.keys(),'+',' '));
    disp('hglmm done');
    imageList = organizePhraseListByImage(phraseList);
    imageFeats = getFastRCNNFeatures(imageList,conf.featModel,conf.featDef);
    disp('cca prep');
    [imageFeats,textFeats] = organizeFeatsForCCA(phraseList,textFeats,imageList,imageFeats);
    center = true;
    cca_m = CCAModel;
    disp('cca training');
    textFeats = single(textFeats);
    cca_m.train(textFeats,imageFeats,conf.ccaETA,center);   
end

function [imageFeats,textFeats] = organizeFeatsForCCA(phraseList,textFeats,imageList,imageFeats)
    textFeatPairIdx = cell(size(textFeats,2),1);
    imageFeatPairs = cell(size(textFeats,2),1);
    phrase = phraseList.keys();
    assert(length(phrase) == size(textFeats,2));
    imFeatDim = size(imageFeats{1},1);
    imageID = imageList.keys();
    for i = 1:length(phrase)
        instances = phraseList(phrase{i});
        textFeatPairIdx{i} = ones(length(instances),1)*i;
        imageFeatPairs{i} = zeros(imFeatDim,length(instances),'single');
        for j = 1:length(instances)
            boxes = imageList(instances(j).imageID);
            imIdx = find(strcmp(instances(j).imageID,imageID),1);
            assert(length(imIdx) == 1);
            [~,~,boxIdx] = intersect(instances(j).box,boxes,'rows');
            assert(length(boxIdx) == 1);
            imageFeatPairs{i}(:,j) = imageFeats{imIdx}(:,boxIdx);
        end
    end
    
    imageFeats = horzcat(imageFeatPairs{:});
    textFeatPairIdx = vertcat(textFeatPairIdx{:});
    textFeats = textFeats(:,textFeatPairIdx); 
end

function phraseList = subsamplePhraseList(phraseList,nSamples)
    phrases = phraseList.keys();
    for i = 1:length(phrases)
        instances = phraseList(phrases{i});
        if length(instances) > nSamples
            sampledIdx = randperm(length(instances),nSamples);
            phraseList(phrases{i}) = instances(sampledIdx);
        end
    end
end



