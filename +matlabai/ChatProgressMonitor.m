classdef ChatProgressMonitor < matlab.net.http.ProgressMonitor
    properties
        Direction matlab.net.http.MessageType
        Value uint64
    end
    properties (Access = private)
        ShouldStop
        Started
    end
    methods
        function monitor = ChatProgressMonitor(shouldStop)
            monitor.ShouldStop = shouldStop;
            monitor.Started = tic;
            monitor.Interval = 0.1;
        end
        function set.Value(monitor, value)
            monitor.Value = value;
            drawnow limitrate;
            limits = matlabai.responseLimits;
            if (monitor.ShouldStop() || toc(monitor.Started) > limits.totalSeconds) && ~isempty(monitor.CancelFcn)
                monitor.CancelFcn();
            end
        end
        function done(~)
        end
    end
end
