function [iw] = irw_est_kmm(X, Z, varargin)
% Use Kernel Mean Matching to estimate weights for importance weighting.
% Jiayuan Huang, Alex Smola, Arthur Gretton, Karsten Borgwardt & Bernhard
% Schoelkopf. Correcting Sample Selection Bias by unlabeled data.

% Parse input
p = inputParser;
addParameter(p, 'theta', 1);
addParameter(p, 'kernel', 'rbf');
parse(p, varargin{:});

% Shapes
[~,NQ] = size(X);
[~,NP] = size(Z);

switch p.Results.kernel
    case 'rbf'
        
        % Calculate Euclidean distances
        K = pdist2(X',X');
        k = pdist2(X',Z');
        
        % Cleanup
        I = find(K<0); K(I) = zeros(size(I));
        J = find(K<0); K(J) = zeros(size(J));
        
        % Radial basis function
        K = exp(-K/(2*p.Results.theta.^2));
        k = exp(-k/(2*p.Results.theta.^2));
        k = NQ./NP*sum(k,2);
        
    case 'diste'
        % Calculate Euclidean distances
        K = pdist2(X',X');
        k = pdist2(X',Z');
        if theta ~= 2
            K = sqrt(K).^p.Results.theta;
            k = sqrt(k).^p.Results.theta;
        end
        k = NQ./NP*sum(k,2);
end

% Approximate if memory shortage
a = whos('K');
if a.bytes > 2e9;
    K(K<.2) = 0;
    K = sparse(K);
end

% Solve quadratic program
options.Display = 'final';
iw = quadprog(K,k,[ones(1,NQ); -ones(1,NQ)],[NQ./sqrt(NQ)+NQ NQ./sqrt(NQ)-NQ],[],[],zeros(NQ,1),ones(NQ,1), [], options)';

end

