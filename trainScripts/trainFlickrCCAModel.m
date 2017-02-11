function cca_m = trainFlickrCCAModel()
%TRAINFLICKRCCAMODEL trains the phrase-region CCA model
    conf = plClcConfig;
    load(conf.trainData,'imData');
    phraseList = getPhraseLists(imData,conf.phraseTypes);
    phraseList = subsamplePhraseList(phraseList,conf.ccaMaxSamplesPerPhrase);
    disp('phrase lists complete');
    textFeats = single(getHGLMMFeatures(strrep(phraseList.keys(),'+',' ')));
    disp('hglmm done');
    imData = organizePhraseListByImage(imData,phraseList);
    imageFeats = getFastRCNNFeatures(imData,conf.featModel,conf.featDef);
    disp('cca prep');
    [imageFeats,textFeats] = organizeFeatsForCCA(phraseList,textFeats,imData,imageFeats);
    center = true;
    cca_m = CCAModel;
    disp('cca training');
    cca_m.train(textFeats,imageFeats,conf.ccaETA,center);   
end

function [imageFeats,textFeats] = organizeFeatsForCCA(phraseList,textFeats,imData,imageFeats)
    textFeatPairIdx = cell(size(textFeats,2),1);
    imageFeatPairs = cell(size(textFeats,2),1);
    phrase = phraseList.keys();
    assert(length(phrase) == size(textFeats,2));
    imFeatDim = size(imageFeats{1},1);
    for i = 1:length(phrase)
        instances = phraseList(phrase{i});
        textFeatPairIdx{i} = ones(length(instances),1)*i;
        imageFeatPairs{i} = zeros(imFeatDim,length(instances),'single');
        for j = 1:length(instances)
            imIdx = find(strcmp(instances(j).imageID,imData.imagefns),1);
            assert(length(imIdx) == 1);
            boxes = imData.getBoxes(imIdx);
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



