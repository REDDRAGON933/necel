--Ñêðèïò äëÿ âûãðóçêè íåöåëåâêè

--Íåîáõîäèìî ïî÷åðåäíî ïåðåñîçäàâàòü âñå òàáëèöû äëÿ ïîëó÷åíèÿ àêòóàëüíîé èíôîðìàöèè

--Ñîäàåì òàáëèöó äëÿ õðàíåíèÿ ïðîìåæóòî÷íîé èíôîðìàöèè

DROP TABLE mp_necel purge;
CREATE table mp_necel
AS

--Àêòóàëüíûå çäàíèÿ ñ ïîñëåäíèì çíà÷èìûì þð.àêòîì

with tab1 as (
select distinct cadastral_number from  unio.t_object_card_state@opndbp
left join rosreestr_import.mv_realty on rosreestr_import.mv_realty.cadnum = unio.t_object_card_state.cadastral_number
left join UNIO.t_gin_verification@opndbp on unio.t_object_card_state.last_year_verification = unio.t_gin_verification.id@opndbp
join unio.t_directory_value@opndbp on unio.t_directory_value.id@opndbp = UNIO.t_gin_verification.RESULT_ID
where (unio.t_directory_value.id = '2510' 
or unio.t_directory_value.id = '2503' 
or unio.t_directory_value.id = '2504' 
or unio.t_directory_value.id = '2505' 
or unio.t_directory_value.id = '2506')
and rosreestr_import.mv_realty.status = 'actual'
and year = '2022'),

--Êëåèì ÇÓ ê çåìëå èç tab1 è Äîáàâëÿåì ÏÊÁÄ 60%

tab5 as (
select * from rosreestr_import.mv_building_to_land
union
select * from ROSREESTR_IMPORT.mv_structure_to_land
union
select * from ROSREESTR_IMPORT.mv_under_construction_to_land
union
select read_user.mp_egrn60.cadnum, read_user.mp_egrn60.land_cadnum from read_user.mp_egrn60),

--Ïðîâåðÿåì çåìëþ è ïîñòðîéêè íà àêòóàëüíîñü

tab51 as(
select * from tab5
left join rosreestr_import.mv_realty on rosreestr_import.mv_realty.cadnum = tab5.realty_id
left join rosreestr_import.mv_land on rosreestr_import.mv_land.record_id = tab5.land_cadnum
where rosreestr_import.mv_realty.status = 'actual' 
and rosreestr_import.mv_land.CANCEL_DATE is null),


--Îáúåäèíÿåì çåìëþ è çäàíèÿ 

tab6 as (
select realty_id, land_cadnum from tab51
join tab1 on tab1.cadastral_number = tab51.realty_id)

select * from tab6;

--Ôîðìèðóåì òàáëèöó ñ èòîãîâûìè ÊÍ

DROP TABLE mp_necelf purge;
CREATE table mp_necelf
AS

--Ïðîâåðêà ÇÓ íà àêòóàëüíîñòü

with tab2 as (
select distinct mp_necel.realty_id, mp_necel.land_cadnum, rosreestr_import.mv_land.category from mp_necel
left join rosreestr_import.mv_land on rosreestr_import.mv_land.RECORD_ID = mp_necel.LAND_CADNUM
where rosreestr_import.mv_land.cancel_date is null),

--ÂÐÈ ÇÓ ñî ñòàòóñîì 2 è áåç ñòàòóñà

tab4 as (
select tab2.realty_id, tab2.land_cadnum, tab2.category from tab2
minus
select tab2.realty_id, tab2.land_cadnum, tab2.category from tab2
where tab2.category = '1' or tab2.category = '0'
),


tab44 as(
select * from rosreestr_import.mv_building_to_land
union
select * from ROSREESTR_IMPORT.mv_structure_to_land
union
select * from ROSREESTR_IMPORT.mv_under_construction_to_land),


tab444 as (select tab44.realty_id, tab4.land_cadnum, tab4.category from tab4
left join tab44 on tab44.land_cadnum = tab4.land_cadnum),


tab4444 as (
select * from tab4
union
select * from tab444)

