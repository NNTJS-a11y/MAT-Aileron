function catalog = blockCatalog
catalog = struct;
catalog.Step = entry('simulink/Sources/Step', struct('Time', 'scalar', 'Before', 'scalar', 'After', 'scalar'));
catalog.Constant = entry('simulink/Sources/Constant', struct('Value', 'scalar'));
catalog.Sine = entry('simulink/Sources/Sine Wave', struct('Amplitude', 'scalar', 'Frequency', 'scalar', 'Phase', 'scalar', 'Bias', 'scalar'));
catalog.Sum = entry('simulink/Math Operations/Sum', struct('Inputs', 'signs'));
catalog.Gain = entry('simulink/Math Operations/Gain', struct('Gain', 'scalar'));
catalog.TransferFcn = entry('simulink/Continuous/Transfer Fcn', struct('Numerator', 'vector', 'Denominator', 'vector'));
catalog.Integrator = entry('simulink/Continuous/Integrator', struct('InitialCondition', 'scalar'));
catalog.PID = entry('simulink/Continuous/PID Controller', struct('P', 'scalar', 'I', 'scalar', 'D', 'scalar', 'N', 'scalar'));
catalog.Saturation = entry('simulink/Discontinuities/Saturation', struct('UpperLimit', 'scalar', 'LowerLimit', 'scalar'));
catalog.Scope = entry('simulink/Sinks/Scope', struct);
end

function result = entry(path, parameters)
result = struct('path', path, 'parameters', parameters);
end
