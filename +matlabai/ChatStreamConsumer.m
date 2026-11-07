classdef ChatStreamConsumer < matlab.net.http.io.ContentConsumer
    properties (SetAccess = private)
        Parser
        Raw = uint8([])
    end
    properties (Access = private)
        ShouldStop
    end
    methods
        function consumer = ChatStreamConsumer(onText, shouldStop)
            consumer.Parser = matlabai.ChatStreamParser(onText);
            consumer.ShouldStop = shouldStop;
        end
        function [length, stop] = putData(consumer, bytes)
            length = numel(bytes);
            stop = false;
            if consumer.ShouldStop(), error('MatlabAI:Cancelled', '已停止生成。'); end
            if isempty(bytes)
                consumer.Parser.finish();
            else
                consumer.Parser.feed(bytes);
            end
            if consumer.Parser.SawEvent
                % SSE has already been parsed. Do not retain another full wire copy.
                consumer.Raw = uint8([]);
            else
                % Only non-streaming JSON fallback needs the raw body.
                consumer.Raw = [consumer.Raw, reshape(uint8(bytes),1,[])];
            end
        end
    end
    methods (Access = protected)
        function length = start(~)
            length = [];
        end
    end
end
