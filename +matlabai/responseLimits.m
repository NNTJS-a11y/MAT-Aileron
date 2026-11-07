function limits = responseLimits
% Separate SSE wire overhead from useful answer text.
limits = struct('wireBytes',32*1024*1024,'textCharacters',500000, ...
    'contextCharacters',800000,'totalSeconds',600);
end
