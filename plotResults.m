function state = plotResults(simPar, options,state,flag, optimType)
%GAPLOTBESTINDIV Plots the best individual.
%   STATE = GAPLOTBESTINDIV(OPTIONS,STATE,FLAG) plots the best 
%   individual's genome as a histogram, with the number of bins
%   in the histogram equal to the length of the genome.
%
%   Example:
%    Create an options structure that uses GAPLOTBESTINDIV
%    as the plot function
%     options = optimoptions('ga','PlotFcn',@gaplotbestindiv);

%   Copyright 2003-2015 The MathWorks, Inc.
global agentType;
switch optimType
    case 'ga'
        if  size(state.Score,2) > 1
            title('Best Individual Plot: not available','interp','none');
            return;
        end
        [~,i] = min(state.Score);
        genome = state.Population(i,:);
        lattice_ratio   = genome(1);
        genome(1)       = [];
        curScore        = state.Score;
        curGen          = state.Generation;
        curMeanScore    = meanf(curScore);
        curBestScore    = min(curScore);
    case 'fmincon'
        genome          = state;
        lattice_ratio   = genome(1);
        genome(1)       = [];
        curBestScore    = options.fval;
        curGen          = options.iteration;
    case 'patternsearch'
        genome          = options.x;
        lattice_ratio   = genome(1);
        genome(1)       = [];
        curBestScore    = options.fval;
        curGen          = options.iteration;
    case 'test'
        figure();
        genome          = options;
        lattice_ratio  = genome(1);
        genome(1)       = [];
        curBestScore    = 0;
        curGen          = 0;
end
simPar.camera_range     = (simPar.seperation_range) * lattice_ratio;
switch(agentType)
    case 'pinciroli'
        tmp_agent = Agent_pinciroli(Mission(simPar.mission{1}),0,[0 0 0],[0 0]);
    case 'polynomial'
        tmp_agent = Agent_polynomial(Mission(simPar.mission{1}),0,[0 0 0],[0 0]);
    case 'sinusoid'
        tmp_agent = Agent_sinusoid(Mission(simPar.mission{1}),0,[0 0 0],[0 0]);
    case 'simpleNN'
        fakeNet             = struct();
        fakeNet.numLayers   = length(simPar.nnSize);
        fakeNet.IW          = genome(simPar.net.i_IW+2)';
        fakeNet.IB          = genome(simPar.net.i_IB+2)';
        fakeNet.LW          = genome(simPar.net.i_LW+2);
        fakeNet.OB          = genome(simPar.net.i_OB+2);
        tmp_agent           = Agent_simpleNN(Mission(simPar.mission{1}),0,[0 0 0],[0 0]);
        tmp_agent.net       = fakeNet;
        tmp_agent.v_max     = simPar.v_max;
