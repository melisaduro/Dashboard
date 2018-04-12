----Guardo copia temporal de las tablas
select * into [AGRIDS].[dbo].lcc_dashboard_info_scopes_NEW_backup
from [AGRIDS].[dbo].lcc_dashboard_info_scopes_NEW

select * into [AGRIDS].[dbo].lcc_dashboard_info_voice_backup
from [AGRIDS].[dbo].lcc_dashboard_info_voice

select * into [AGRIDS].[dbo].lcc_dashboard_info_data_backup
from [AGRIDS].[dbo].lcc_dashboard_info_data

SELECT * FROM [AGRIDS].[dbo].lcc_dashboard_info_data_backup

select * into [AGRIDs_v2].[dbo].lcc_ciudades_tipo_Project_V9_backup_20170220
from [AGRIDs_v2].[dbo].lcc_ciudades_tipo_Project_V9

------Cambio scope railways


select * from [AGRIDS].[dbo].lcc_dashboard_info_scopes_NEW
where report='MUN'
and scope like 'RAILWAYS'

begin transaction
update [AGRIDS].[dbo].lcc_dashboard_info_scopes_NEW
set scope = 'RAILWAYS'
where report='MUN'
and scope like 'RAILWAYS EXTRA'
commit

----Cambio 3G_2G por 3G

select * from [AGRIDS].[dbo].lcc_dashboard_info_voice 
where technology= '3G'

begin transaction
update [AGRIDS].[dbo].lcc_dashboard_info_voice 
set technology = '3G'
where technology= '3G_2G'
commit

select * from [AGRIDS].[dbo].lcc_dashboard_info_data
where technology= '3G'

begin transaction
update [AGRIDS].[dbo].lcc_dashboard_info_data
set technology = '3G'
where technology= '3G_2G'
commit

---------Cambio LA Coruña Station por Coruña Station
SELECT * FROM [AGRIDS].[dbo].lcc_dashboard_info_scopes_NEW
WHERE ENTITIES_BBDD = 'CORU-RLW'

BEGIN TRANSACTION
UPDATE [AGRIDS].[dbo].lcc_dashboard_info_scopes_NEW
SET ENTITIES_DASHBOARD='CORUÑA STATION'
WHERE ENTITIES_BBDD = 'CORU-RLW'

COMMIT

------BACKUPs creados

------------Cambio 4G_CAONLY por 4G_CA_ONLY
select * from [AGRIDS].[dbo].lcc_dashboard_info_data
where technology= '4G_CAONLY'

begin transaction
update [AGRIDS].[dbo].lcc_dashboard_info_data
set technology = '4G_CA_ONLY'
where technology= '4G_CAONLY'
commit

------------Cambio zona Canarias
select * from [AGRIDs_v2].[dbo].lcc_ciudades_tipo_Project_V9
where zona_OSP='zona4'

begin transaction
update [AGRIDs_v2].[dbo].lcc_ciudades_tipo_Project_V9
set zona_OSP='Zona4'
where zona_OSP='zona6'
commit

---------Cambio provincias/comunidades autonomas
select * from [AGRIDs_v2].[dbo].lcc_ciudades_tipo_Project_V9
where CCAA in ('Pais Vasco')--,'Castilla León','Catalunya','Ceuta','Islas Canarias','Madrid','Melilla','Pais Vasco')

begin transaction
update [AGRIDs_v2].[dbo].lcc_ciudades_tipo_Project_V9
set CCAA = 'País Vasco'
where CCAA in ('Pais Vasco')
commit

select * from [AGRIDs_v2].[dbo].lcc_ciudades_tipo_Project_V9
where Provincia =('SCTENERIFE')--'BALEARES','CIUDADREAL','CORUNA','ORENSE','PALMAS','RIOJA','SCTENERIFE'

begin transaction
update [AGRIDs_v2].[dbo].lcc_ciudades_tipo_Project_V9
set Provincia = 'SANTA_CRUZ_DE_TENERIFE'
Where Provincia =('SCTENERIFE')
COMMIT

-----------Cambio Carrier Aggregattion a Y

select * from [AGRIDS].[dbo].lcc_dashboard_info_data
where technology like '%4G%'
and carrier_aggregation='n'

begin transaction
update [AGRIDS].[dbo].lcc_dashboard_info_data
set carrier_aggregation='Y'
where technology like '%4G%'
and carrier_aggregation='N'
commit

----------------Cambio terminal/firmware/handset
----DATOS
select * from [AGRIDS].[dbo].lcc_dashboard_info_data
where 
scope like '%PLACES OF CONCENTRATION%' 
AND CARRIER_AGGREGATION = 'N'
and (scope like '%add-on%' or scope like '%touristic%')

begin transaction
update [AGRIDS].[dbo].lcc_dashboard_info_data
set HANDSET_CAPABILITY='42.2/5.76'
where scope like '%PLACES OF CONCENTRATION%' 
commit

select * from [AGRIDS].[dbo].lcc_dashboard_info_data
where technology='3G'

begin transaction
update [AGRIDS].[dbo].lcc_dashboard_info_data
set HANDSET_CAPABILITY='42.2/5.76'
where technology='3G'
commit


select * from [AGRIDS].[dbo].lcc_dashboard_info_data
where 
scope like '%railways%' 

begin transaction
update [AGRIDS].[dbo].lcc_dashboard_info_data
set firmware_version='G901FXXU1ANH5'
where scope like '%railways%' 
commit


-----Cambio San Mamés

select * from [AGRIDs_v2].[dbo].lcc_ciudades_tipo_Project_V9
where Entity_name='ATH-STD'

begin transaction
update [AGRIDs_v2].[dbo].lcc_ciudades_tipo_Project_V9
set Zona_OSP='Zona2'
where Entity_name='ATH-STD'
commit

begin transaction
update [AGRIDs_v2].[dbo].lcc_ciudades_tipo_Project_V9
set CCAA='Pais Vasco'
where Entity_name='ATH-STD'
commit

begin transaction
update [AGRIDs_v2].[dbo].lcc_ciudades_tipo_Project_V9
set Zona_VF='Region4'
where Entity_name='ATH-STD'
commit




