function [cStats, pStats, nStats] = ...
  bandStatsCPNwrap( Cslice, Pslice, Nslice, Lvar, NposVar )
% C slice
[cStats.maxV, cStats.minV, cStats.aveV, ...
  cStats.vdiff, cStats.fwhd, maxInd] = ...
  bandStats( Cslice, Lvar, NposVar ) ;
% Scale c's 
cStats.maxV = cStats.maxV / pi;
cStats.minV = cStats.minV / pi;
cStats.aveV = cStats.aveV / pi;
cStats.vdiff = cStats.vdiff / cStats.aveV;

% P slice: two peaks so be careful
 deltaInd = round( cStats.fwhd / Lvar .* NposVar);
if maxInd > length(Pslice) / 2;
  pInd = maxInd-deltaInd:maxInd;
else
  pInd = maxInd:maxInd+deltaInd;
end

[pStats.maxV, pStats.minV, pStats.aveV, ...
  pStats.vdiff, pStats.fwhd,~] = ...
  bandStats( Pslice(pInd), Lvar, NposVar ) ;

% N slice
[nStats.maxV, nStats.minV, nStats.aveV, ...
  nStats.vdiff, nStats.fwhd,~] = ...
  bandStats( Nslice, Lvar, NposVar ) ;

end

