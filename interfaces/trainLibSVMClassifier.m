function model = trainLibSVMClassifier(trainData,maxSamples,trainPosThresh)
%TRAINLIBSVMCLASSIFIER
%   inputs
%       trainData{i}{j}{k} - features for image i, sentence j, and
%                            phrase k
%       maxSamples - the maximum number of positive or negative
%                    examples to use during training
%       trainPosThresh - the IOU threshold required for a bounding
%                        box to be considered a positive example
%   outputs
%       model - a struct containing the trained svm and the platt
%               scaling parameters to convert the output to a
%               probability
    trainData = vertcat(trainData{:});
    trainData = vertcat(trainData{:});
    trainData(cellfun(@isempty,trainData)) = [];
    trainData = vertcat(trainData{:});
    model = cell(size(trainData,2),1);
    opts = '-t 2 -s 3 -c 1.0 -h 0';
    parfor i = 1:size(trainData,2)
        features = vertcat(trainData{:,i});
        labels = features(:,end) >= trainPosThresh;
        features(:,end) = [];
        
        [features,labels] = checkMaxSamples(features,labels,maxSamples,false);
        [features,labels] = checkMaxSamples(features,labels,maxSamples,true);
        features = sparse(double(features));
        labels = double(labels);
        svmModel = svmtrain(labels,features,opts); 
        scores = svmpredict(labels,features,svmModel);
        sigfunc = @(A, x)(1 ./ (1 + exp(x.*A(1)+A(2))));
        probModel = fitnlm(scores,labels,sigfunc,[0,0]);
        model{i} = struct('svm',svmModel,'prob',probModel);
    end
end

function [features,labels] = checkMaxSamples(features,labels,maxSamples,checkLabel)
    nSamples = sum(labels == checkLabel);
    maxSamples = min(maxSamples,sum(labels ~= checkLabel));
    if nSamples > maxSamples
        removeSample = find(labels == checkLabel);
        removeSample(randperm(nSamples,maxSamples)) = [];
        features(removeSample,:) = [];
        labels(removeSample) = [];
    end
end




