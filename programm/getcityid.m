function [ city_id_correct, c_id, lng, lat ] = get_city_id( cityname )
%Gets the city id from the city list
%   Detailed explanation goes here
citylist = evalin('base','city_list');
citylist.CityName = nominal(citylist.CityName);
city_id_dataset = citylist(citylist.CityName == cityname,:);
if isempty(city_id_dataset)
    city_id_correct = 0;
    c_id = '';
    lng = '';
    lat = '';
else
    c_id = city_id_dataset{:,1};
    lng = city_id_dataset{:,3};
    lat = city_id_dataset{:,4};
    city_id_correct = 1;
end
end

