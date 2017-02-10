% learns the single phrase cue mixing weights
conf = plClcConfig;
load(conf.valData,'imData');
imData.concatenateGTBoxes();
[spc,updateBoxes] = singlePhraseCueSet(conf);
[imData,scores,boxes] = getSPCScores(conf,imData,spc,updateBoxes);
[weights,valLoss] = trainCueWeights(conf,imData,boxes,scores);
outdir = fullfile(conf.modeldir,'learnedWeights');
mkdir_if_missing(outdir);
fn = fullfile(outdir,'spcWeights.mat');
save(fn,'weights','valLoss');


