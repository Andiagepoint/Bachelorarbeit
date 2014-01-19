function [ value ] = send_and_receive_data( modbus_msg, field_name, res,...
                                            con_qual, lng, lat )
%Writes and reads modbus message on serial interface
%   Detailed explanation goes here

% Makes serial interfaces available in local workspace
serial_interface = evalin('base','serial_interface');

% Formats the modbus message into serial interface readable structure
txdata = format_modbus_msg(modbus_msg);

% Write message 
fwrite(serial_interface,txdata);

pause(1);

% Check how many bytes have been received on serial interface
if serial_interface.BytesAvailable == 0
    bytes_num = 8;
else
    bytes_num = serial_interface.BytesAvailable;
end

% Read message data as unsigned values
[rxdata] = fread(serial_interface, bytes_num, 'uint8');

% Call rxdata processing
[value, error_msg] = rxdata_processing( rxdata, modbus_msg, field_name, res,...
                                        con_qual, lng, lat );

end

