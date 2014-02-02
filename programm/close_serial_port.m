function [ ] = close_serial_port( )
% This function is shutting down the modbus communication channel
%   Detailed explanation goes here

% Clear serial port in base workspace
evalin('base','delete(serial_interface)');
evalin('base','clear serial_interface');

% Clear all serial ports available
t = evalin('base', 'instrfind');
if ~isempty(t)
    fclose(t);
    delete(t);
    clear t;
end

% Send message that all serial ports are cleared now
fprintf('Serielle Schnittstelle wurde geschlossen.\n')

end

