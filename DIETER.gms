$offOrder
********************************************************************************
$ontext
The Dispatch and Investment Evaluation Tool with Endogenous Renewables (DIETER).
Version 1.#, April 2018.
Written by Alexander Zerrahn and Wolf-Peter Schill.
This work is licensed under the MIT License (MIT).
For more information on this license, visit http://opensource.org/licenses/mit-license.php.
Whenever you use this code, please refer to http://www.diw.de/dieter.
We are happy to receive feedback under azerrahn@diw.de and wschill@diw.de.
$offtext
********************************************************************************




**************************
***** GLOBAL OPTIONS *****
**************************

$if not set solver               $setglobal solver cplex
$if not set SolveTimeLimit       $setglobal SolveTimeLimit 86400

* Set star to skip Excel upload and load data from gdx
$setglobal skip_Excel "*"
$setglobal datadir data/
$setglobal gdxdir gdxfiles/
$setglobal datafile data_input_f�r_mario.xlsx

* Choose base year
$setglobal base_year "'2030'"

* Test runs: Germany only - also adjust Excel inputs!
$setglobal GER_only "*"

* Set star to activate options
$setglobal DSM ""

$setglobal reserves_endogenous ""
$setglobal reserves_exogenous "*"

$setglobal prosumage ""

$setglobal heat "*"
$setglobal HEAT_NIGHT ""

$setglobal P2G "*"

$setglobal EV "*"
$setglobal EV_EXOG ""
* Set star to indicate renewables constraint on electric vehicles - DEFAULT is same quota as for the rest of the electricity system
$setglobal EV_DEFAULT "*"
$setglobal EV_100RES ""
$setglobal EV_FREE ""

* Set star to select run-of-river options either as a simple exogenous parameter or as an endogenous variable including reserve provision:
* if nothing is selected, ROR capacity will be set to zero
* if parameter option is selected, set appropriate values in fix.gmx
* if variable option is selected, set appropriate bound in data_input excel
$setglobal ror_parameter ""
$setglobal ror_variable "*"

* Set star to determine loops, otherwise default 100% renewables
$setglobal loop_over_renewable_share "*"

* Set star to run test variant with each second hour
* FEATURE DOES NOT WORK WITH HEAT VERSION
$setglobal second_hour ""
$if not set nthhour $set nthhour 1

* Set star for no crossover to speed up calculation time by skipping crossover in LP solver
$setglobal no_crossover ""


********************************************************************************

* Definition of strings for report parameters and sanity checks
* (Do not change settings below)
$setglobal sec_hour "1"

%second_hour%$ontext
$setglobal sec_hour "8760/2208"
$ontext
$offtext

$setglobal reserves "%reserves_endogenous%%reserves_exogenous%"

* Sanity checks
$if "%ror_parameter%" == "*" $if "%ror_variable%" == "*" $abort Choose appropriate ROR option! ;

$if "%reserves%" == "**" $abort Choose only one reserve option (endogenous or exogenous)!

$if "%EV%" == "" $if "%EV_EXOG%" == "*" $abort Switch on EV! ;

$if "%EV%" == "*" $if "%EV_DEFAULT%%EV_100RES%%EV_FREE%" == "" $abort Choose exactly one EV option! ;
$if "%EV%" == "*" $if "%EV_DEFAULT%%EV_100RES%%EV_FREE%" == "**" $abort Choose exactly one EV option! ;
$if "%EV%" == "*" $if "%EV_DEFAULT%%EV_100RES%%EV_FREE%" == "***" $abort Choose exactly one EV option! ;

$if "%EV_EXOG%" == "*" $if "%EV_DEFAULT%%EV_100RES%%EV_FREE%" == "" $abort Choose exactly one EV option! ;
$if "%EV_EXOG%" == "*" $if "%EV_DEFAULT%%EV_100RES%%EV_FREE%" == "**" $abort Choose exactly one EV option! ;
$if "%EV_EXOG%" == "*" $if "%EV_DEFAULT%%EV_100RES%%EV_FREE%" == "***" $abort Choose exactly one EV option! ;




