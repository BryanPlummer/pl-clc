classdef Cue < handle
%CUE members and functions that are applicible to all cues
%   This is the base class for all cues with member variables and functions
%   which are shared over all cues.
    properties (SetAccess = public)
        % Character array containing an identifier for a cue.
        cueLabel = [];
        
        % The parameters used to score an image region for a cue (i.e. an 
        % SVM, weights for a CNN, etc).
        model = [];
        
        % The data used to identify if a cue is applicable to a partciular
        % phrase.
        dictionary = [];
    end
    
    methods
        function cue = Cue(cueLabel,model,dictionary)
            if nargin > 0
                cue.cueLabel = cueLabel;
                cue.model = model;
                cue.dictionary = dictionary;
            end
        end

        function [scores,boxes] = loadCueScores(cue,cachedir)
        %LOADCUESCORES loads any previously computed cue scores
        %   inputs
        %       cue - this Cue object
        %       cachedir - directory where cue data is being saved to
        %   outputs
        %       scores - saved score data for this cue
        %       boxes - saved box data for this cue
            fn = strcat(fullfile(cachedir,cue.cueLabel),'.mat');
            if ~exist(fn,'file')
                scores = [];
                boxes = [];
            else
                if nargout > 1
                    load(fn,'scores','boxes');
                else
                    load(fn,'scores');
                end
            end
        end

        function saveCueScores(cue,cachedir,scores,boxes)
        %SAVECUESCORES saves cue scores to a mat file
        %   inputs
        %       cue - this Cue object
        %       scores - score data for this cue
        %       boxes - box data for this cue
        %       cachedir - directory where cue data should be saved to
            mkdir_if_missing(cachedir);
            fn = fullfile(cachedir,cue.cueLabel);
            if nargin < 4
                save(fn,'scores','-v7.3');
            else
                save(fn,'scores','boxes','-v7.3');
            end
        end
    end
end

