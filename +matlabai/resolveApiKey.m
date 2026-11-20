function key=resolveApiKey(endpoint,explicitKey)
% Resolve only the environment key belonging to the selected official host.
key=strtrim(char(string(explicitKey)));
if ~isempty(key),return;end
key=strtrim(getenv('MATLAB_AI_API_KEY'));
if ~isempty(key),return;end
profile=matlabai.providerProfile(endpoint);
if ~isempty(profile.keyEnvironment),key=strtrim(getenv(profile.keyEnvironment));end
end