********************************************************************************

****************************
***** INITIALIZE LOOPS *****
****************************

sets
%loop_over_renewable_share%$ontext
loop_res_share   Solution loop for different shares of renewables       /70,80,90,100/
$ontext
$offtext

%EV%$ontext
loop_ev          Solution loop for different fleets of EVs              /0,2e+6,4e+6/
$ontext
$offtext

%prosumage%$ontext
loop_prosumage   Solution loop for different prosumer self-consumption levels    /50/
$ontext
$offtext

%heat%$ontext
loop_heat   Solution loop for different heat levels    /0,50,100/
$ontext
$offtext

%p2g%$ontext
loop_p2g   Solution loop for different hydrogen demand    /0,100,200,300,400,500/
$ontext
$offtext

%loop_over_renewable_share%      loop_res_share                          /100/
%EV%                             loop_ev                                 /0/
%prosumage%                      loop_prosumage                          /0/
%heat%                           loop_heat                               /0/
%p2g%                            loop_p2g                                /0/
;




********************************************************************************

**************************
***** SOLVER OPTIONS *****
**************************

options
optcr = 0.00
reslim = 10000000
lp = %solver%
mip = cplex
nlp = conopt
limrow = 0
limcol = 0
;

options
dispwidth = 15
limrow = 0
limcol = 0
solprint = off
sysout = off
;



********************************************************************************

**************************
***** Dataload *****
**************************

$include dataload.gms



********************************************************************************

*************************************
***** Features for single nodes *****
*************************************

Set
features /dsm, ev, reserves, prosumage, rsvr_outflow, heat/
;

%GER_only%$include feat_node.gms
%GER_only%$goto jump
Table
feat_node(features,n)
                 DE
%DSM%$ontext
dsm              1
$ontext
$offtext
%reserves%$ontext
reserves         1
$ontext
$offtext
%ev%$ontext
ev               1
$ontext
$offtext
%prosumage%$ontext
prosumage        1
$ontext
$offtext
rsvr_outflow     0
%heat%$ontext
heat             1
$ontext
$offtext
;

%GER_only%$label jump

%DSM%$ontext
m_dsm_cu(n,dsm_curt)$(feat_node('dsm',n) = 0) = 0 ;
m_dsm_shift(n,dsm_shift)$(feat_node('dsm',n) = 0) = 0 ;
$ontext
$offtext

%prosumage%$ontext
m_res_pro(n,res)$(feat_node('prosumage',n) = 0) = 0 ;
m_sto_pro_e(n,sto)$(feat_node('prosumage',n) = 0) = 0 ;
m_sto_pro_p(n,sto)$(feat_node('prosumage',n) = 0) = 0 ;
$ontext
$offtext

phi_rsvr_min(n) = 0
*feat_node('rsvr_outflow',n)
;

%heat%$ontext
dh(n,bu,ch,h)$(feat_node('heat',n) = 0) = 0 ;
d_dhw(n,bu,ch,h)$(feat_node('heat',n) = 0) = 0 ;
%heat_night%theta_night(h) = 1 ;
$ontext
$offtext




********************************************************************************

***************************
***** Initialize data *****
***************************

* Parameters for default base year
d(n,h) = d_y(n,%base_year%,h) ;
phi_res(n,res,h) = phi_res_y(n,%base_year%,res,h) ;
rsvr_in(n,rsvr,h) = rsvr_in_y(n,%base_year%,rsvr,h) ;
phi_reserves_call(n,reserves,h) = phi_reserves_call_y(n,%base_year%,reserves,h) ;
phi_mean_reserves_call(n,reserves) = phi_mean_reserves_call_y(n,%base_year%,reserves) ;
reserves_exogenous(n,reserves,h) = reserves_exogenous_y(n,%base_year%,reserves,h) ;
dh(n,bu,ch,h) = dh_y(n,%base_year%,bu,ch,h) ;
d_dhw(n,bu,ch,h) = d_dhw_y(n,%base_year%,bu,ch,h) ;

