function [ ] = open_serial_port( com_address, baudrate, databits, parity, stopbit )
%This function establishes the serial interface for the modbus
%communication channel.
%   For the HWK Kompakt COM address has to be COM6, Baudrate = 19200,
%   Databits = 8, Parity = 'even' and Stopbit = 1  

% Creates the serial interface
serial_interface = serial(com_address,'BaudRate',baudrate,'DataBits', ...
                          databits,'Parity',parity,'StopBits',stopbit);

% Export variable to base workspace
assignin('base','serial_interface',serial_interface);

% Open the serial interface
fopen(serial_interface);

fprintf(['Serielle Schnittstelle wurde eingerichtet unter der Variable\n'...
        '"serial_interface"\n']);
end

