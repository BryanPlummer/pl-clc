function createFlickrDetectorDictionaries(conf,imData,detectorTypes)
%CREATEFLICKRDETECTORDICTIONARIES outputs the files needed to train Fast
%RCNN detectors
%   inputs
%       conf - struct output of plCLCConfig
%       imData - an instance of ImageSetData with the training data
%       detectorTypes - cell array of Detector single phrase cue instances
    if isempty(detectorTypes)
        return;
    end

    imData.filterNonvisualPhrases();
    
    for i = 1:length(detectorTypes)
        detectorTypes{i}.makeClasses(conf,imData);
    end
end


