function profile = compatibilityProfile(release)
% A single conservative API baseline; never represents another installed runtime.
release = char(release);
token = regexp(release, '^R(202[3-6])([ab])$', 'tokens', 'once');
if isempty(token)
    error('MatlabAI:UnsupportedRelease', '请选择 R2023a 至 R2026b；此范围之外尚未提供兼容策略。');
end
profile = struct('release', release, 'baseline', 'R2023a', ...
    'year', str2double(token{1}), 'half', token{2}, ...
    'runtimeTested', strcmp(release, 'R2024a'), ...
    'liveFormat', '.mlx', 'policy', 'conservative-common-api');
% .mlx avoids depending on the newer plain-text Live Code format.
end
