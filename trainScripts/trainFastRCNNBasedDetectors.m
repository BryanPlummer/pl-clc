% learns the adjective, subject-verb and verb-object Fast RCNN models
conf = plClcConfig;
load(conf.trainData,'imData');
val = load(conf.valData,'imData');

detectorCues = singlePhraseCueSet(conf,'adjectives','subjectVerb','verbObject');
cachedir = '';
for i = 1:length(detectorCues)
    netdir = fullfile(conf.modeldir,detectorCues{i}.cueLabel);
    dbdir = fullfile('imdb','cache',strcat(detectorCues{i}.cueLabel,'_'));
    trainFastRCNNCue(imData,val.imData,detectorCues{i},netdir,cachedir,dbdir);
end



