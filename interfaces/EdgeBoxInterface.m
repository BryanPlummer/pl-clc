classdef EdgeBoxInterface < handle
%EDGEBOXINTERFACE wrapper around the Dollar's Edge Box code
    properties
        % the Edge Box model to use
        model = [];
        
        % parameters used to compute the Edge Box proposals
        opts = [];
    end
    
    methods
        function eb = EdgeBoxInterface()
            boxModel=load(fullfile('external','edges','models','forest','modelBsds')); 
            boxModel=boxModel.model;
            boxModel.opts.multiscale=0; 
            boxModel.opts.sharpen=2; 
            boxModel.opts.nThreads=4;
            boxModel.opts.nTreesEval=4;
            boxModel.opts.nms=1;

            % set up opts for edgeBoxes (see edgeBoxes.m)                  
            opts = edgeBoxes;
            opts.alpha = .65;     % step size of sliding window search
            opts.beta  = .65;     % nms threshold for object proposals
            opts.eta   = 1.0;     % adaptive nms threshold
            opts.minScore = .01;  % min score of boxes to detect
            opts.maxBoxes = 1e4;  % max number of boxes to detect
            eb.model = boxModel;
            eb.opts = opts;
        end
        
        function boxes = computeProposals(eb,im)
        %COMPUTEPROPOSALS returns the Edge Box proposals for this image
        %   inputs
        %       eb - EdgeBoxInface instace
        %       im - image to compute proposals for
        %   outputs
        %       boxes - Edge Box proposals for this image
            boxes = edgeBoxes(im,eb.model,eb.opts);
            
            % convert to [x1 y1 x2 y2] format
            boxes(:,3) = boxes(:,1)+boxes(:,3);
            boxes(:,4) = boxes(:,2)+boxes(:,4);
        end
    end
    
end

