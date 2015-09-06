PLAB0
Cog4 IP port 2020 <-> Cog0           PLAB1                                         PLAB2
Cog4 IP port 2021 <-> Cog2 0 MCS <=> Cog7 0 MCS <-> Cog0   |-------> Cog6 0 MCS <=> Cog7 0 MCS <-> Cog0
Cog4 IP port 2022 <-> Cog2 1 MCS <=> Cog7 1 MCS <----------| |-----> Cog6 1 MCS <=> Cog7 1 MCS <-> Cog1
Cog4 IP port 2023 <-> Cog2 2 MCS <=> Cog7 2 MCS <---------|  |       Cog6 2 MCS <=> Cog7 2 MCS <-> Cog2
                      Cog2 3 MCS <=> Cog7 3 MCS           |  |       Cog6 3 MCS <=> Cog7 3 MCS <-> Cog3
                      Cog2 4 MCS <=> Cog7 4 MCS <-> Cog4  |  |       Cog6 4 MCS <=> Cog7 4 MCS <-> Cog4
Cog5 <--------------> Cog2 5 MCS <=> Cog7 5 MCS           |  |       Cog6 5 MCS <=> Cog7 5 MCS     Cog5 SERIAL------|
                      Cog2 6 MCS <=> Cog7 6 MCS -------------|       Cog6 6 MCS <=> Cog7 6 MCS                      |
                      Cog2 7 MCS <=> Cog7 7 MCS -------|  |          Cog6 7 MCS <=> Cog7 7 MCS                      |
                                                       |  |                                                         |
                                                       |  |                         PLAB3                           |
                                                       |  |--------> Cog3 0 MCS <=> Cog7 0 MCS <-> Cog0             |
                                                       |-----------> Cog3 1 MCS <=> Cog7 1 MCS <-> Cog1             |
                                                                     Cog3 2 MCS <=> Cog7 2 MCS <-> Cog2             |
                                                                     Cog3 3 MCS <=> Cog7 3 MCS <-> Cog3             |
                                                                     Cog3 4 MCS <=> Cog7 4 MCS <-> Cog4             |
                                                                     Cog3 5 MCS <=> Cog7 5 MCS     Cog5 SERIAL---|  |
                                                                     Cog3 6 MCS <=> Cog7 6 MCS     Cog6 SERIAL-| |  |
                                                                     Cog3 7 MCS <=> Cog7 7 MCS                 | |  |
                                                                                                               | |  |
     ----------------------------------------------------------------------------------------------------------| |  |  
     |                                                                                                           |  |
     |                                      DEMO                                                                 |  |
     |- IO3 (TX blue)    --> IO7 (RX blue)  Cog7 SERIAL                                                          |  |
     |- IO4 (RX green)   <-- IO6 (TX green) Cog7 SERIAL                                                          |  |
     |- IO5 (RES orange) --> RES                                                                                 |  |
                                                                                                                 |  |
     |-----------------------------------------------------------------------------------------------------------|  |
     |                                                                                                              |
     |                                       PROT                                                                   |
     |- IO0 (RX blue)    --> I030 (TX blue)  Cog7 SERIAL                                                            |
     |- IO1 (RX green)   <-- IO31 (RX green) Cog7 SERIAL                                                            |
     |- IO2 (RES orange) --> RES                                                                                    |
                                                                                                                    |
     |--------------------------------------------------------------------------------------------------------------| 
     |
     |                                       PLAT
     |- IO0 (RX blue)    --> I030 (TX blue)  Cog7 SERIAL
     |- IO1 (RX green)   <-- IO31 (RX green) Cog7 SERIAL
     |- IO2 (RES orange) --> RES         |-> Cog1 SERIAL <--> SanciBluetooth
                                         |-> Cog0


   

