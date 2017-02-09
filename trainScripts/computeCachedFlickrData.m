% This script loads the Flickr30k Entities annotations, parses the dataset's
% sentences, and computes Edge Box proposals for the dataset's images.
conf = plClcConfig;
load(fullfile('data','flickr30k','dataSplits.mat'),'testfns','valfns','trainfns');
imagedir = fullfile(conf.datadir,'Images');
stopwordFile = fullfile(conf.dictionarydir,'stopwords.txt');
stopwords = strsplit(fileread(stopwordFile),'\n');
stopwords(cellfun(@isempty,stopwords)) = [];

if ~exist(conf.testData,'file')
    imData = ImageSetData('test',testfns,imagedir,conf.imExt,stopwords);
    imData.computeSetData(conf.nParseThreads,conf.datadir,conf.pronounFile,conf.nEdgeBoxes);
    save(conf.testData,'imData','-v7.3');
end

if ~exist(conf.valData,'file')
    imData = ImageSetData('val',valfns,imagedir,conf.imExt,stopwords);
    imData.computeSetData(conf.nParseThreads,conf.datadir,conf.pronounFile,conf.nEdgeBoxes);
    save(conf.valData,'imData','-v7.3');
end

if ~exist(conf.trainData,'file')
    imData = ImageSetData('train',trainfns,imagedir,conf.imExt,stopwords);
    imData.computeSetData(conf.nParseThreads,conf.datadir,conf.pronounFile,conf.nEdgeBoxes);
    save(conf.trainData,'imData','-v7.3');
end


