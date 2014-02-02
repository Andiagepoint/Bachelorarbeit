function [ check, error_msg  ] = crc_check( rxdata )
%Calculates the CRC sum from the slave response
%   Detailed explanation goes here
msg = '';
% for each byte in the response message convert dec to hex values and
% concatenate it to the message in hex format
for t = 1:(size(rxdata,1)-2)
hex_val = dec2hex(rxdata(t),2);
msg = strcat(msg,hex_val);
end
% extract the crc checksum and calculate the crc
% checksum from the response message
crc_checksum = strcat(dec2hex(rxdata(end-1,1),2),dec2hex(rxdata(end,1),2));
response_msg = crc_calc(msg);
% compare calculated checksum and recived checksum and assign flag value
if strcmp(response_msg(end-3:end),crc_checksum) == 1 
    check = 1;
    error_msg = [];
else
    check = 0;
    error_msg = 'CRC Check war ungueltig';
end
end

