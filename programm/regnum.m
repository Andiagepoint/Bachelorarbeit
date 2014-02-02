function [ num_reg ] = reg_num( start_address, end_address)
%Calculates the difference between start and end register number
%   Detailed explanation goes here
if hex2dec(start_address) > hex2dec(end_address) 
    error('Startadresse des Registers ist groesser als Endaddresse!','Eingabefehler');
else
    num_reg = dec2hex(hex2dec(end_address)-hex2dec(start_address)+1,4);
end
end