select distinct * from tab4444;


DROP TABLE mp_necelfdist PURGE;
CREATE table mp_necelfdist
AS
with tab1111 as( 
select distinct * from mp_necelf)

select distinct * from tab1111;

--Âûãðóçêà ÊÍ è ñêëåéêà èíôîðìàöèè î ñîáñòâåííèêå,âèäå ïðàâà è äîëå

DROP TABLE mp_tab11 PURGE;
CREATE table mp_tab11
AS

with tab10 as(
select MP_NECELFDIST.realty_id, (ROSREESTR_IMPORT.mv_right_owner.name  || ROSREESTR_IMPORT.mv_right_owner.RIGHT_TYPE_NAME || ' ' || ROSREESTR_IMPORT.mv_right_owner.SHARE_DESCRIPTION) as qwe from MP_NECELFDIST
inner join ROSREESTR_IMPORT.mv_right_owner on MP_NECELFDIST.realty_id = ROSREESTR_IMPORT.mv_right_owner.cad_number),

tab11 as(
SELECT tab10.realty_id,
RTRIM(XMLAGG(XMLELEMENT(E,tab10.qwe,',').EXTRACT('//text()') ORDER BY tab10.qwe).GetClobVal(),',') AS name1
FROM tab10
group by tab10.realty_id)

select * from tab11;

--Îáùàÿ ïëîùàäü ïîìåùåíèÿ

DROP TABLE mp_tab12 PURGE;
CREATE table mp_tab12
AS

with tab12 as (
select oks_cadnum, sum(area) as area1 from rosreestr_import.MV_FLAT
where status = 'actual'
group by oks_cadnum)

select * from tab12;

--Ïëîùàäü ñ ïðàâîì

DROP TABLE mp_tab13 PURGE;
CREATE table mp_tab13
AS

with tab13 as (
select rosreestr_import.MV_FLAT.oks_cadnum, sum(area) as area2 from rosreestr_import.MV_FLAT
inner join ROSREESTR_IMPORT.mv_right_owner on ROSREESTR_IMPORT.mv_right_owner.cad_number = ROSREESTR_IMPORT.mv_flat.record_id
where status = 'actual'
group by oks_cadnum
)

select * from tab13;

--Ñîåäèíåíèå èíôîðìàöèè ïî ïîìåùåíèÿì

DROP TABLE mp_tab15 PURGE;
CREATE table mp_tab15
AS

with tab14 as(
select rosreestr_import.MV_FLAT.record_id, rosreestr_import.MV_FLAT.oks_cadnum, (ROSREESTR_IMPORT.mv_right_owner.name  || ROSREESTR_IMPORT.mv_right_owner.RIGHT_TYPE_NAME ||' '|| ROSREESTR_IMPORT.mv_right_owner.SHARE_DESCRIPTION) as qwe from mp_tab11
left join rosreestr_import.MV_FLAT on mp_tab11.realty_id = rosreestr_import.MV_FLAT.oks_cadnum
inner  join ROSREESTR_IMPORT.mv_right_owner on ROSREESTR_IMPORT.mv_right_owner.cad_number = ROSREESTR_IMPORT.mv_flat.record_id),

tab15 as(
SELECT tab14.record_id,
RTRIM(XMLAGG(XMLELEMENT(E,tab14.qwe,',').EXTRACT('//text()') ORDER BY tab14.qwe).GetClobVal(),',') AS name2 
FROM tab14
group by tab14.record_id),

tab151 as (
SELECT rosreestr_import.mv_flat.oks_cadnum, tab15.name2 
from rosreestr_import.mv_flat
join tab15 on tab15.record_id = rosreestr_import.mv_flat.record_id)

select * from tab151;

--Ïëîùàäü, íàèìåíîâàíèå,  òèï îáúåêòà è íàçíà÷åíèå,  

DROP TABLE mp_tab16 PURGE;
CREATE table mp_tab16
AS

