function [ timevec ] = tvector(f_c_d, d_p, varargin )
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here
if strcmp(f_c_d,'mittlere_temp_prog') ~= 1 
    switch varargin{2}
        case 'morgen'
           timevec      = [d_p, 0 0 0];
        case 'vormittag'
           timevec      = [d_p, 6 0 0];
        case 'nachmittag'
           timevec      = [d_p, 12 0 0];
        case 'abend'    
           timevec      = [d_p, 18 0 0];
    end
else
    switch varargin{1}
        case 'am0_00'
           timevec = [d_p, 0 0 0]; 
        case 'am01_00'
           timevec = [d_p, 1 0 0];
        case 'am02_00'
           timevec = [d_p, 2 0 0]; 
        case 'am03_00'
           timevec = [d_p, 3 0 0]; 
        case 'am04_00'
           timevec = [d_p, 4 0 0]; 
        case 'am05_00'
           timevec = [d_p, 5 0 0]; 
        case 'am06_00'
           timevec = [d_p, 6 0 0]; 
        case 'am07_00'
           timevec = [d_p, 7 0 0]; 
        case 'am08_00'
           timevec = [d_p, 8 0 0]; 
        case 'am09_00'
           timevec = [d_p, 9 0 0]; 
        case 'am10_00'
           timevec = [d_p, 10 0 0]; 
        case 'am11_00'
           timevec = [d_p, 11 0 0]; 
        case 'am12_00'
           timevec = [d_p, 12 0 0]; 
        case 'pm01_00'
           timevec = [d_p, 13 0 0]; 
        case 'pm02_00'
           timevec = [d_p, 14 0 0]; 
        case 'pm03_00'
           timevec = [d_p, 15 0 0]; 
        case 'pm04_00'
           timevec = [d_p, 16 0 0]; 
        case 'pm05_00'
           timevec = [d_p, 17 0 0]; 
        case 'pm06_00'
           timevec = [d_p, 18 0 0]; 
        case 'pm07_00'
           timevec = [d_p, 19 0 0]; 
        case 'pm08_00'
           timevec = [d_p, 20 0 0]; 
        case 'pm09_00'
           timevec = [d_p, 21 0 0]; 
        case 'pm10_00'
           timevec = [d_p, 22 0 0]; 
        case 'pm11_00'   
           timevec = [d_p, 23 0 0]; 
    end
end

end

