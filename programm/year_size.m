function [ ys  ] = year_size( varargin )
%UNTITLED3 Summary of this function goes here
%   Detailed explanation goes here
if size(varargin,2) == 1
    year = varargin{1};
    mon = 1;
else
    year = varargin{1};
    mon = varargin{2};
end

ly_table = {31, 29, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31};
nly_table = {31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31};


ly_table_cum = {335, 305, 274, 244 ,213, 182, 152, 121, 91, 60, 31, 0};
nly_table_cum = {334, 304, 273, 243, 212, 181, 151, 120, 90, 59, 31, 0};

if mod(year,400) == 0
    ys(1) = 366;
    ys(2) = ly_table_cum{mon};
    ys(3) = ly_table{mon};
elseif mod(year,100) == 0
    ys(1) = 365;
    ys(2) = nly_table_cum{mon};
    ys(3) = nly_table{mon};
elseif mod(year, 4) == 0
    ys(1) = 366;
    ys(2) = ly_table_cum{mon};
    ys(3) = ly_table{mon};
else
    ys(1) = 365;
    ys(2) = nly_table_cum{mon};
    ys(3) = nly_table{mon};
end
end

