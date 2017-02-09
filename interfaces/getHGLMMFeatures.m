function textFeats = getHGLMMFeatures(text)
%GETHGLMMFEATURES
%   inputs
%       text - a cell array of length M containing the text to
%              encode as a HGLMM vector representation
%   outputs
%       textFeats - 18000 x M matrix of the HGLMM fisher vector
%                   representation of text inputs on top of word2vec
    if ~iscell(text)
        text = {text};
    end
    type = 'hglmm_30';
    dim_red_type = 'ica_300';
    is_sampled = true;
    textFeats = encode_sentences(text, type, dim_red_type, is_sampled);
end

