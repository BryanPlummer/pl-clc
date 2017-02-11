% Outputs the prototxt files and dictionaries for the Fast RCNN detectors
% and dictionaries for the pair phrase cues.
conf = plClcConfig;
verbfn = fullfile(conf.dictionarydir,'verbs.txt');
verbs = readClassesFromFile(verbfn);
isSubjectVerb = true;
subjectVerbDet = VerbDetector(isSubjectVerb,'subjectVerb',[],[],verbs);
verbObjectDet = VerbDetector(~isSubjectVerb,'verbObject',[],[],verbs);
verbPairDet = RelativePosition('flickrVerbPair',[],verbs);
prepfn = fullfile(conf.dictionarydir,'prepositions.txt');
prepositions = readClassesFromFile(prepfn);
prepPairDet = RelativePosition('flickrPrepPair',[],prepositions);
clothingBPDet = ClothingBP('flickrClothingbpPair',[],[]);
detectors = {subjectVerbDet,verbObjectDet,verbPairDet,prepPairDet,clothingBPDet};

load(conf.trainData,'imData');
createFlickrDetectorDictionaries(conf,imData,detectors);
adjectives = readClassesFromFile(fullfile(conf.dictionarydir,'adjectives.txt'));
modeldir = fullfile(conf.modeldir,'adjectives');
writeFastRCNNProto(length(adjectives.words),modeldir);



