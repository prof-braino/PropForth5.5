hA state orC!
\
\
\ IP & TELNET CONFIG PARAMETERS BEGIN
\
\
hFFFF wconstant $S_ip_light
\
\ This defines the cog which will be used to run the ip service
5 wconstant $S_ip_cog
\
\ These constants configure the number of ip channels and the
\ buffer allocation in the W5100
\
\ The number of telnet sockets to start
\
h800 wconstant $S_ip_sockbufsize
h7FF wconstant $S_ip_sockbufmask
h55 wconstant $S_ip_sockbufinit
4 wconstant $S_ip_numsock
4 wconstant $S_ip_numTelnet
\
\
3020 wconstant $S_ip_telnetport
\
\ The gateway parameter is necessary for the client protocols, to route through for internet requests.
\
hC0_A8 wconstant $S_ip_gatewayhi
h00_01 wconstant $S_ip_gatewaylo
\
hFF_FF wconstant $S_ip_subnetmaskhi
hFF_00 wconstant $S_ip_subnetmasklo
\
\ The mac address is on the bottom of the spinneret board
\
h00_0C wconstant $S_ip_machi
h29_8B wconstant $S_ip_macmid
h00_70 wconstant $S_ip_maclo
\
hC0_A8 wconstant $S_ip_addrhi
h00_81 wconstant $S_ip_addrlo
\
8080 wconstant $S_ip_httpport
\
\
\ IP & TELNET CONFIG PARAMETERS END
\
hA state andnC!
