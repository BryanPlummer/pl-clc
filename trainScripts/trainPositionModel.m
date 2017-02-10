% trains the phrase location svm model
conf = plClcConfig;
groupNames = conf.phraseTypes;
groupNames(strcmp('notvisual',groupNames)) = [];

load(conf.trainData,'imData');
imData.concatenateGTBoxes();
maxTrainSamples = 7000;
position = CandidatePosition('position',[],groupNames);
position.trainModel(imData,maxTrainSamples,conf.posThresh);

posFN = sprintf('position_subsample_%ik',maxTrainSamples/1000);
save(fullfile(conf.modeldir,'svms',posFN),'position','-v7.3');
    

