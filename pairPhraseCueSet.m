function ppc = pairPhraseCueSet(conf,varargin)
%PAIRPHRASECUESET creates a cell array with the pair phrase cues to use
%   inputs
%       conf - configuration settings (e.g. output of plClcConfig)
%       varargin - string arguments identifying specific cues to use
%   outputs
%       ppc - cell array of pair phrase cues
    nCues = 3;
    ppc = cell(nCues,1);
    if isempty(varargin) || ~isempty(find(strcmp('verb',varargin),1))
        modelFN = fullfile(conf.modeldir,'svms','verbPairPhrase_defaultWeights_top30_0.8nms_subsample_10k.mat');
        load(modelFN,'verbPairs');
        ppc{1} = verbPairs;
    end
    if isempty(varargin) || ~isempty(find(strcmp('prep',varargin),1))
        modelFN = fullfile(conf.modeldir,'svms','prepPairPhrase_defaultWeights_top30_0.8nms_subsample_10k.mat');
        load(modelFN,'prepPairs');
        ppc{2} = prepPairs;
    end
    if isempty(varargin) || ~isempty(find(strcmp('clbp',varargin),1))
        modelFN = fullfile(conf.modeldir,'svms','clbpPairPhrase_defaultWeights_top30_0.8nms_subsample_7k.mat');
        load(modelFN,'clbpPairs');
        ppc{3} = clbpPairs;
    end
    
    ppc(cellfun(@isempty,ppc)) = [];
end




