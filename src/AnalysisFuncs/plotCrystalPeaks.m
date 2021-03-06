% Plot k peaks vs time
function plotCrystalPeaks( cFt, c, k1, k2, timeRec, systemObj, ...
  lrEs1, lrEs2, lrLs1, lrLs2, saveMe)
% add paths for now
addpath( genpath( './src' ) )
% square cFt
cFt = abs( cFt ) .^ 2;
% run dispererion
paramVec = [ systemObj.n1, systemObj.n2, systemObj.l1, systemObj.l2, ...
  lrEs1, lrEs2, ...
  lrLs1, lrLs2, systemObj.c ];
disper = dispersionSoftShoulder( paramVec, 1 );
fig0 = gcf;
% get size and center
[n1, n2, nt] = size( cFt );
k1center = n1 / 2 + 1;
k2center = n2 / 2 + 1;
% get positive kx, ky vectors
k1Pos = k1( k1center:n1 );
k2Pos = k2( k2center:n2 );
% Look at positive kx, ky
cFtPos = cFt(k1center:n1, k2center:n2,:);
% Get rid of noise
noiseEps = 1e-10;
cFtPos( cFtPos < noiseEps ) = 0;
% find peaks
ftTemp = cFtPos(:,:,end);
ftTemp( ftTemp < ftTemp(1,1) / 100 ) = 0;
[~,k1PeakInds] = findpeaks( ftTemp(:,1) );
[~,k2PeakInds] = findpeaks( ftTemp(1,:) );
% Add zero so there are no bugs
k1PeakInds = [1 k1PeakInds'];
k2PeakInds = [1 k2PeakInds];
numk1peaks = length( k1PeakInds );
numk2peaks = length( k2PeakInds );
% peaks in k-space
dPeak = 12;
fig1 = figure();
% set max number of time slices to prevent overcrowding
maxSlices = 6;
tInterval = floor( (nt-1) / ( maxSlices - 1 ) );
tSliceInds = tInterval * (0:maxSlices-1) + 1;
colorArray = viridis( maxSlices );
legcell = cell( maxSlices, 1 );
for ii = 1:maxSlices
  legcell{ii} = [ '$$ t = ' num2str( timeRec( tSliceInds(ii) ) ) ' $$'];
end
% k1 peaks
ax = subplot(1,2,1);
inds = 2: min( max(k1PeakInds) + dPeak, n1 );
c2plot =  reshape( cFtPos( inds , 1, tSliceInds), [length(inds), maxSlices] );
x2plot = repmat( k1Pos(inds)', [1 maxSlices] );
p = plot( x2plot, c2plot, 'Linewidth', 2 );
for ii = 1:maxSlices
  p(ii).Color = colorArray(ii,:);
end
% plot n index by peaks
c2plot( c2plot < max( c2plot(:,1) / 100 ) ) = 0;
[~,getIndsForPeaks1] = findpeaks( c2plot(:,1) );
[~,getIndsForPeaks2] = findpeaks( c2plot(:,end) );
getIndsForPeaks = unique( [getIndsForPeaks1; getIndsForPeaks2 ] );
if ~isempty(getIndsForPeaks)
  text4plot = cellstr( num2str( getIndsForPeaks, 'n = %d' ) );
  maxC2plot = max( c2plot, [], 2 );
  for ii = 1:length(text4plot)
    text( 2*pi/systemObj.l1*(getIndsForPeaks(ii)-0.5 ), ...
      maxC2plot( getIndsForPeaks(ii) ) .* 1.01 , ...
      text4plot{ii} );
  end
end
xlabel( ' $$ k_1 $$ '); ylabel('Amplitude');
title( '$$ k_1 $$ modes')
ax.XAxis.TickLabelFormat = '%,.2f';
leg = legend(legcell);
leg.Interpreter = 'latex';
% k2 peaks
ax = subplot(1,2,2);
inds = 2: min( max(k2PeakInds) + dPeak, n2 );
c2plot =  reshape( cFtPos( 1, inds, tSliceInds), [length(inds), maxSlices] );
x2plot = repmat( k2Pos(inds)', [1 maxSlices] );
p = plot( x2plot, c2plot, 'Linewidth', 2 );
for ii = 1:maxSlices
  p(ii).Color = colorArray(ii,:);
end
% plot n index by peaks
c2plot( c2plot < max( c2plot(:,1) / 100 ) ) = 0;
[~,getIndsForPeaks1] = findpeaks( c2plot(:,1) );
[~,getIndsForPeaks2] = findpeaks( c2plot(:,end) );
getIndsForPeaks = unique( [getIndsForPeaks1; getIndsForPeaks2 ] );
if ~isempty(getIndsForPeaks)
  text4plot = cellstr( num2str( getIndsForPeaks, 'n = %d' ) );
  maxC2plot = max( c2plot, [], 2 );
  for ii = 1:length(text4plot)
    text( 2*pi/systemObj.l1*(getIndsForPeaks(ii)-0.5 ), ...
      maxC2plot( getIndsForPeaks(ii) ) .* 1.01 , ...
      text4plot{ii} );
  end
end
xlabel( ' $$ k_2 $$ '); ylabel('Amplitude');
title( '$$ k_2 $$ modes')
ax.XAxis.TickLabelFormat = '%,.2f';
leg = legend(legcell);
leg.Interpreter = 'latex';
% peaks in time
fig2 = figure();
% k1 peaks vs time
colorArray = viridis( numk1peaks );
ax = subplot(2,2,1);
legcell = cell( numk1peaks, 1 );
for ii = 1:numk1peaks
  legcell{ii} = ['$$ k_1 =  ' num2str( k1Pos( k1PeakInds(ii) ),'%.1f' ) ' $$'];
end
tempFt2plot = reshape( cFtPos( k1PeakInds , 1, : ), [numk1peaks nt] )';
p = plot( timeRec, tempFt2plot, 'LineWidth', 2 );
for ii = 1:numk1peaks
  p(ii).Color = colorArray(ii,:);
end
xlabel( ' $$ t $$ '); ylabel('Amplitude');
title( '$$ k_1 $$ modes')
ax.YAxis.TickLabelFormat = '%,.2f';
leg = legend(legcell);
leg.Interpreter = 'latex';
% k2 peaks vs time
colorArray = viridis( numk2peaks );
ax = subplot(2,2,2);
legcell = cell( numk2peaks, 1 );
for ii = 1:numk2peaks
  legcell{ii} = ['$$ k_2 = ' num2str( k2Pos( k2PeakInds(ii) ),'%.1f' ) ' $$'];
end
tempFt2plot = reshape( cFtPos( 1, k2PeakInds, : ), [numk2peaks nt] )' ;
p = plot( timeRec, tempFt2plot, 'LineWidth', 2  );
for ii = 1:numk2peaks
  p(ii).Color = colorArray(ii,:);
end
xlabel( ' $$ t $$ '); ylabel('Amplitude');
title( '$$ k_2 $$ modes')
ax.YAxis.TickLabelFormat = '%,.2f';
leg = legend(legcell);
leg.Interpreter = 'latex';
% unstable peaks plotyy
maxLinDispPeaks = disper.kAllPeakInds;
if length( maxLinDispPeaks ) < 3
  maxLinDispPeaks = [ maxLinDispPeaks,...
    ones(1,3-length( maxLinDispPeaks ) ) ];
end
subplot(2,2,3);
if length(k1PeakInds) >= length(k2PeakInds)
  pickedkDir = 'k1';
else
  pickedkDir = 'k2';
end
% peak 1
if length(k1PeakInds) >= length(k2PeakInds)
  tempFt2plot1 = reshape( cFtPos( maxLinDispPeaks(2), 1, : ), [1 nt] )' ;
else
  tempFt2plot1 = reshape( cFtPos(1, maxLinDispPeaks(2), : ), [1 nt] )' ;
end
% get stabillity info
if maxLinDispPeaks(2) == disper.kPeakMaxInd
  plotk1peak = 'max unstable';
  dashtype1 = '-';
elseif any( maxLinDispPeaks(2) == disper.kPeaksInds )
  plotk1peak = 'unstable';
  % plot all unstable peaks
  dashtype1 = '--';
else
  plotk1peak = 'stable';
  dashtype1 = ':';
end
% peak 2
if length(k1PeakInds) >= length(k2PeakInds)
  tempFt2plot2 = reshape( cFtPos(maxLinDispPeaks(3), 1, : ), [1 nt] )' ;
else
  tempFt2plot2 = reshape( cFtPos(1, maxLinDispPeaks(3), : ), [1 nt] )' ;
end
% get stability info
if maxLinDispPeaks(3) == disper.kPeakMaxInd
  plotk2peak = 'max unstable';
  dashtype2 = '-';
elseif any( maxLinDispPeaks(3) == disper.kPeaksInds)
  plotk2peak = 'unstable';
  dashtype2 = '--';
else
  plotk2peak = 'stable';
  dashtype2 = ':';
end
% get peak k values from dispersion
nLow = maxLinDispPeaks(2) - 1;
kLow = 2*pi/systemObj.l1 * nLow;
nUpp = maxLinDispPeaks(3) - 1;
kUpp = 2*pi/systemObj.l1 * nUpp;
% plot it
[~, p1, p2 ] = plotyy( timeRec, tempFt2plot1, timeRec, tempFt2plot2);
p1.LineStyle = dashtype1;
p1.LineWidth = 2;
p2.LineStyle = dashtype2;
p2.LineWidth = 2;
titlstr = ['Lin stability peaks. k dir: ' pickedkDir ];
title(titlstr)
xlabel('t');ylabel('Amplitude');
legcell = { ['$$ k_{p,l} $$ : ' plotk1peak ], ...
  [ '$$ k_{p,u} $$ : ' plotk2peak ] };
leg = legend(legcell,'location','best');
leg.Interpreter = 'latex';
% unstable peaks plot together, but only show low amplitude
subplot(2,2,4);
% normalize if possible
if tempFt2plot1(1) ~= 0 && tempFt2plot2(1) ~= 0
  tempFt2plot1 = tempFt2plot1 ./ tempFt2plot1(1);
  tempFt2plot2 = tempFt2plot2 ./ tempFt2plot2(1);
  ylab = 'Amplitude / A(0)';
else
  ylab = 'Amplitude';
end
p = plot( timeRec, tempFt2plot1, timeRec, tempFt2plot2 );
ax = gca;
limFact = 1.61;
if  min( [ max( tempFt2plot1 ) max( tempFt2plot2 ) ] ) == 0
  ax.YLim = [ 0 0.1 ];
else
  ax.YLim = [ 0 limFact * min( [ max( tempFt2plot1 ) max( tempFt2plot2 ) ] ) ];
end
p(1).LineStyle = dashtype1;
p(1).LineWidth = 2;
p(2).LineStyle = dashtype2;
p(2).LineWidth = 2;
titlstr = [ ' $$ k_{p,l} = ' num2str( kLow, '%.2f' ) ' n_{p,l}: ' num2str( nLow )...
  '$$; $$ k_{p,u} = ' num2str( kUpp, ' %.2f' ) 'n_{p,u}: ' num2str( nUpp ) '$$'];
title(titlstr)
xlabel('t');ylabel(ylab);
legcell = { ['$$ k_{p,l} $$ : ' plotk1peak ], ...
  [ '$$ k_{p,u} $$ : ' plotk2peak ] };
leg = legend(legcell,'location','best');
leg.Interpreter = 'latex';
% plot all unstable peaks
if ~isempty(disper.kAllUnstableInds)
  numUnstab = length( disper.kAllUnstableInds );
  figure()
  % peak 2
  if length(k1PeakInds) >= length(k2PeakInds)
    allUnstable = reshape( cFtPos( disper.kAllUnstableInds, 1, : ), [numUnstab nt] )' ;
  else
    allUnstable = reshape( cFtPos( 1, disper.kAllUnstableInds, : ), [numUnstab nt] )' ;
  end
  plot( timeRec, allUnstable );
  ylab = 'Amplitude';
  title('All unstable k from linear stab')
  xlabel('t'); ylabel(ylab);
  legCell = cellstr(num2str( [disper.kAllUnstableNs' disper.kAllUnstable'], ...
    'n,k=%.2d k=%.2f') );
  legend( legCell, 'location', 'best');
  if saveMe
    figname = 'kAmpsUnstable';
    savefig( gcf, figname )
    saveas( gcf, figname, 'jpg' )
  end
end
% all peaks
maxC = max(c(:));
minC = min(c(:));
meanC = min(c(:));
if abs( maxC - minC ) / meanC < 1e-2
  maxC = maxC + meanC * 0.01;
  minC = minC - meanC * 0.01;
end
x1 = systemObj.l1 / systemObj.n1 * (0:systemObj.n1-1);
x2 = systemObj.l2 / systemObj.n2 * (0:systemObj.n2-1);
fig3 = figure();
colormap(fig3, viridis )
subplot(2,2,1)
imagesc( x1, x2, c' )
colorbar
xlabel( '$$ x _1 $$ '); ylabel('$$ x_2 $$');
title('C');
axis square
ax = gca;
ax.YDir = 'normal';
ax.YLabel = fliplr(ax.YLabel);
ax.CLim = [minC maxC];
% log(c)
subplot(2,2,2)
imagesc( x1, x2, log(c) );
colorbar
xlabel( '$$ x_1 $$ '); ylabel('$$ x_2 $$');
title('log(c)');
axis square
ax = gca;
ax.YDir = 'normal';
ax.YLabel = fliplr(ax.YLabel);
ax.CLim = log( [minC maxC] ) ;
% cFT
subplot(2,2,3)
imagesc( k2, k1, cFt(:,:,end)' )
colorbar
xlabel( '$$ k _1 $$ '); ylabel('$$ k_2 $$');
title('Full k-space amplitudes');
axis square
ax = gca;
ax.YDir = 'normal';
ax.YLabel = fliplr(ax.YLabel);
% cFt smaller
subplot(2,2,4)
kSub = 1:min( max([ k1PeakInds k2PeakInds ]) + dPeak, min( n1, n2 ) );
imagesc( k2Pos(kSub), k1Pos(kSub), ...
  cFtPos(kSub,kSub,end)' );
colorbar
xlabel( '$$ k _1 $$ '); ylabel('$$ k_2 $$');
title('Subdomain k-space amplitudes');
axis square
ax = gca;
ax.YDir = 'normal';
ax.YLabel = fliplr(ax.YLabel);
% save it
if saveMe
  fig0name = 'kAmpsDisp';
  fig1name = 'kAmpsVsK';
  fig2name = 'kAmpsVsT';
  fig3name = 'kAmpsMap';
  savefig( fig0, fig0name )
  saveas( fig0, fig0name, 'jpg' )
  savefig( fig1, fig1name )
  saveas( fig1, fig1name, 'jpg' )
  savefig( fig2, fig2name )
  saveas( fig2, fig2name, 'jpg' )
  savefig( fig3, fig3name )
  saveas( fig3, fig3name, 'jpg' )
end