dh(n,bu,ch,h) = area_floor(n,bu,ch) * dh(n,bu,ch,h) ;
d_dhw(n,bu,ch,h) = area_floor(n,bu,ch) * d_dhw(n,bu,ch,h) ;


* No interconnections between non-adjacent or nonuploaded nodes
m_ntc(l)$( smax(n,inc(l,n)) = 0 OR smin(n,inc(l,n)) = 0 ) = 0 ;

* Set loop parameters to default zero
phi_min_res = 0 ;
ev_quant = 0 ;
phi_pro_self = 0 ;
phi_pro_load(n) = 0 ;
phi_pro_load(n)$feat_node('prosumage',n) = 0.2 ;


*$stop




Parameter
phi_min_res_exog(n)
min_flh(n,rsvr)
;

phi_min_res_exog(n) = 1 ;
min_flh(n,rsvr) = 0 ;

*min_flh('FR',rsvr) = 1000 * card(h)/8760 ;
*min_flh('AT',rsvr) = 1000 * card(h)/8760 ;
*min_flh('CH',rsvr) = 1000 * card(h)/8760 ;




********************************************************************************
***** Model *****
********************************************************************************

$include model.gms




********************************************************************************
***** Options, fixings, report preparation *****
********************************************************************************

*Option ResLim = %SolveTimeLimit% ;

* Solver options
$onecho > cplex.opt
lpmethod 4
threads -1
epgap 1e-3
parallelmode -1
names 0
$offecho

$onecho > gurobi.opt
names 0
method 2
presolve 2
barconvtol 1e-10
threads -1
$offecho

%no_crossover%$ontext
$onecho > cplex.opt
lpmethod 4
threads -1
epgap 1e-3
parallelmode -1
barcrossalg -1
barepcomp 1e-8
$offecho
$ontext
$offtext

dieter.OptFile = 1;
dieter.holdFixed = 1 ;

********************************************************************************
***** Solve *****
********************************************************************************

* Preparation of GUSS tool for scenario analysis
phi_min_res = eps ;
ev_quant = eps ;
phi_pro_self = eps ;
gas_demand = eps;
heat_share = eps;

$eval superscencount 1000

Set
modelstats       model stats collection                  /modelstat, solvestat, resusd/
superscen        Scenarios                               /scen1*scen%superscencount%/
map(superscen,loop_res_share,loop_ev,loop_prosumage, loop_heat, loop_p2g)    /#superscen:(#loop_res_share.#loop_ev.#loop_prosumage.#loop_heat.#loop_p2g)/
;

set
scen(superscen);
scen(superscen) = yes$( sum((loop_res_share,loop_ev,loop_prosumage,loop_heat, loop_p2g) , map(superscen,loop_res_share,loop_ev,loop_prosumage,loop_heat, loop_p2g)) )    ;

Parameters
gussoptions                              /Logoption 2, Optfile 1, Skipbasecase 1/
modstats(superscen, modelstats)
min_res
number_ev
pro_selfcon
heat_level
hydrogen_demand
;

