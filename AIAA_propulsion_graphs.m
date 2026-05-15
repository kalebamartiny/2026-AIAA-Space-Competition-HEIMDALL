clc; clear; close all;

rho_ox = 1390; % Density of Oxidizer (e.g., MON3 in kg/m^3)
rho_fuel = 874; % Density of Fuel (e.g., MMH in kg/m^3)

fuel_vol = [6.4999 6.4338 6.3267 6.1826 6.6829];
ox_vol = [6.7844 6.7154 6.6036 6.4532 6.9753];

fuel_m3 = fuel_vol ./ 1000;
ox_m3 = ox_vol ./ 1000;

fuel_mass = rho_fuel .* fuel_m3;
ox_mass = rho_ox .* ox_m3;

disp(fuel_mass)
disp(ox_mass)

% Electric
e_name = {'ST-25', 'BHT-600', 'SHT1500', 'ST-100', 'BHT-6000 HT', 'BHT-6000 HI'};
e_dry = [642.24 642.24 642.24 642.24 642.24 642.24];
e_prop = [2.943937321 3.154172115 2.453365822 2.597655008 2.176513072 1.6308407];
e = [e_dry; e_prop]';

tiledlayout(1, 3)

% Electric Plot
nexttile;
bar(e, 'stacked')
ylim([640 665])
title('Electric Hall Effect', 'FontSize', 14)
set(gca, 'XTick', 1:numel(e_name), 'XTickLabel', e_name)
ylabel('Mass (kg)', 'FontSize', 12, 'FontWeight', 'bold')
legend({'Dry Mass', 'Xenon'}, 'Location', 'northeast')
ax = gca;
ax.XGrid = false;
ax.YGrid = true;
ax.GridLineStyle = '-';
ax.GridAlpha = 0.15;
ax.Box = 'off';
set(ax, 'FontSize', 12, 'FontWeight', 'bold') % make axis tick labels bold and 12pt

% Monopropellant
m_name = {'Rafael 25N', 'MT-8A', 'MT-2', 'MRE-15', 'MRE-5.0'};
m_dry = [642.24 642.24 642.24 642.24 642.24];
m_prop = [20.04905928 20.80471612 20.23277908 19.34638116 19.01319773];
m_pressurant = [0.153423235 0.159205816 0.15482913 0.148046067 0.145496417];
m = [m_dry; m_prop; m_pressurant]';

% Monoprop Plot
nexttile;
bar(m, 'stacked')
ylim([640 665])
title('Monopropellant', 'FontSize', 14)
set(gca, 'XTick', 1:numel(m_name), 'XTickLabel', m_name)
xlabel('Thruster Name', 'FontSize', 12, 'FontWeight', 'bold')
ylabel('Mass (kg)', 'FontSize', 12, 'FontWeight', 'bold')
legend({'Dry Mass', 'Hydrazine', 'Helium'}, 'Location', 'northeast')
ax = gca;
ax.XGrid = false;
ax.YGrid = true;
ax.GridLineStyle = '-';
ax.GridAlpha = 0.15;
ax.Box = 'off';
set(ax, 'FontSize', 12, 'FontWeight', 'bold')

% Bipropellant
b_name = {'S10-13', 'BT-6', 'Halcyon', 'DST-11H', '5 lbf Columbium'};
b_dry = [642.24 642.24 642.24 642.24 642.24];
b_fuel = fuel_mass; 
b_ox = ox_mass;
b = [b_dry; b_fuel; b_ox]';

% Biprop Plot
nexttile;
bar(b, 'stacked')
ylim([640 665])
title('Bipropellant', 'FontSize', 14)
set(gca, 'XTick', 1:numel(b_name), 'XTickLabel', b_name)
ylabel('Mass (kg)', 'FontSize', 12, 'FontWeight', 'bold')
legend({'Dry Mass', 'MMH', 'MON3'}, 'Location', 'northeast')
ax = gca;
ax.XGrid = false;
ax.YGrid = true;
ax.GridLineStyle = '-';
ax.GridAlpha = 0.15;
ax.Box = 'off';
set(ax, 'FontSize', 12, 'FontWeight', 'bold')




























