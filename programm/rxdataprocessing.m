function [ response_data ] = ...
           rxdata_processing( rxdata, modbus_pdu, fc_def, res,...
           con_qual, lng, lat, cnt, lokal_temp )
%Processing the received rxdata from serial interface
%   Rxdata contains the response from the MODBUS server, which has to be
%   processed here and in a subsequent function.

% Initial value for the while loop
not_done = 1;

% The while loop will run three times in the case of no data was received
% an exception code was thrown or crc check failed. 
while not_done == 1
    if isempty(rxdata)
        error_msg = ('No data received! Check if server is available!');
        response_data = [];
        crc_check_value = 0;
    else
        func_code = dec2hex(rxdata(2),2);
        fcode_error = fcode_check(func_code);

        if fcode_error == 1
            exception_code = dec2hex(rxdata(3),2);
            switch exception_code
                case '01'
                    error_msg = ('Exception Code 01 -> Function code not supported');
                case '02'
                    error_msg = ('Exception Code 02 -> Output address not valid');
                case '03'
                    error_msg = (['Exception Code 03 -> Quantity of outputs exceeds'...
                           'range 0x0001 and 0x07D0']);
                case '04'
                    error_msg = (['Exception Code 04 -> Failure during reading discret'...
                          'outputs']);
                otherwise
                    error_msg = ['Unnown exception code: ' exception_code];
            end
            response_data = [];
            crc_check_value = 0;
        else
            error_msg = [];
            switch rxdata(2)
                case 1
                    response_data = rxdata(4);
                    [crc_check_value, error_msg] = crc_check(rxdata);
                case 3
                    response_data = data_processing(rxdata(4:end-2), fc_def,...
                                                 res, con_qual, lng, lat, lokal_temp);
                    [crc_check_value, error_msg] = crc_check(rxdata);
                case 6
                    response_data = dec2hex(rxdata(5:6),4);
                    [crc_check_value, error_msg] = crc_check(rxdata);
            end
        end
    end

    if (isempty(response_data) || isempty(crc_check_value)) && ~isempty(error_msg)
        not_done = 1;
        cnt = cnt + 1;
        if cnt == 3
            error(error_msg);
        else
            send_and_receive_data(modbus_pdu, fc_def, res, con_qual,...
                                  lng, lat, cnt, lokal_temp);
        end
    else
        not_done = 0;
    end

end
end