min_res(scen) = sum( (loop_res_share,loop_ev,loop_prosumage,loop_heat, loop_p2g)$map(scen,loop_res_share,loop_ev,loop_prosumage,loop_heat, loop_p2g) , loop_res_share.val/100 ) ;
number_ev(scen) = sum( (loop_res_share,loop_ev,loop_prosumage,loop_heat, loop_p2g)$map(scen,loop_res_share,loop_ev,loop_prosumage,loop_heat, loop_p2g) , loop_ev.val ) ;
pro_selfcon(scen) = sum( (loop_res_share,loop_ev,loop_prosumage,loop_heat, loop_p2g)$map(scen,loop_res_share,loop_ev,loop_prosumage,loop_heat, loop_p2g) , loop_prosumage.val/100 ) ;
heat_level(scen) = sum( (loop_res_share,loop_ev,loop_prosumage,loop_heat, loop_p2g)$map(scen,loop_res_share,loop_ev,loop_prosumage,loop_heat, loop_p2g) , loop_heat.val/100 ) ;
hydrogen_demand(scen) = sum( (loop_res_share,loop_ev,loop_prosumage,loop_heat, loop_p2g)$map(scen,loop_res_share,loop_ev,loop_prosumage,loop_heat, loop_p2g) , loop_p2g.val * 1000000/8760) ;

Parameters
* Equations
marginal_con5a(superscen,*)
marginal_con1a(superscen,*,*)
marginal_con9a(superscen,*,*,*)
marginal_con9b(superscen,*,*,*)

* Basic
lev_Z(superscen)
lev_G_L(superscen,n,tech,h_full)
lev_G_UP(superscen,n,tech,h_full)
lev_G_DO(superscen,n,tech,h_full)
lev_G_RES(superscen,n,tech,h_full)
lev_CU(superscen,n,tech,h_full)
lev_STO_IN(superscen,n,sto,h_full)
lev_STO_OUT(superscen,n,sto,h_full)
lev_STO_L(superscen,n,sto,h_full)
lev_N_TECH(superscen,n,tech)
lev_N_STO_E(superscen,n,sto)
lev_N_STO_P(superscen,n,sto)
lev_NTC(superscen,l)
lev_F(superscen,l,h_full)
lev_RSVR_OUT(superscen,n,rsvr,h_full)
lev_RSVR_L(superscen,n,rsvr,h_full)
lev_N_RSVR_E(superscen,n,rsvr)
lev_N_RSVR_P(superscen,n,rsvr)

* EV
lev_EV_CHARGE(superscen,n,ev,h_full)
lev_EV_DISCHARGE(superscen,n,ev,h_full)
lev_EV_L(superscen,n,ev,h_full)
lev_EV_PHEVFUEL(superscen,n,ev,h_full)
lev_EV_GED(superscen,n,ev,h_full)

* DSM
lev_DSM_CU(superscen,n,dsm,h_full)
lev_DSM_UP(superscen,n,dsm,h_full)
lev_DSM_DO(superscen,n,dsm,h_full,hh_full)
lev_DSM_UP_DEMAND(superscen,n,dsm,h_full)
lev_DSM_DO_DEMAND(superscen,n,dsm,h_full)
lev_N_DSM_CU(superscen,n,dsm)
lev_N_DSM_SHIFT(superscen,n,dsm)

* Reserves
lev_RP_DIS(superscen,n,reserves,tech,h_full)
lev_RP_NONDIS(superscen,n,reserves,tech,h_full)
lev_RP_STO_IN(superscen,n,reserves,sto,h_full)
lev_RP_STO_OUT(superscen,n,reserves,sto,h_full)
lev_RP_RSVR(superscen,n,reserves,rsvr,h_full)

* EV & reserves
lev_RP_EV_V2G(superscen,n,reserves,ev,h_full)
lev_RP_EV_G2V(superscen,n,reserves,ev,h_full)

* DSM $ reserves
lev_RP_DSM_CU(superscen,n,reserves,dsm,h_full)
lev_RP_DSM_SHIFT(superscen,n,reserves,dsm,h_full)

