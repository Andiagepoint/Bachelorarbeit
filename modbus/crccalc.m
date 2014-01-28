function [ txdata_hex ] = crc_calc( modbus_pud_hex )
%This function calculates the cyclic redundancy check value. Its input
%are the message bytes in hexadecimal format, i.e. 01010000000A
%   Detailed explanation goes here

%Determine the number of bits the given message has
databits = size(modbus_pud_hex,2)*4;

%Convert the hexadecimal input into a binary format
datastream = hexToBinaryVector(modbus_pud_hex,databits);

%Define the shiftregister 
CRCshiftreg_bin = hexToBinaryVector('FFFF',16);

%Define the generator polynom 
CRCgenpolynom_bin = hexToBinaryVector('A001',16);

%Extract byte by byte from datastream and represent it as a 16bit word
n = 8;
m = 1;
for s = 1 : ceil(size(modbus_pud_hex,2)/2)
% data_byte will be the first byte for s = 1 in logical format
    data_byte = datastream(1,m:n);
% add zeros to make it a 16 bit word    
    data_16bit = logical([zeros(1,8) data_byte]);
% xor the word with the shift register    
    crc_erg = xor(data_16bit,CRCshiftreg_bin);
% for all 8 bits of the data_byte do    
% shift word to the left for each left bit = 0 until bit = 1, refill word
% with zeros from the right side. If bit = 1 xor the word with the
% CRCgenpolynom.
    for t = 1 : 8
        if crc_erg(1,end) == 0
            crc_erg = logical([0 crc_erg(1,1:end-1)]);
        else
            crc_erg = xor(logical([0 crc_erg(1,1:end-1)]),CRCgenpolynom_bin);
        end
    end
% assign the result to the shift register and increase the byte counter    
    CRCshiftreg_bin = crc_erg;
    m = m + 8;
    n = n + 8;
end
% convert the result in a 2 byte hex word and combine PDU and crc check to
% ADU
crc_16 = dec2hex(bin2dec(sprintf('%i',CRCshiftreg_bin)),4);
txdata_hex = strcat(modbus_pud_hex,crc_16);
end

