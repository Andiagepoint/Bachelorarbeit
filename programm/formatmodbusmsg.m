function [ txdata ] = format_modbus_msg( modbus_msg_crc )
%Format modbus pdu to 'fwrite' readable structure
%   Detailed explanation goes here
for e = 2:2:(size(modbus_msg_crc,2)-2)
    if e == 2
        temp1 = modbus_msg_crc(1,1:e);
        temp2 = modbus_msg_crc(1,e+1:end);
        string = strcat(temp1,':',temp2);
    else
        temp2 = modbus_msg_crc(1,e+1:end);
        string = strcat(string(1,1:(size(string,2)-size(temp2,2))),':',temp2);
    end
end
txdata = regexp(string,':','split');
txdata = hex2dec(txdata);
end