end
tmp_agent.genome            = genome;
tmp_agent.seperation_range  = simPar.seperation_range;
tmp_agent.cam_range         = simPar.camera_range;
x                           = 0:0.05:tmp_agent.cam_range;
switch flag
    case 'init'
        %% Plot field
        subplot(2,2,1);
        hold on;
        axis tight;
        simPar.type             = 'pinciroli';
        simPar.simTime          = 2/simPar.fps;
        [simPar.nnAgents,simPar.polyAgents,simPar.sinusoidAgents] = deal(0);
        [~,sArena]              = sim_calc_cost(simPar,[1.6 0.12 0 0.12], false);
        agentIndices            = sArena.chunkSplit(1:sArena.nAgents,length(simPar.field));
        margin                  = 1.5;
        reso                    = margin * simPar.size(1) / 100;
        l = 1;
        sArena.agents{agentIndices(l,1)}.plotGlobalAttraction(-margin*simPar.size(1)/2:reso:margin*simPar.size(1)/2,-margin*simPar.size(2)/2:reso:margin*simPar.size(2)/2, [0 0 10],false);
        %% Plot best score
        H = subplot(2,2,2);
        hold on;
        axis tight;
        xlabel('Generation','interp','none');
        ylabel('Fitness value','interp','none');
        plotBest = plot(curGen,curBestScore,'.k');
        set(plotBest,'Tag','gaplotbestf');
        if strcmp(optimType,'ga')
            plotMean = plot(curGen,curMeanScore,'.b');
            set(plotMean,'Tag','gaplotmean');
            title(['Best: ',' Mean: '],'interp','none');
        else
            title('Best: ','interp','none');
        end
        grid minor;
        hold on;
        %% Plot agent function
        subplot(2,2,[3 4]);
        hold on;
        axis tight;
        sigma = tmp_agent.seperation_range;
        plot([x(1) 2*sigma],[simPar.v_max simPar.v_max],'--','Color','black');
        plot([x(1) 2*sigma],[-simPar.v_max -simPar.v_max],'--','Color','black');
        plot([sigma sigma],[-simPar.v_max simPar.v_max],'--','Color','black');
        plot([x(1) 2*sigma],[0 0],'-','Color','black');
        y = tmp_agent.getAgentFunction(x);
        h = plot(x,y);
        set(h,'Tag','gaPlotAgentFunction');
        tmp_agent.heading = [0 0];
        loglo = zeros(length(x),1);
        loglo2 = zeros(length(x),1);
        loglo3 = zeros(length(x),1);
        for pl=1:length(x)
            loglo(pl) = tmp_agent.loglo_int(x(pl),-[0 1 0],[0 simPar.v_max 0]);
            loglo2(pl) = tmp_agent.loglo_int([x(pl); x(pl)],-[cos(1/3*pi()) sin(1/3*pi()) 0; cos(2/3*pi()) sin(2/3*pi()) 0],[0 simPar.v_max 0]);
            loglo3(pl) = tmp_agent.loglo_int([x(pl); x(pl); x(pl)],-[cos(1/4*pi()) sin(1/4*pi()) 0; cos(2/4*pi()) sin(2/4*pi()) 0; cos(3/4*pi()) sin(3/4*pi()) 0],[0 simPar.v_max 0]);
        end
        h2 = plot(x,loglo.*simPar.v_max,'--','Color','red');
        set(h2,'Tag','gaPlotAgentFunctionLoGlo');
        h2 = plot(x,loglo2.*simPar.v_max,'-.','Color','red');
        set(h2,'Tag','gaPlotAgentFunctionLoGlo2');
        h2 = plot(x,loglo3.*simPar.v_max,':','Color','red');
        set(h2,'Tag','gaPlotAgentFunctionLoGlo3');
        h3 = text(0.3,0.1*simPar.v_max,strcat(['Lattice ratio: ' num2str(lattice_ratio)]));
        set(h3,'Tag','gaPlotlattice_ratio');
        h4 = text(0.3,0.2*simPar.v_max,strcat(['Viscosity: ' num2str(genome(1)*100) '%']));
        set(h4,'Tag','gaPlotviscosity');
        h5 = text(0.3,0.3*simPar.v_max,strcat(['Local-global: ' num2str(genome(2))]));
        set(h5,'Tag','gaPlotloglo');
        grid minor;
        set(gca,'xlim',[0, tmp_agent.cam_range])
        set(gca,'ylim',[min(0,max(1.1*min(y),-1.1 * simPar.v_max)), 1.1 * simPar.v_max])
        title('Current Best Individual','interp','none')
        xlabel('Distance [m]','interp','none');
        ylabel('Velocity response [m/s]','interp','none');
    case 'iter'
        %% Plot best score
        subplot(2,2,2);
        hold on;
        plotBest    = findobj(get(gca,'Children'),'Tag','gaplotbestf');
        newX        = [get(plotBest,'Xdata') curGen];
        newY        = [get(plotBest,'Ydata') curBestScore];
        bestCol     = newY;
        set(plotBest,'Xdata',newX, 'Ydata',newY);
        if strcmp(optimType,'ga')
            plotMean    = findobj(get(gca,'Children'),'Tag','gaplotmean');
            newY        = [get(plotMean,'Ydata') curMeanScore];
            set(plotMean,'Xdata',newX, 'Ydata',newY);
            set(get(gca,'Title'),'String',sprintf('Best: %g Mean: %g',curBestScore,curMeanScore));
        else
            set(get(gca,'Title'),'String',sprintf('Best: %g',curBestScore));
        end
        set(gca,'xlim',[0,max(1,curGen)]);
        set(gca,'ylim',[max(0,curBestScore*0.95),max(curBestScore+0.1,curBestScore+std(bestCol(max(1,end-20):end)))]);
        %% Plot agent function
        subplot(2,2,[3 4]);
        y = tmp_agent.getAgentFunction(x);
        set(gca,'XLim',[0 simPar.camera_range]);
        set(gca,'ylim',[min(0,max(1.1*min(y),-1.1 * simPar.v_max)), 1.1 * simPar.v_max])
        hold on;
        h = findobj(get(gca,'Children'),'Tag','gaPlotAgentFunction');
        set(h,'Ydata',y);
        set(h,'Xdata',x);
        h2 = findobj(get(gca,'Children'),'Tag','gaPlotAgentFunctionLoGlo');
        tmp_agent.heading = [0 0];
        loglo = zeros(length(x),1);
        loglo2 = zeros(length(x),1);
        loglo3 = zeros(length(x),1);
        for pl=1:length(x)
            loglo(pl) = tmp_agent.loglo_int(x(pl),-[0 1 0],[0 simPar.v_max 0]);
            loglo2(pl) = tmp_agent.loglo_int([x(pl); x(pl)],-[cos(1/3*pi()) sin(1/3*pi()) 0; cos(2/3*pi()) sin(2/3*pi()) 0],[0 simPar.v_max 0]);
            loglo3(pl) = tmp_agent.loglo_int([x(pl); x(pl); x(pl)],-[cos(1/4*pi()) sin(1/4*pi()) 0; cos(2/4*pi()) sin(2/4*pi()) 0; cos(3/4*pi()) sin(3/4*pi()) 0],[0 simPar.v_max 0]);
        end
        set(h2,'Ydata',loglo.*simPar.v_max);
        set(h2,'Xdata',x);
        h2 = findobj(get(gca,'Children'),'Tag','gaPlotAgentFunctionLoGlo2');
        set(h2,'Ydata',loglo2.*simPar.v_max);
        set(h2,'Xdata',x);
        h2 = findobj(get(gca,'Children'),'Tag','gaPlotAgentFunctionLoGlo3');
        set(h2,'Ydata',loglo3.*simPar.v_max);
        set(h2,'Xdata',x);
        h3 = findobj(get(gca,'Children'),'Tag','gaPlotlattice_ratio');
        set(h3,'String',strcat(['Lattice ratio: ' num2str(lattice_ratio)]));
        h4 = findobj(get(gca,'Children'),'Tag','gaPlotviscosity');
        set(h4,'String',strcat(['Viscosity: ' num2str(genome(1)*100) '%']));
        h5 = findobj(get(gca,'Children'),'Tag','gaPlotloglo');
        set(h5,'String',strcat(['Local-global: ' num2str(genome(2))]));
    case 'done'
        hold off
        %% Plot best score
%         if strcmp(optimType,'ga')
%             LegnD = legend('Best fitness','Mean fitness');
%             set(LegnD,'FontSize',8);
%         end
end
if strcmp(optimType,'fmincon') || strcmp(optimType,'patternsearch')
    state = false;
end
end

%------------------------------------------------
function m = meanf(x)
nans = isnan(x);
x(nans) = 0;
n = sum(~nans);
n(n==0) = NaN; % prevent divideByZero warnings
% Sum up non-NaNs, and divide by the number of non-NaNs.
m = sum(x) ./ n;
end