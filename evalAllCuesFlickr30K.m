% Example script which evaluates the phrase localization task using the cues 
% from our paper.
conf = plClcConfig;
load(conf.testData,'imData');
[spc,updateBoxes] = singlePhraseCueSet(conf);
[imData,scores,boxes] = getSPCScores(conf,imData,spc,updateBoxes);

load(conf.spcWeights,'weights');
addGT = false;
scores = scoreRegionsWithSinglePhraseCues(conf,imData,weights,scores,boxes,addGT);

ppc = pairPhraseCueSet(conf);
load(conf.ppcWeights,'weights');
selectedCandidates = refineCandidatesWithPairPhraseCues(conf,imData,weights,ppc,scores);

% comment out the following line and uncomment the one with more
% arguments for detailed evaluation
[acc,oracle] = flickrPhraseLocalizationEval(imData,boxes,selectedCandidates,conf.posThresh);

detailedEvalFN = 'test_all_cue.csv';
phraseTypes = conf.phraseTypes(~strcmp('notvisual',conf.phraseTypes));
%[acc,oracle] = flickrPhraseLocalizationEval(imData,boxes,selectedCandidates,conf.posThresh,spc,ppc,detailedEvalFN,phraseTypes);
fprintf('Accuracy: %f Upper Bound: %f\n',acc,oracle);
