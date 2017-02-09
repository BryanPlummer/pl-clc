classdef DataDefinedClasses < handle
%DATADEFINEDCLASSES required interface for cues that consider the training
%data when deciding on categories.
%   This class contains the expected interface for cues that base the
%   categories they train off of the available training data.

    methods (Abstract)
        makeClasses(classObj,conf,imData);
        %MAKECLASSES creates the categories the cue will learn
        %   inputs
        %       classObj - this instance of the DataDefinedClasses object
        %       conf - struct containing the configuration data of this
        %              experiment
        %       imData - an instance of ImageSetData with the training data
    end
end

