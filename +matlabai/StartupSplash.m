classdef StartupSplash < matlabai.StartupPresentation
    % Compatibility name; new launches use StartupPresentation directly.
    methods
        function splash=StartupSplash(varargin)
            splash@matlabai.StartupPresentation(varargin{:});
        end
    end
end
