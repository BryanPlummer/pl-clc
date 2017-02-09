function [spc,updateBoxes] = singlePhraseCueSet(conf,varargin)
%SINGLEPHRASECUESET creates a cell array with the single phrase cues to use
%   inputs
%       conf - configuration settings (e.g. output of plClcConfig)
%       varargin - string arguments identifying specific cues to use
%   outputs
%       spc - cell array of single phrase cues
%       updateBoxes - logical array of the same length as spc where it is 
%                     true when that cue updates the initial candidate 
%                     list
    nCues = 7;
    spc = cell(nCues,1);
    updateBoxes = false(nCues,1);
    if isempty(varargin) || ~isempty(find(strcmp('pascalDetector',varargin),1))
        % we update bounding boxes using the detector so it must
        % come first due to assumptions in the code
        classFN = fullfile(conf.dictionarydir,'pascalObjects.txt');
        classes = readClassesFromFile(classFN);
        def = fullfile(conf.modeldir,'fastrcnn_det.prototxt');
        net = conf.featModel;
        spc{1} = Detector('pascalDetector',net,def,classes);
        updateBoxes(1) = true;
    end
    if isempty(varargin) || ~isempty(find(strcmp('cca',varargin),1))
        load(fullfile(conf.modeldir,'fastrcnn_cca.mat'),'cca_m');
        spc{2} = RegionPhraseCCA('cca',cca_m,conf.featModel,conf.featDef);
    end
    if isempty(varargin) || ~isempty(find(strcmp('size',varargin),1))
        phraseTypes = conf.phraseTypes(~strcmp('notvisual',conf.phraseTypes));
        spc{3} = CandidateSize('size',phraseTypes);
    end
    if isempty(varargin) || ~isempty(find(strcmp('adjectives',varargin),1))
        classFN = fullfile(conf.dictionarydir,'adjectives.txt');
        classes = readClassesFromFile(classFN);
        net = fullfile(conf.modeldir,'adjectives','vgg16_adjectives_iter_40k_final.caffemodel');
        def = fullfile(conf.modeldir,'adjectives','test.prototxt');
        spc{4} = Detector('adjectives',net,def,classes);
    end
    if isempty(varargin) || ~isempty(find(strcmp('subjectVerb',varargin),1))
        classFN = fullfile(conf.dictionarydir,'flickrSubjectVerbClasses.txt');
        classes = readClassesFromFile(classFN);
        net = fullfile(conf.modeldir,'subjectVerb','vgg16_subjectVerb_iter_40k_final.caffemodel');
        def = fullfile(conf.modeldir,'subjectVerb','test.prototxt');
        isSubjectVerb = true;
        spc{5} = VerbDetector(isSubjectVerb,'subjectVerb',net,def,classes);
    end
    if isempty(varargin) || ~isempty(find(strcmp('verbObject',varargin),1))
        classFN = fullfile(conf.dictionarydir,'flickrVerbObjectClasses.txt');
        classes = readClassesFromFile(classFN);
        net = fullfile(conf.modeldir,'verbObject','vgg16_verbObject_iter_40k_final.caffemodel');
        def = fullfile(conf.modeldir,'verbObject','test.prototxt');
        isSubjectVerb = false;
        spc{6} = VerbDetector(isSubjectVerb,'verbObject',net,def,classes);
    end
    if isempty(varargin) || ~isempty(find(strcmp('position',varargin),1))
        modelFN = fullfile(conf.modeldir,'svms','position_subsample_7k.mat');
        load(modelFN,'position');
        spc{7} = position;
    end

    notUsed = cellfun(@isempty,spc);
    spc(notUsed) = [];
    updateBoxes(notUsed) = [];
end