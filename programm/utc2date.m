function [ date_str ] = utc2date( utc_time )
%Converts unix time to date
%   Detailed explanation goes here

% Define start year of unix time calculation
year = 1970;
% Calculate how many seconds elapsed since 0.00 o'clock
day_clock = mod(utc_time,86400);
% Calculate how many days elapsed since 01.01.1970
day_no = floor(double(utc_time)./86400);

% Calculate elapsed hours, min, sec since 0.00 o'clock
hour = floor(day_clock./3600);
min = floor(double(mod(day_clock,3600))./60);
sec = mod(day_clock,60);

% wd = mod(day_no + 4,7);

% Define the number of days in year, considering leap years
ys(1:size(utc_time,2)) = {year_size(year)};
temp = cell2mat(ys);
year_days = temp(1:3:end);

% Reduce day_no by number of days in a year until day_no is less than a year
while day_no > year_days
    day_no = day_no - year_days;
    year = year+1;
    ys(1:size(utc_time,2)) = {year_size(year)};
    temp = cell2mat(ys);
    year_days = temp(1:3:end);
end

y(1:size(utc_time,2)) = year;
m(1:size(utc_time,2)) = 1;

% Get the number of days in a year, the elapsed days since 01.01. of that
% year, and the number of days in a month starting with January
j(1:size(utc_time,2)) = {year_size(year, m)};
temp = cell2mat(j);
remaining_days = temp(2:3:end);
day_a_month = temp(3:3:end);
% Loop until remaining day_no is less than elapsed days since 01.01. 
while day_no >= remaining_days;
    if (double(day_no) - day_a_month) <= 0
        break;
    else
% Subtract number of days in a month        
        day_no = day_no - day_a_month;
    end
% Increase number of elapsed month since 01.01.
    m = m + 1;
    j(1:size(utc_time,2)) = {year_size(year, m)};
    temp = cell2mat(j);
    remaining_days = temp(2:3:end);
    day_a_month = temp(3:3:end);
end
d = double(day_no)+1;
result = double([y; m; d; hour; min; sec]);
date_str(1:size(utc_time,2)) = cellstr(datestr(result',0))';
end

