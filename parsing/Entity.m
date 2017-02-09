classdef Entity < Phrase
%ENTITY Common functions and data around noun phrases in a sentence
%   This class contains member variables and functions that are specific to
%   the noun phrase chunks extracted from sentences.
%
%   Documentation for class member variables and functions not provided
%   here are located in the superclass they are originally defined in.
    properties (SetAccess = private)
        % coarse categories associated with this Entity
        groupType = [];
        
        % identifier for this Entity, in Flickr30k Entities this is
        % needed to get bounding box annotations
        entityID = [];
    end
    
    methods
        function phrase = Entity(inWords,inPos,inPosition,inEntityID,inGroups)
            words = [];
            pos = [];
            sentencePosition = [];
            if nargin > 0
                pos = inPos;
                words = inWords;
                sentencePosition = inPosition;
            end
            phrase = phrase@Phrase(words,pos,sentencePosition);
            
            if nargin > 0
                phrase.entityID = inEntityID;
                phrase.groupType = inGroups;
            end
        end

        function box = getGTBox(phrase,annotations)
        %GETGTBOX returns any associated ground truth bounding box for this
        %instance, if multiple boxes are associated the union of the boxes
        %is returned
        %   inputs
        %       phrase - this Entity instance
        %       annotations - the struct output of Flickr30k Entity's
        %                     getAnnotations function for the image
        %                     associated with this Entity
        %   outputs
        %       box - ground truth box if one exists
            box = [];
            idx = find(strcmp(phrase.entityID,annotations.id));
            if isempty(idx),return,end
            locs = annotations.idToLabel{idx};
            box = vertcat(annotations.labels(locs).boxes);
            if isempty(box),return,end
            box = [min(box(:,1)),min(box(:,2)),max(box(:,3)),max(box(:,4))];
        end
        
        function groupMatches = groupTypeMatches(phrase,groupType)
        %GROUPTYPEMATCHES returns indices of groupType that this Entity is
        %associated with
        %   inputs
        %       phrase - this Entity instance
        %       groupType - list of coarse categories to check for
        %                   association with this Entity
        %   outputs
        %       groupMatches - indices of groupType that is associated with
        %                      this Entity
            if ischar(groupType)
                groupType = {groupType};
            end
            isType = cellfun(@(f)~isempty(find(strcmp(f,phrase.groupType),1)),groupType);
            groupMatches = find(isType);
        end
    end
end

