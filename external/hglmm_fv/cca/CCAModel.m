% this class enables you to:
% 1. train CCA mappings given training data.
% 2. map test data using the mappings obtained in the training stage.
classdef CCAModel < handle
    
    properties
        eta;
        center;
        
        meanX;
        meanY;
        Wx;
        Wy;
        r;
        apply_r;
    end
    
    methods
	    
        % XTRAIN: X vectors (the columns are the vectors)
        % YTRAIN: Y vectors (the columns are the vectors)
        % for all i, XTRAIN(:,i) and YTRAIN(:,i) should be a correct pair
        % eta: regularization const
        % center: subtract mean. 
        function train(this, XTRAIN, YTRAIN, eta, center)
            
            this.eta = eta;
            this.center = center;
            

            if center
                this.meanX = mean(XTRAIN, 2);
                this.meanY = mean(YTRAIN, 2);
                XTRAIN = bsxfun(@minus, XTRAIN, this.meanX);
                YTRAIN = bsxfun(@minus, YTRAIN, this.meanY);
            else
                this.meanX = zeros(size(XTRAIN,1), 1);
                this.meanY = zeros(size(YTRAIN,1), 1);
            end

            if eta
                regfactor = 1/eta;
            else
                regfactor = 0;
            end
            
            [this.Wx, this.Wy, this.r] = cca_alg(XTRAIN,YTRAIN,[],regfactor);
        end
        
        
        % set the apply_r parameter, to be used in 'map' method
        % setting apply_r to true will enable scaling by the eigenvalues
        function set_apply_r(this, apply_r)
            this.apply_r = apply_r;
        end
        
        
        % maps the given vectors to the cca space.
        % is_X determines whether to map the vectors using Wx or Wy
        % normalize determines whether to L2-normalize the vectors.
        function vectors = map(this, vectors, is_X, normalize)
            
            if is_X
                vectors = this.Wx' * bsxfun(@minus, vectors, this.meanX);
            else
                vectors = this.Wy' * bsxfun(@minus, vectors, this.meanY);
            end
            
            if isempty(this.apply_r)
                error('apply_r was not set. you have to call set_apply_r()');
            end
            
            if this.apply_r
                vectors = diag(this.r)*vectors;
            end
            
            if normalize
                vectors = normc(vectors);
            end
        end
        
        
        % returns the distance between x and y
        function d = dist(this, x, y, apply_r, cosdist)

            x = this.Wx'*(x - this.meanX);
            y = this.Wy'*(y - this.meanY);

            if apply_r
                x = diag(this.r)*x;
                y = diag(this.r)*y;
            end
            
            if cosdist
                x = x./norm(x);
                y = y./norm(y);
                % y'*x is faster than dot(y,x)
                d = 1 - y'*x;
            else                
                d = norm(y-x);
            end
            
        end
        
    end
end
