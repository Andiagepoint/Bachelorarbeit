function [ ] = write_com_set( device_id, request_value_list, reg_add_list, cnt )
%Write single value to holding register
%   Detailed explanation goes here

% Code for writing a single value to the holding register
fcode_ws_reg                = '06';
% Create progress bar
wb                          = waitbar(0,'Please wait while writing to registers ...');
% Convert dec value to 2 byte hex value
request_value_list          = dec2hex(request_value_list,4);
waitbar(1/3,wb)
% Receive register address to write value into
[reg_add, field_name]       = get_reg_address(char(reg_add_list));
% Generate modbus pdu
modbus_msg                  = strcat(device_id, fcode_ws_reg, reg_add, request_value_list);
waitbar(2/3,wb)
% Generate modbus adu
msg                         = crc_calc(char(modbus_msg));
% Send message
[rxdata]                    = send_and_receive_data(msg, field_name, '', '', '', '', cnt, '');
waitbar(3/3,wb)
% Close progress bar
close(wb)

end

