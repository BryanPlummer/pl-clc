function [relationship,phrase] = batchSentenceParse(imagefns,annodir,nThreads,pronounFile)
%BATCHSENTENCEPARSE parses an array of sentences using Matlab's batch
%functions
%   inputs
%       imagefns - a cell array of image identifiers
%       annodir - directory where Flickr30k Entities' sentence annotations
%                 are
%       nThreads - number of compute threads to use
%   outputs
%       relationship - pair phrase relationships objects for each sentence
%       phrase - single phrase Entity objects for each sentence
nPerBatch = floor(length(imagefns)/nThreads);
batchIdx = 0:nPerBatch:length(imagefns);
batchIdx(end) = length(imagefns);
parseRequiredFunctions = {'addIfNotInJavaPath.m','Entity.m','FlickrSentenceData.m','isRelationInSequence.m','parseTreeStringCompareN.m','Phrase.m','Relationship.m','StanfordParser.m'};

assert(length(batchIdx) == nThreads+1);
nOutputArgs = 2; % cell array of relationships and another of entities
for i = 1:nThreads-1
    batchfns = imagefns(batchIdx(i)+1:batchIdx(i+1));
    batchArgs = [];
    batchArgs.imageID = batchfns;
    batchArgs.annodir = annodir;
    batchArgs.pronounFile = pronounFile;
    jobs(i) = batch('sentenceParse',nOutputArgs,{batchArgs},'AttachedFiles',parseRequiredFunctions);
end


relationship = cell(nThreads,1);
phrase = cell(nThreads,1);
batchfns = imagefns(batchIdx(end-1)+1:batchIdx(end));
batchArgs = [];
batchArgs.imageID = batchfns;
batchArgs.annodir = annodir;
batchArgs.pronounFile = pronounFile;
[relationship{end},phrase{end}] = sentenceParse(batchArgs);

for i = 1:nThreads-1
    wait(jobs(i))
    outArgs = fetchOutputs(jobs(i));
    relationship{i} = outArgs{1};
    phrase{i} = outArgs{2};
end


relationship = vertcat(relationship{:});
phrase = vertcat(phrase{:});