* Prosumage
lev_CU_PRO(superscen,n,tech,h_full)
lev_G_MARKET_PRO2M(superscen,n,tech,h_full)
lev_G_MARKET_M2PRO(superscen,n,h_full)
lev_G_RES_PRO(superscen,n,tech,h_full)
lev_STO_IN_PRO2PRO(superscen,n,tech,sto,h_full)
lev_STO_IN_PRO2M(superscen,n,tech,sto,h_full)
lev_STO_IN_M2PRO(superscen,n,sto,h_full)
lev_STO_IN_M2M(superscen,n,sto,h_full)
lev_STO_OUT_PRO2PRO(superscen,n,sto,h_full)
lev_STO_OUT_PRO2M(superscen,n,sto,h_full)
lev_STO_OUT_M2PRO(superscen,n,sto,h_full)
lev_STO_OUT_M2M(superscen,n,sto,h_full)
lev_STO_L_PRO2PRO(superscen,n,sto,h_full)
lev_STO_L_PRO2M(superscen,n,sto,h_full)
lev_STO_L_M2PRO(superscen,n,sto,h_full)
lev_STO_L_M2M(superscen,n,sto,h_full)
lev_N_STO_E_PRO(superscen,n,sto)
lev_N_STO_P_PRO(superscen,n,sto)
lev_STO_L_PRO(superscen,n,sto,h_full)
lev_N_RES_PRO(superscen,n,tech)

* Heat
lev_H_DIR(superscen,n,bu,ch,h_full)
lev_H_SETS_LEV(superscen,n,bu,ch,h_full)
lev_H_SETS_IN(superscen,n,bu,ch,h_full)
lev_H_SETS_OUT(superscen,n,bu,ch,h_full)
lev_H_HP_IN(superscen,n,bu,ch,h_full)
lev_H_STO_LEV(superscen,n,bu,ch,h_full)
lev_H_STO_IN_HP(superscen,n,bu,ch,h_full)
lev_H_STO_IN_ELECTRIC(superscen,n,bu,ch,h_full)
lev_H_ELECTRIC_IN(superscen,n,bu,ch,h_full)
lev_H_STO_IN_FOSSIL(superscen,n,bu,ch,h_full)
lev_H_STO_OUT(superscen,n,bu,ch,h_full)

lev_H_DHW_STO(superscen,n,bu,ch,h_full)
lev_H_DHW_STO_OUT(superscen,n,bu,ch,h_full)
lev_H_DHW_DIR(superscen,n,bu,ch,h_full)

lev_H_DHW_AUX_ELEC_IN(superscen,n,bu,ch,h_full)
lev_H_DHW_AUX_LEV(superscen,n,bu,ch,h_full)
lev_H_DHW_AUX_OUT(superscen,n,bu,ch,h_full)


lev_RP_SETS(superscen,n,reserves,bu,ch,h_full)
lev_RP_HP(superscen,n,reserves,bu,ch,h_full)
lev_RP_H_ELEC(superscen,n,reserves,bu,ch,h_full)
lev_RP_SETS_AUX(superscen,n,reserves,bu,ch,h_full)

* P2G
lev_G_P2G(superscen,n,p2g,h_full)
lev_G_G2P(superscen,n,p2g,h_full)
lev_GS_STO_IN(superscen,n,p2g,h_full)
lev_GS_STO_OUT(superscen,n,p2g,h_full)
lev_GS_STO_L(superscen,n,p2g,h_full)
lev_N_GS(superscen,n,p2g)
lev_N_P2G(superscen,n,p2g)
lev_N_G2P(superscen,n,p2g)

* Infeasibility
lev_G_INFES(superscen,n,h_full)
lev_G_P2G_INFEAS(superscen,n,h_full)
;


* Inclusion of scenario and fixing
$include fix.gms
$include Scenario.gms


* Definition of dictionary set for GUSS tool
Set dict(*,*,*) /
scen             .scenario       .''
gussoptions      .opt            .modstats

phi_min_res      .param          .min_res
%EV%$ontext
ev_quant         .param          .number_ev
$ontext
$offtext
%prosumage%$ontext
phi_pro_self     .param          .pro_selfcon
$ontext
$offtext

%heat%$ontext
heat_share       .param          .heat_level
$ontext
$offtext

%p2g%$ontext
gas_demand       .param          .hydrogen_demand
$ontext
$offtext

