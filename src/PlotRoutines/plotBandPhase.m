function plotBandPhase( bandTable, featureStr, plotIN, plotTheory )
% plot phase
cIN = 1.5;
% set-up figure
fig = figure();
fig.WindowStyle = 'normal';
fig.Position = [360 278 560 420];
% grab feature
fPlot = bandTable.fd;
cPlot = bandTable.c;
if strcmp( featureStr, 'cMax' )
  featurePlot = bandTable.cMax;
  % plot failed
  threshold = 1.01;
  failInds = featurePlot < threshold .* cPlot;
elseif strcmp( featureStr, 'cFWHM' )
  featurePlot = bandTable.cFWHM;
  % plot failed
  threshold = 0.99;
  failInds = featurePlot > threshold * max( featurePlot ) ;
end
% Scaled Pe and concentration
xLabel = 'Concentration $$  C^* $$';
yLabel = 'P\''eclet Number $$ Pe $$';
c = linspace( 1.5, 1.4*1.5 );
cS = c/cIN;
cTheory2plot = c;
fUnstable = 12 * ( cS.^2 - 1 )  .* ( cS + 1 ) .^2 ./ ...
  ( cS .^ 2 + cS - 1 ) .^ 2; % actve nematic
%fUnstable2 = sqrt( ( cS.^2 - 1 ) ); % self-regulation
plotPhaseDiagram( cPlot, fPlot, featurePlot, failInds, cTheory2plot, fUnstable,...
  plotIN, plotTheory, xLabel, yLabel)

%% functions
  function plotPhaseDiagram( cPlot, fPlot, feature2plot, failInds, cTheory2plot, fUnstable,...
      plotIN, plotTheory, xLabel, yLabel)
    % theory  lines
    circleSize = 75;
    lineIN = ':';
    lineTheory = '-';
    lineColorIN = [0 0 0];
    lineColorTheory = [0 0 0];
    scatterMarkSize = 10;
    % phase diagram
    ax = gca;
    axis square
    hold on
    legCell = {'Homo.', 'Band'};
    p = scatter( cPlot(failInds), fPlot(failInds), scatterMarkSize, ...
      feature2plot(failInds) );
    p.Marker = 'o';
    p.SizeData = circleSize;
    % plot success
    p = scatter( cPlot(~failInds), fPlot(~failInds), scatterMarkSize,...
      feature2plot(~failInds), 'filled' );
    p.Marker = 'o';
    p.SizeData =  circleSize;
    % plot IN transtion
    if plotIN
      bigSlope = 1000000;
      plot( cTheory2plot, bigSlope * (cTheory2plot - cTheory2plot(1)), ...
        'Color', lineColorIN, 'LineStyle', lineIN )
      legCell{end+1} = 'IN trans.';
    end
    if plotTheory
      plot( cTheory2plot, fUnstable, ...
        'Color', lineColorTheory, 'LineStyle', lineTheory )
      % plot IN transtion
      bigSlope = 10000;
      plot( cTheory2plot, bigSlope * (cTheory2plot - cTheory2plot(1)), ...
        'Color', lineColorIN, 'LineStyle', lineIN )
      % legend
      legCell{end+1} = 'Theory';
      legPos = [0.5570 0.6946 0.2003 0.2195];
    else
      legPos = [0.5918 0.8005 0.1652 0.1136];
      cTheory2plot = cPlot;
    end
    % axis
    % set-up axis properties
    h = colorbar;
    h.TickLabelInterpreter = 'latex';
    hold off
    xlabel(ax, xLabel);
    ylabel(ax, yLabel);
    ax.XLim = [min( [cTheory2plot(:); cPlot(:)] ), ...
      max([cTheory2plot(:); cPlot(:)]) ];
    ax.YLim = [min(fPlot) max(fPlot) ];
    ax.XAxis.TickLabelInterpreter = 'latex';
    ax.YAxis.TickLabelInterpreter = 'latex';
    box on
    % legend Turn off for now
    if 0
      [hl] = legend(legCell, ...
        'location', 'best');
      hl.Interpreter = 'latex';
      hl.Position = legPos;
    end
    textFontSize = 30;
    th1 = text( 1.35, 17.5, 'I');
    th2 = text( 1.65, 2, 'N' );
    th3 = text( 1.65, 17.5, 'B' );
    th1.FontSize = textFontSize;
    th2.FontSize = textFontSize;
    th3.FontSize = textFontSize;
  end
end
