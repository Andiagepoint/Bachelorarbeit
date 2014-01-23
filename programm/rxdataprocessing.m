function [ response_data, crc_check_value, response_msg ] = ...
           rxdata_processing( rxdata, modbus_msg, field_name, res, con_qual, lng, lat )
%Processing the received rxdata from serial interface
%   Rxdata contains the response from the MODBUS server, which has to be
%   processed here and in a subsequent function.

not_done = 1;

while not_done == 1
    if isempty(rxdata)
        error('No data received! Check if server is available!');
%         response_data = [];
%         crc_check_value = 0;
%         response_msg = [];
    else
        func_code = dec2hex(rxdata(2),2);
        fcode_error = fcode_check(func_code);

        if fcode_error == 1
            exception_code = dec2hex(rxdata(3),2);
            switch exception_code
                case '01'
                    error('Exception Code 01 -> Function code not supported');
                case '02'
                    error('Exception Code 02 -> Output address not valid');
                case '03'
                    error(['Exception Code 03 -> Quantity of outputs exceeds'...
                           'range 0x0001 and 0x07D0']);
                case '04'
                    error('Exception Code 04 -> Failure during reading discret'...
                          'outputs');
            end
%             response_data = [];
%             crc_check_value = 0;
%             response_msg = [];
        else
%             pause(0.25)
%             err_msg = [];
            switch rxdata(2)
                case 1
%                     byte_count = rxdata(3);
                    response_data = rxdata(4);
                    [crc_check_value, response_msg] = crc_check(rxdata);
                case 3
%                     byte_count = rxdata(3);
%                     if byte_count > (size(rxdata,1)-5)
%                     [ value ] = send_and_receive_data( modbus_msg, field_name );
%                     end
                    response_data = data_processing( rxdata(4:end-2), field_name,...
                                                     res, con_qual, lng, lat );
                    [crc_check_value, response_msg] = crc_check(rxdata);
                case 6
                    response_data = dec2hex(rxdata(5:6),4);
                    [crc_check_value, response_msg] = crc_check(rxdata);
            end
        end
    end

    if (isempty(response_data) || isempty(crc_check_value) || isempty(response_msg))
        not_done = 1;
    else
        not_done = 0;
    end

end
end