con5a_minRES     .marginal       .marginal_con5a
con1a_bal        .marginal       .marginal_con1a

Z                .level          .lev_Z
G_L              .level          .lev_G_L
G_UP             .level          .lev_G_UP
G_DO             .level          .lev_G_DO
G_RES            .level          .lev_G_RES
CU               .level          .lev_CU
STO_IN           .level          .lev_STO_IN
STO_OUT          .level          .lev_STO_OUT
STO_L            .level          .lev_STO_L
N_TECH           .level          .lev_N_TECH
N_STO_E          .level          .lev_N_STO_E
N_STO_P          .level          .lev_N_STO_P
NTC              .level          .lev_NTC
F                .level          .lev_F
RSVR_OUT         .level          .lev_RSVR_OUT
RSVR_L           .level          .lev_RSVR_L
N_RSVR_E         .level          .lev_N_RSVR_E
N_RSVR_P         .level          .lev_N_RSVR_P

%EV%$ontext
EV_CHARGE        .level          .lev_EV_CHARGE
EV_DISCHARGE     .level          .lev_EV_DISCHARGE
EV_L             .level          .lev_EV_L
EV_PHEVFUEL      .level          .lev_EV_PHEVFUEL
EV_GED           .level          .lev_EV_GED
$ontext
$offtext

%DSM%$ontext
DSM_CU           .level          .lev_DSM_CU
DSM_UP           .level          .lev_DSM_UP
DSM_DO           .level          .lev_DSM_DO
DSM_UP_DEMAND    .level          .lev_DSM_UP_DEMAND
DSM_DO_DEMAND    .level          .lev_DSM_DO_DEMAND
N_DSM_CU         .level          .lev_N_DSM_CU
N_DSM_SHIFT      .level          .lev_N_DSM_SHIFT
$ontext
$offtext

%reserves%$ontext
RP_DIS           .level          .lev_RP_DIS
RP_NONDIS        .level          .lev_RP_NONDIS
RP_STO_IN        .level          .lev_RP_STO_IN
RP_STO_OUT       .level          .lev_RP_STO_OUT
RP_RSVR          .level          .lev_RP_RSVR
$ontext
$offtext

%reserves_endogenous%$ontext
con9a_reserve_prov_endogenous    .marginal       .marginal_con9a
con9b_reserve_prov_PR_endogenous .marginal       .marginal_con9b
$ontext
$offtext
%reserves_exogenous%$ontext
con9a_reserve_prov_exogenous     .marginal       .marginal_con9a
con9b_reserve_prov_PR_exogenous  .marginal       .marginal_con9b
$ontext
$offtext

%reserves%$ontext
%EV%$ontext
%EV_EXOG% RP_EV_V2G      .level  .lev_RP_EV_V2G
%EV_EXOG% RP_EV_G2V      .level  .lev_RP_EV_G2V
$ontext
$offtext

%reserves%$ontext
%DSM%$ontext
RP_DSM_CU        .level          .lev_RP_DSM_CU
RP_DSM_SHIFT     .level          .lev_RP_DSM_SHIFT
$ontext
$offtext

%prosumage%$ontext
CU_PRO           .level           .lev_CU_PRO
G_MARKET_PRO2M   .level           .lev_G_MARKET_PRO2M
G_MARKET_M2PRO   .level           .lev_G_MARKET_M2PRO
G_RES_PRO        .level           .lev_G_RES_PRO
STO_IN_PRO2PRO   .level           .lev_STO_IN_PRO2PRO
STO_IN_PRO2M     .level           .lev_STO_IN_PRO2M
STO_IN_M2PRO     .level           .lev_STO_IN_M2PRO
STO_IN_M2M       .level           .lev_STO_IN_M2M
STO_OUT_PRO2PRO  .level           .lev_STO_OUT_PRO2PRO
STO_OUT_PRO2M    .level           .lev_STO_OUT_PRO2M
STO_OUT_M2PRO    .level           .lev_STO_OUT_M2PRO
STO_OUT_M2M      .level           .lev_STO_OUT_M2M
STO_L_PRO        .level           .lev_STO_L_PRO
STO_L_PRO2PRO    .level           .lev_STO_L_PRO2PRO
STO_L_PRO2M      .level           .lev_STO_L_PRO2M
STO_L_M2PRO      .level           .lev_STO_L_M2PRO
STO_L_M2M        .level           .lev_STO_L_M2M
N_STO_E_PRO      .level           .lev_N_STO_E_PRO
N_STO_P_PRO      .level           .lev_N_STO_P_PRO
N_RES_PRO        .level           .lev_N_RES_PRO
$ontext
$offtext

