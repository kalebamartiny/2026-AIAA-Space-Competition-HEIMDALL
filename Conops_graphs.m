year=[1:5];
days=(360-60./year)/360*365.25;

a_Earth=147*10^6;
w_Earth=0.98562628;

mu_Earth=3.986*10^5;
mu_Sun=1.327*10^11;

orbital_period=days*24*60*60;
a=((orbital_period/(2*pi)).^2*mu_Sun).^(1/3);

r_alpha=a_Earth;
V_alpha=sqrt(mu_Sun/r_alpha)*sqrt(2./(1+r_alpha./(2*a-r_alpha)));
V_Earth=sqrt(mu_Sun/r_alpha);
V_infinity=V_alpha-V_Earth;

a_parking=6678.14;
a_departure=-mu_Earth./(V_infinity).^2;
e=1+(V_infinity.^2*a_parking)./mu_Earth;
Va=-acos(-1./e)*180/pi;
V_pi=sqrt(V_infinity.^2+2*mu_Earth/a_parking)
Vc=sqrt(mu_Earth/a_parking)
delta_v=V_pi-Vc
delta_v1=sqrt(V_pi.^2+Vc.^2-2*(V_pi*Vc)*cosd(5));

figure(1)
plot(year,delta_v,'g*-')
hold on
plot(year,-V_infinity,'m*-')
plot(year,delta_v-V_infinity,'r*-')
xlabel('Phasing Duration (years)')
ylabel('Delta V (km/s)')
title('Delta V vs Phasing Years Delta V1')
legend('Phase 2', 'Phase 3', 'Total Delta V for the later two phases')

figure(2)
plot(year,days,'k-')
hold on
xlabel('Orbital Period (days)')
ylabel('Phasing Duration (years)')
title('Orbital Period of the satellite vs Phasing Duration')