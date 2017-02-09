conf = plClcConfig;
load(conf.valData,'imData');
imData.concatenateGTBoxes();
[spc,updateBoxes] = singlePhraseCueSet(conf);
[imData,scores,boxes] = getSPCScores(conf,imData,spc,updateBoxes);
load(conf.spcWeights,'weights');
addGT = true;
scores = scoreRegionsWithSinglePhraseCues(conf,imData,weights,scores,boxes,addGT);

ppc = pairPhraseCueSet(conf);
[weights,valLoss] = trainPairCueWeights(conf,imData,scores,ppc);
outdir = fullfile(conf.modeldir,'learnedWeights');
mkdir_if_missing(outdir);
fn = fullfile(outdir,'ppcWeights.mat');
save(fn,'weights','valLoss');