%heat%$ontext
H_DIR                    .level          .lev_H_DIR
H_SETS_LEV               .level          .lev_H_SETS_LEV
H_SETS_IN                .level          .lev_H_SETS_IN
H_SETS_OUT               .level          .lev_H_SETS_OUT
H_HP_IN                  .level          .lev_H_HP_IN
H_STO_LEV                .level          .lev_H_STO_LEV
H_STO_IN_HP              .level          .lev_H_STO_IN_HP
H_STO_IN_ELECTRIC        .level          .lev_H_STO_IN_ELECTRIC
H_ELECTRIC_IN            .level          .lev_H_ELECTRIC_IN
H_STO_IN_FOSSIL          .level          .lev_H_STO_IN_FOSSIL
H_STO_OUT                .level          .lev_H_STO_OUT

*H_DHW_STO        .level          .lev_H_DHW_STO
H_DHW_STO_OUT    .level          .lev_H_DHW_STO_OUT
H_DHW_DIR        .level          .lev_H_DHW_DIR

H_DHW_AUX_ELEC_IN    .level          .lev_H_DHW_AUX_ELEC_IN
H_DHW_AUX_LEV    .level          .lev_H_DHW_AUX_LEV
H_DHW_AUX_OUT        .level          .lev_H_DHW_AUX_OUT

$ontext
$offtext

%heat%$ontext
%reserves%$ontext
RP_SETS          .level          .lev_RP_SETS
RP_SETS_AUX      .level          .lev_RP_SETS_AUX
RP_HP            .level          .lev_RP_HP
RP_H_ELEC        .level          .lev_RP_H_ELEC
$ontext
$offtext

%P2G%$ontext
G_P2G                 .level      .lev_G_P2G
G_G2P                 .level      .lev_G_G2P
GS_STO_IN             .level      .lev_GS_STO_IN
GS_STO_OUT            .level      .lev_GS_STO_OUT
GS_STO_L              .level      .lev_GS_STO_L
N_GS                  .level      .lev_N_GS
N_P2G                 .level      .lev_N_P2G
N_G2P                 .level      .lev_N_G2P

G_P2G_INFEAS          .level      .lev_G_P2G_INFEAS
$ontext
$offtext

G_INFES          .level          .lev_G_INFES
/
;

$include parallel_run.gms


solve DIETER using lp min Z scenario dict;

* Reporting
$include report2.gms

$stop
execute_unload "results", report, report_tech, report_node, report_line, report_tech_hours, report_hours, report_cost
%prosumage%$ontext
, report_prosumage, report_prosumage_tech, report_prosumage_tech_hours, report_market, report_market_tech, report_market_tech_hours
$ontext
$offtext
%heat%$ontext
, report_heat_tech_hours, report_heat_tech
$ontext
$offtext
%reserves_endogenous%$ontext
, report_reserves, report_reserves_tech, report_reserves_tech_hours
$ontext
$offtext
%reserves_exogenous%$ontext
, report_reserves_tech, report_reserves_tech_hours, report_reserves_hours
$ontext
$offtext
;

*$include report_to_excel.gms



* ---------------------------------------------------------------------------- *
* ---------------------------------------------------------------------------- *
* ---------------------------------------------------------------------------- *
