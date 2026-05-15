% This code is to calculate the needed delta V's to position our satellite
% on Earth's L4. We'll be doing something called phasing maneuver. Since we
% want to be ahead of Earth, we can't increase our speed, that would
% increase our orbit's period, what we need to do is get into a lower
% heliocentric orbit, which would increase our heliocentric velocity with
% respect to Earth's and after 1 full rotation, we induce a delta v to
% position ourselves in L4. 

% Constants:
a_Earth = 1.496e8;
miu_sun = 1.32e11;
miu_Earth = 398600; 
r_parking = 300;
r_Earth = 6378; 
r = r_Earth + r_parking; 
delta_t = 365.25;

% constants to calculate Delta_v losses due to solar radiation
t = 31536000*15; % duration of the whole duration (around 15 years) 
S_o = 1361; % Solar constant (w/m^2) 
c = 3e8; % speed of light
Area = 15; % area of the spacecraft, assumed to be 15 m^2
reflectivity = 0.5;
beta = 0; % the angle that the solar radiation hits the s/c assumed to be straight toward the s/c
m = 168.396; % Approx mass of the s/c

% Calculating delta V losses due to solar radiation: 
F_sr = (S_o/c)*Area*(1 + reflectivity)*cosd(0);

% the acceleration of the particles hitting the s/c
a_sr = F_sr/m;
delta_Vloss_solar =(a_sr * t)/1000;

                 %%% Propulsion %%%
% Need to find propellant mass, I will assume that to do this maneuver
% we'll use chemical propulsion since it's the one that can provide those
% high delta V impulses required for the phasing maneuver

% Calculate the propellant mass required using the Tsiolkovsky rocket equation
Isp = 300; % specific impulse in seconds
g0 = 9.81/1000; % standard gravity in km/s^2
m_dry = m * 3.74; % Using table A-2 from leasson 7, the average payload represents the 26.7% of the whole weight of the spacecraft (excluding fuel) 


duration = 1:5;
DV1_array = zeros(1,5);
DV2_array = zeros(1,5);
Total_dV_array = zeros(1,5); 
propellanr_mass_array = zeros(1,5);
                      
for n = 1:5  % Asumming mission duration between 1 to 5 years: 
    
    % calculating phasing period, the value of theta and theta_earth changes, it
    % depends on the mission duration. 
    theta = (n * 360) + 60; %since L4 is 60 degrees ahead of Earth. This value changes depending on your mission duration, if we say 2 year phasing maneuver, then we would do two rotations (720) plus 60 degrees ans so on
    theta_Earth = n * 360; % for 2 year mission duration, then it would be 720 and so on 

    Tph = delta_t*(theta_Earth/theta);
    Tph_seconds = Tph * 86400;

    % Dependingon our budget, we can change the duration of the maneuver. Which is why I did this for loop 

    % Get the semimejaor axis of this new orbit: 
    a_ph = (miu_sun*(Tph_seconds/(2*pi))^2)^(1/3);
    a_ph_au = a_ph/1.496e8;

    % Finding heliocentric Velocity at departure: 
    Vc1 = sqrt(miu_sun*((2/a_Earth)-(1/a_ph)));

    % Calculating Earth's velocity: 
    V_Earth = sqrt(miu_sun/a_Earth);

    % Calculating hyperbolic excess velocity: 
    V_infinity = V_Earth - Vc1;

    % Get scape Velocity: 
    V_escape = sqrt(2 * miu_Earth / r);

    % The velocity to stay in orbit is: 
    V_orbit = sqrt(miu_Earth / r);

    % Since our ecliptic an orbital plane are not coplanar, we need to account
    % for this difference in angle, we found that the difference is 5 degrees,
    % so we need to use law of cosines to find the accurate delta V: 
    % Calculate the energy needed to drift to L4: 
    Vp_hyp = sqrt((V_infinity^2) + (2*miu_Earth/r));
    delta_V1 = sqrt((Vp_hyp^2) + (V_orbit^2) - (2*(Vp_hyp * V_orbit)*cosd(5)));

    % This is the value of the first burn to get to a smaller orbit. 

    % Calculate the second delta V needed to position at L4 after the first burn
    delta_V2 = V_Earth - Vc1;
    
    % Total Budget
    total_delta_V = delta_V1 + delta_V2 + delta_Vloss_solar;

    % propulsion 
    m_wet = m_dry * (exp((total_delta_V) / (Isp * g0)));
    propellant_mass = m_wet - m_dry; % Calculate the propellant mass required for the maneuver

    DV1_array(n) = delta_V1;
    DV2_array(n) = delta_V2; 
    Total_dV_array(n) = total_delta_V; % here you just store the values in the arrays created before
    propellanr_mass_array(n) = propellant_mass; 

   
    fprintf('Maneuver Duration:    %d Year(s)\n', n);
    fprintf('  Phasing Orbit Time: %.2f days\n', Tph);
    fprintf('  Departure Burn (dV1): %.3f km/s\n', delta_V1);
    fprintf('  Arrival Burn (dV2):   %.3f km/s\n', delta_V2);
    fprintf('  TOTAL DELTA-V:        %.3f km/s\n', total_delta_V);
    fprintf('  Propellant Mass Required: %.2f kg\n', propellant_mass);
    fprintf('----------------------------------------\n');

end

figure;  
hold on;
plot(duration, Total_dV_array, '-o', 'LineWidth', 2, 'DisplayName', 'Total Delta-V');
plot(duration, DV1_array, '--s', 'LineWidth', 1.5, 'DisplayName', 'Departure Burn (dV1)');
plot(duration, DV2_array, '--^', 'LineWidth', 1.5, 'DisplayName', 'Arrival Burn (dV2)');
hold off;
grid on;
title('Delta-V Requirements vs. Phasing Maneuver Duration (Earth L4)');
xlabel('Phasing Maneuver Duration (Years)');
ylabel('Required \Delta V (km/s)');
xticks(duration); 
legend('Location', 'northeast'); 

figure;
plot(duration, propellanr_mass_array, '-o', 'LineWidth', 2, 'DisplayName', 'Total Propellant Mass');
grid on;
title('Propellant Mass Required vs Phasing Mneuver Duration (Earth L4)');
xlabel('Phasing Maneuver Duration (Years)');
ylabel('Propellant Mass (kg)');
xticks(duration); 
legend('Location', 'northeast'); 

