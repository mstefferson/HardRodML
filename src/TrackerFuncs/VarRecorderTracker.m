function [SteadyState,ShitIsFucked,MaxReldRho] = ...
VarRecorderTracker(lfid,timeObj,t,n1,n2,n3,rhoVec_FT,rhoVec_FT_prev,TotalDensity ,j_record)
% Track how mucht the wieghted density has changed.
%Check to see if steady state has been reached. If so, break the
%loop'
%         keyboard
global Density_rec 
global DensityFT_rec

% keyboard
fprintf(lfid,'%f percent done\n',t./timeObj.N_time*100);
% fclose(tfid);
rho         = real(ifftn(ifftshift(reshape( rhoVec_FT,n1,n2,n3 ))));
rho_prev    = real(ifftn(ifftshift(reshape( rhoVec_FT_prev,n1,n2,n3 ))));

% See if things are broken
[SteadyState,ShitIsFucked,MaxReldRho] = BrokenSteadyDenTracker(rho,rho_prev,TotalDensity ,timeObj);

rho_cube_FT = reshape( rhoVec_FT,n1,n2,n3 );
DensityFT_rec(:,:,:,j_record)   = rho_cube_FT;
Density_rec(:,:,:,j_record)     = rho;
%         keyboard
end

function [SteadyState,ShitIsFucked,MaxReldRho] = ...
    BrokenSteadyDenTracker(rho,rho_prev,TotalDensity ,timeObj)
SteadyState = 0;
ShitIsFucked = 0;

AbsDensityChange = abs( rho - rho_prev );
WeightDensityChange = AbsDensityChange ./ rho;
MaxReldRho = max(max(max(WeightDensityChange)));
if MaxReldRho < timeObj.ss_epsilon
    SteadyState = 1;
end

%See if something broke
%Negative Density check
if min(min(min(rho))) < 0
    fprintf('Forgive me, your grace. Density has become negative\n');
    %         keyboard
    ShitIsFucked  = 1;
end
%Not conserving density check.
if abs( sum(sum(sum(rho)))- TotalDensity ) > TotalDensity / 1000;
    fprintf('Forgive me, your grace. Density is not being conserved\n');
    ShitIsFucked  = 1;
end


% Nan or infinity
% keyboard
if find(isinf(rho)) ~= 0
    fprintf('Forgive me, your grace. Density has gone infinite. ');
    fprintf('Does that make sense? No. No it does not\n');
    ShitIsFucked  = 1;
end

if find(isnan(rho)) ~= 0
    fprintf('Forgive me, your grace. Density elements are no longer numbers. ');
    fprintf('Does that make sense? No. No it does not\n');
    ShitIsFucked  = 1;
end


end