with tab16 as(
select distinct ROSREESTR_IMPORT.mv_realty.cadnum, area, OBJECT_TYPE, ADDR_GKN_STRUCT, IS_NEW_MOSCOW, STATUS, name, living from ROSREESTR_IMPORT.mv_realty
inner join mp_necelf on mp_necelf.realty_id = ROSREESTR_IMPORT.mv_realty.CADNUM
)

select * from tab16;

--Êîììåíòàðèé ÅÃÐÍ èç ASUR

DROP TABLE mp_tab18 PURGE;
CREATE table mp_tab18
AS

with tab18 as (
select asur_rr2_20200707.t$rr#realty.REALTY_ID, asur_rr2_20200707.t$rr#realty.note from mp_necelfdist
inner join asur_rr2_20200707.t$rr#realty on mp_necelfdist.realty_id = asur_rr2_20200707.t$rr#realty.realty_id
where asur_rr2_20200707.t$rr#realty.note is not null)

select * from tab18;


--ÎÊÍ

DROP TABLE mp_tab211 purge;
CREATE table mp_tab211
AS

with tab211 as(
select distinct read_user.MP_NECELFDIST.realty_id,
case
when  mp_okn.okn_fz is null 
then 'Íåò'
Else 'Äà'
End as okn_fz
from read_user.MP_NECELFDIST
right join read_user.mp_okn on read_user.mp_okn.okn_fz = read_user.MP_NECELFDIST.realty_id
)

select * from tab211;

--Ïðèçíàê îïåðàòèâíîãî óïðàâëåíèÿ, ïåøåõîäíàÿ çîíà, âëàäåíèå ÌÑÊ\ÐÔ, ïðåäíàçíà÷åíèå, âêëþ÷åí â ïåðå÷åíü 22

DROP TABLE mp_tab21 PURGE;
CREATE table mp_tab21
AS

with tab21 as(
select UNIO.t_object_card_state.cadastral_number,
UNIO.t_object_card_state.MOSCOW_OWNERSHIP,
UNIO.t_object_card_state.RF_OWNERSHIP,
UNIO.t_object_card_state.PEDESTRIAN_ZONE,
UNIO.t_object_card_state.INCLUDE_BY_BTI, 
case
when  INCLUSION_CRITERION = 'DGI' 
then 'ÂÐÈ ÇÓ' 
when INCLUSION_CRITERION = 'MVK' 
then 'ÂÔÈ' 
when INCLUSION_CRITERION = 'VRI_ZU'
then 'ÂÐÈ ÇÓ'
when INCLUSION_CRITERION = 'VFI'
then 'ÂÔÈ'
when INCLUSION_CRITERION =  'EXCLUDED'
then 'Èñêëþ÷åí'
end as fix22
from UNIO.t_object_card_state@opndbp
inner join MP_NECELFDIST on MP_NECELFDIST.realty_id = UNIO.t_object_card_state.cadastral_number
where year = '2022')

select * from tab21;

--Íîìåð àêòà, äàòà àêòà, äîïóñê íà îáúåêò, îáñòîÿòåëüñòâà, ðåçóëüòàò, êîììåíò, êîììåíò ê ðåçóëüòàòó

DROP TABLE mp_tab23 PURGE;
CREATE table mp_tab23
AS

with tab23 as(
select distinct 
unio.t_object_card_state.cadastral_number, 
unio.t_gin_verification.NUMBER_SURVEY_ACT,
unio.t_gin_verification.DATE_OF_DRAWING_UP,
unio.t_gin_verification.INSPECTORS_GOT_TO_OKS,
unio.t_gin_verification.NOT_GOT_TO_OKS_CONDITIONS,
unio.t_directory_value.value, 
unio.t_gin_verification.comments, 
unio.t_gin_verification.results_comments 
from  unio.t_gin_verification@opndbp
left join UNIO.t_object_card_state@opndbp on unio.t_object_card_state.last_year_verification = unio.t_gin_verification.id
inner join unio.t_directory_value@opndbp on unio.t_directory_value.id@opndbp = UNIO.t_gin_verification.RESULT_ID
where year = '2022')

select * from tab23;
 
--Âêëþ÷åí â ïåðå÷åíü 21

DROP TABLE mp_tab24 PURGE;
CREATE table mp_tab24
AS

with tab24 as(
select cadastral_number,
case
when  FIXED_INCLUSION_CRITERION = 'DGI' 
then 'ÂÐÈ ÇÓ' 
when FIXED_INCLUSION_CRITERION = 'MVK' 
then 'ÂÔÈ' 
when FIXED_INCLUSION_CRITERION = 'VRI_ZU'
then 'ÂÐÈ ÇÓ'
when FIXED_INCLUSION_CRITERION = 'VFI'
then 'ÂÔÈ'
when FIXED_INCLUSION_CRITERION =  'EXCLUDED'
then 'Èñêëþ÷åí'
end as fix21
from unio.t_object_card_state@opndbp
left join mp_necelf on mp_necelf.realty_id = UNIO.t_object_card_state.cadastral_number
where year = '2021')

select * from tab24;

--Èíôîðìàöèÿ ïî ÇÓ 

DROP TABLE mp_tab2612 purge;
CREATE table mp_tab2612
AS
with tab123123 as ( 
select mp_necelf.realty_id, mp_necelf.land_cadnum, rosreestr_import.mv_land.cancel_date from mp_necelf
left join rosreestr_import.mv_land on rosreestr_import.mv_land.record_id = mp_necelf.land_cadnum)

select distinct * from tab123123;

DROP TABLE mp_tab2613 purge;
CREATE table mp_tab2613
AS

with tab2613 as ( 
select distinct read_user.mp_tab2612.realty_id, read_user.mp_tab2612.land_cadnum, read_user.mp_egrn60.PERCENT,  read_user.mp_egrn60.EGRN,  read_user.mp_egrn60.PKBD, cancel_date from read_user.mp_tab2612
left join  read_user.mp_egrn60 on read_user.mp_egrn60.cadnum =  read_user.mp_tab2612.realty_id
left join  read_user.mp_egrn60 on  read_user.mp_egrn60.land_cadnum =  read_user.mp_tab2612.land_cadnum
)

select * from tab2613;

--Ñîáñòâåííèê ÇÓ, âèä ïðàâà, äîëÿ

DROP TABLE mp_tab27 purge;
CREATE table mp_tab27
AS

with tab27 as(
select rosreestr_import.MV_land.record_id,( ROSREESTR_IMPORT.mv_right_owner.name || ROSREESTR_IMPORT.mv_right_owner.RIGHT_TYPE_NAME || ROSREESTR_IMPORT.mv_right_owner.SHARE_DESCRIPTION) as qwe1 from mp_necelf
left join rosreestr_import.MV_land on mp_necelf.land_cadnum = rosreestr_import.MV_land.record_id
left join ROSREESTR_IMPORT.mv_right_owner on ROSREESTR_IMPORT.mv_right_owner.cad_number = ROSREESTR_IMPORT.mv_land.record_id),

tab271 as(
SELECT tab27.record_id,
RTRIM(XMLAGG(XMLELEMENT(E,tab27.qwe1,',').EXTRACT('//text()') ORDER BY tab27.qwe1).GetClobVal(),',') AS name11
FROM tab27 
group by tab27.record_id)

select * from tab271;

--ÂÐÈ ÇÓ

DROP TABLE mp_tab28 PURGE;
CREATE table mp_tab28
AS

with tab28 as(
select rosreestr_import.mv_land.record_id, rosreestr_import.mv_land.pu_by_document,rosreestr_import.mv_land.reg_date, rosreestr_import.mv_land.category from mp_necelf
inner join rosreestr_IMPORT.mv_land on mp_necelf.land_cadnum = rosreestr_IMPORT.mv_land.record_id)
select * from tab28;

--ÂÐÈ ÇÓ 2020

DROP TABLE mp_tab30 PURGE;
CREATE table mp_tab30
AS

with tab30 as(
select distinct mp_tab2613.land_cadnum, asur_cr2_20200707.mv_land.vri_by_doc, asur_cr2_20200707.t$cr#parcel_doc.doc_id from mp_tab2613
left join asur_cr2_20200707.mv_land on mp_tab2613.land_cadnum = asur_cr2_20200707.mv_land.cadnum
left join asur_cr2_20200707.t$cr#parcel_doc on asur_cr2_20200707.t$cr#parcel_doc.parcel_id = mp_tab2613.land_cadnum)

select * from tab30;


DROP TABLE mp_tab31 purge; 
CREATE table mp_tab31

AS

with tab31 as(
SELECT DISTINCT
    mp_tab30.land_cadnum,
    mp_tab30.vri_by_doc,
    asur_cr2_20200707.t$cr#doc.name AS name4,
    read_user.library_vri_zu_20200929.group_vri_zu,
    asur_cr2_20200707.t$cr#doc.dt
FROM
    (
        SELECT
            mp_tab30.land_cadnum,
            MAX(asur_cr2_20200707.t$cr#doc.dt) AS dt
        FROM
            mp_tab30
            INNER JOIN asur_cr2_20200707.t$cr#doc ON asur_cr2_20200707.t$cr#doc.doc_id = mp_tab30.doc_id
        GROUP BY
            mp_tab30.land_cadnum
    ) tab1
     left join mp_tab30 on mp_tab30.land_cadnum = tab1.land_cadnum
    LEFT JOIN asur_cr2_20200707.t$cr#doc ON mp_tab30.doc_id = asur_cr2_20200707.t$cr#doc.doc_id
    JOIN read_user.library_vri_zu_20200929 ON read_user.library_vri_zu_20200929.vri = mp_tab30.vri_by_doc)

select * from tab31;

--Áåñõîç

DROP TABLE mp_tab32 PURGE;
CREATE table mp_tab32
AS

with tab32 as(
select * from read_user.av_egrp_20200707
right join mp_necelf on mp_necelf.realty_id = read_user.av_egrp_20200707.num_cadnum
where read_user.av_egrp_20200707.TP_NAME like '%áåñõîç%')

select * from tab32;

DROP TABLE mp_tab33 PURGE;
CREATE table mp_tab33
AS

with tab33 as(
select num_cadnum, case 
when tp_name = 'Ïðèíÿò íà ó÷åò êàê áåñõîçÿéíûé îáúåêò íåäâèæèìîãî èìóùåñòâà'
then 'Äà'
Else 'Íåò'
end as beshoz
from mp_tab32
)

select * from tab33;

--Èòîãîâàÿ âûãðóçêà îòîáðàíûõ îáúåêòîâ

DROP TABLE mp_necel_full purge;
CREATE table mp_necel_full
AS

select distinct
MP_NECELF.realty_id as "Êàäàñòðîâûé íîìåð îáúåêòà",
mp_tab33.beshoz as "Áåñõîç",
dbms_lob.substr(mp_tab11.name1, 4000, 1) as "Ñîáñòâåííèê ÎÊÑ",
mp_tab12.area1 as "Îáùàÿ ïëîùàäü íåæåë",
mp_tab13.area2 as "Ïëîùàäü ñ ïðàâîì",
mp_tab16.area as "Ïëîùàäü îáúåêòà",
mp_tab16.object_type as "Òèï îáúåêòà",
mp_tab16.name as "Òèï è íàçíà÷åíèå îáúåêòà",
mp_tab16.addr_gkn_struct as  Àäðåñ,
mp_tab16.living as "Æèëîå",
mp_tab16.IS_NEW_MOSCOW as "Íîâàÿ Ìîñêâà",
dbms_lob.substr(mp_tab18.note, 4000, 1) as "Êîììåíòàðèé ÅÃÐÍ",
case 
when mp_tab21.moscow_ownership  = 'OPERATIONAL_OWN'
then 'Äà'
end as "Ñîáñòâåííîñòü ÌÑÊ",
case 
when mp_tab21.rf_ownership  = 'OPERATIONAL_OWN'
then 'Äà'
end as "Ôåäåðàëüíàÿ ñîáñòâåííîñòü",
mp_tab211.okn_fz as ÎÊÍ,
mp_tab21.pedestrian_zone as "Ïåøåõîäíàÿ çîíà",
mp_tab21.INCLUDE_BY_BTI as "Ïðèçíàê çíà÷åíèÿ ÁÒÈ",
mp_tab24.fix21 as "Âêëþ÷åí â ïåðå÷åíü 2021",
mp_tab21.fix22 as "Âêëþ÷åí â ïåðå÷åíü 2022",
mp_tab23.number_survey_act as "Íîìåð àêòà",
mp_tab23.date_of_drawing_up as "Äàòà àêòà",
mp_tab23.inspectors_got_to_oks as "Äîïóùåí íà îáúåêò",
mp_tab23.NOT_GOT_TO_OKS_CONDITIONS as "Îáñòîÿòåëüñòâà ïðåïÿòñòâóþùèå",
mp_tab23.value as "Ðåçóëüòàò",
mp_tab23.comments as "Êîìåíòàðèé èç êàðòî÷êè",
mp_tab23.results_comments as "Êîìåíòàðèé ê ðåçóëüòàòó",
mp_tab2613.land_cadnum as "ÇÓ",
case 
when dbms_lob.substr(mp_tab2613.cancel_date, 4000, 1) is null
then 'Àêòóàëüíûé'
else 'Aðõèâíûé'
end as "Ñòàòóñ ÇÓ",
case
when mp_tab2613.PKBD = '99'
then 'ÏÊÁÄ'
else 'ÃÊÍ' 
end as "Èñòî÷íèê èíôîðìàöèè ÇÓ",
mp_tab2613.percent as "% ïåðåñå÷åíèÿ ñ ÇÓ",
dbms_lob.substr(mp_tab28.pu_by_document, 4000, 1) as "ÂÐÈ ÇÓ â òåêùåì äàìïå",
dbms_lob.substr(mp_tab28.reg_date, 4000, 1) as "Äàòà ïðèñâîåíèÿ ÂÐÈ",
dbms_lob.substr(mp_tab271.name11,4000, 1) as "Ñîáñòâåííèê ÇÓ",
mp_tab28.category as "Êàòåãîðèÿ",
mp_tab31.vri_by_doc as "ÂÐÈ ÇÓ 07 07 2020",
mp_tab31.DT as "Äàòà ïðèñâîåíèÿ ÂÐÈ20",
mp_tab31.name4 as "Äîêóìåíò ïðèñâîåíèÿ ÂÐÈ",
mp_tab31.group_vri_zu as "Êàòåãîðèÿ ÇÓ"

from mp_necelf

left join mp_tab11 on MP_NECELF.realty_id = mp_tab11.realty_id
left join mp_tab211 on mp_necelf.realty_id = mp_tab211.realty_id
left join mp_tab33 on mp_tab33.num_cadnum = mp_necelf.realty_id
left join mp_tab12 on MP_NECELF.realty_id = mp_tab12.oks_cadnum
left join mp_tab13 on MP_NECELF.realty_id = mp_tab13.oks_cadnum
left join mp_tab16 on MP_NECELF.realty_id = mp_tab16.cadnum
left join mp_tab18 on MP_NECELF.realty_id = mp_tab18.realty_id
left join mp_tab21 on MP_NECELF.realty_id = mp_tab21.cadastral_number
left join mp_tab23 on MP_NECELF.realty_id = mp_tab23.cadastral_number
left join mp_tab24 on MP_NECELF.realty_id = mp_tab24.cadastral_number
left join mp_tab2613 on MP_NECELF.land_cadnum = mp_tab2613.land_cadnum
and MP_NECELF.realty_id = mp_tab2613.realty_id
left join mp_tab271 on mp_necelf.land_cadnum = mp_tab271.record_id
left join mp_tab28 on mp_necelf.land_cadnum = mp_tab28.record_id
left join mp_tab30 on mp_necelf.land_cadnum = mp_tab30.land_cadnum
left join mp_tab31 on mp_necelf.land_cadnum = mp_tab31.land_cadnum;

-- ×èñòèì ïóñòóþ ïëîùàäü

DROP TABLE mp_necel_final purge;
CREATE table mp_necel_final
AS

select * from mp_necel_full
where "Îáùàÿ ïëîùàäü íåæåë" is not null;
