function [ampl_record] = ...
    SpecAnaly2DwRotSubRoutPhi(gridObj,ParamObj,NumModesMax,DensityFT_record,TimeRecVec, dt,kxholder,kyholder,...
    min_amp,kx,ky,km,D_rot, D_pos,n1,n2,n3,bc)

DecayDisp   = 0;
AllKsVsTime = 1;

%Use squeeze to make a matrix (length(ky), length(j_record) ) of the
%amplitudes we want to look at
ampl_record = squeeze(DensityFT_record(kxholder,kyholder,:,:));

% keyboard
[k2plotInd,n3odes] = Ks2TrackFinderSpec(NumModesMax,ampl_record,TimeRecVec,min_amp);

% keyboard
%Now plot all these amplitudes throughout the record
if DecayDisp
    if bc < 1.5 %Isotropic
        IsoDispPlotterBody(k2plotInd,ampl_record,n3odes,TimeRecVec, dt,kxholder,kyholder,...
            kx,ky,km,D_rot, D_pos,n1,n2,n3,bc)
    else % Nematic
        NemDispPlotterBody(gridObj,ParamObj,k2plotInd,ampl_record,n3odes,TimeRecVec, kxholder,kyholder,...
    kx,ky,km,D_rot, D_pos,n1,n2,n3,bc)

    end
    
end % End DecayDisp

if AllKsVsTime
    ModesVsTimePlotterKm(ampl_record,k2plotInd,TimeRecVec, n3odes,kxholder,kyholder,...
        n1,n2,n3)
end % End AllKsVsTime

end %end function