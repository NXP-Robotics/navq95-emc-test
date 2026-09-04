# Parts and connections

NXP X-NAVQ95-MAIN (DRQ30074657) (700-97010 REV X1) (SCH-97010 REV A)

| ID             | PartNumber              | Quantity | Description                          | Connection 1                                  | Connection 2                                    | Connection 3         |
|----------------|-------------------------|----------|--------------------------------------|-----------------------------------------------|-------------------------------------------------|----------------------|
| X-NAVQ95-MAIN  | NXP 9355 073 92598      | 1        | NavQ95B Main board                   |                                               |                                                 |                      |
| X-NAVQ95-IO    | NXP 9355 073 98598      | 1        | NavQ95B IO shield                    |                                               |                                                 |                      |
| X-NAVQ95-T1SW  | NXP 9355 073 94598      | 1        | NavQ95B T1 Switch shield             |                                               |                                                 |                      |
| X-NAVQ95-CAMRP | NXP 9355 073 96598      | 2        | NavQ95B Camera shield                |                                               |                                                 |                      |
| EXT_1          | PAK HENG E301195        | 1        | USB host cable                       | X-NAVQ95-IO J1(CONSOLE)                       | Host laptop *                                   |                      |
| EXT_2          | custom                  | 1        | CAN BUS cable (cable has three ends) | X-NAVQ95-IO J5(CAN1)                          | X-NAVQ95-IO J4(CAN2)                            | X-NAVQ95-IO J3(CAN3) |
| EXT_3          | Generic 3.5mm jack      | 1        | Earphones                            | X-NAVQ95-IO Earphone jack                     |                                                 |                      |
| EXT_4          | Videk 2965-1W           | 1        | RJ45 CAT.5E cable                    | X-NAVQ95-MAIN J8(Ethernet port)               | EXT_15 (Switch/AP) Port 1-4 (yellow socket)     |                      |
| EXT_5          | Molex 146153            | 2        | 2.4/5GHz antenna                     | X-NAVQ95-MAIN J18 ANT0, J19 ANT1              |                                                 |                      |
| EXT_6          | custom                  | 3        | 100BASE-T1 cable **                  | X-NAVQ95-T1SW J5(PORT5), J7(PORT7), J9(PORT9) | X-NAVQ95-T1SW J6(PORT6), J8(PORT8), J10(PORT10) |                      |
| EXT_7          | Amphenol MSPEC2L0B3010  | 1        | 1000BASE-T1 cable                    | X-NAVQ95-T1SW J4(PORT1)                       | X-NAVQ95-T1SW J3(PORT2)                         |                      |
| EXT_8          | EDAC EA11701M-1200      | 1        | Power supply                         | X-NAVQ95-MAIN J9 (PWR IN)                     | mains                                           |                      |
| EXT_9          | Raspberry Pi SC1892     | 2        | Camera flatfoil ***                  | X-NAVQ95-CAMRP J3                             | EXT_14 (Raspberry PI Camera)                    |                      |
| EXT_10         | Kingston DT70/64GB      | 2        | USB drive                            | X-NAVQ95-MAIN J13(USB1), J12(USB2)            |                                                 |                      |
| EXT_11         | ASSY 600-77626          | 1        | Antenna NFC 30x40mm 100mm            | X-NAVQ95-MAIN J10(SE_NFC)                     |                                                 |                      |
| EXT_12         | Kingston SA2000M8/500G  | 1        | Kingston M.2 SSD                     | X-NAVQ95-MAIN J1 (M.2 KEY_M)                  |                                                 |                      |
| EXT_13         | SP 25040818090064       | 1        | SP M.2 SSD                           | X-NAVQ95-MAIN J16(M.2_KEY_B)                  |                                                 |                      |
| EXT_14         | Raspberry Pi B01ER2SKFS | 2        | RPI Camera v2.1                      |                                               |                                                 |                      |
| EXT_15         | ASUS 90IG0550-BM3400    | 1        | Switch/AP                            |                                               |                                                 |                      |
| EXT_16         | Seanen KSA-24W-120200VE | 1        | Switch/AP power supply               | EXT_15 (Switch/AP) DC-IN                      | mains                                           |                      |
| EXT_17         | SanDisk 5272DFCYV0QF    | 1        | SD-card                              |                                               |                                                 |                      |

\* *Host laptop is not included in the shipment.*

\*\* *There are 3 EXT_6 componentes which are used to connect PORT5-PORT6, PORT7-PORT8 and PORT8-PORT10 of the X-NAVQ95-T1SW.*

\*\*\* *Make sure the flatfoil is inserted in the same orientation as on the [top](images/emc_test_setup_top.png) and [bottom](images/emc_test_setup_bottom.png) images.*


## Images

![](images/emc_connections_north.png)
![](images/emc_connections_east.png)
![](images/emc_connections_south.png)
![](images/emc_connections_west.png)
![](images/emc_connections_top.png)
![](images/emc_connections_bottom.png)