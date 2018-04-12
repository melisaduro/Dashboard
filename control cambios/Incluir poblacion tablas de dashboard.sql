----Eliminamos la copia de backup antigua
drop table AGRIDS.dbo.lcc_dashboard_info_scopes_NEW_backup

---Creamos una copia de backup para hacer los cambios
select * 
into AGRIDS.dbo.lcc_dashboard_info_scopes_NEW_backup_20170228
from AGRIDS.dbo.lcc_dashboard_info_scopes_NEW 

--Cambiamos el tipo de la columna population por un float, como en la tabla v9
alter table AGRIDS.dbo.lcc_dashboard_info_scopes_NEW_backup_20170228
alter column [POPULATION] float

---- Eliminamos los registros con datos para cargar los nuevos
select *
from AGRIDS.dbo.lcc_dashboard_info_scopes_NEW_backup_20170228
where POPULATION = ''

begin transaction
update AGRIDS.dbo.lcc_dashboard_info_scopes_NEW_backup_20170228
set POPULATION=''
where POPULATION is not null
commit
rollback

--Copiamos los registros de la tabla V9 en la tabla del dashboard 

begin transaction
update AGRIDS.dbo.lcc_dashboard_info_scopes_NEW_backup_20170228 
set [POPULATION]=v.pob13
from AGRIDs_v2.dbo.lcc_ciudades_tipo_Project_V9 v
inner join AGRIDS.dbo.lcc_dashboard_info_scopes_NEW_backup_20170228 d
on v.entity_name=d.entities_bbdd
commit

--Hacemos las comprobaciones para chequear (estarán a null los RW, ROAD y POCs)
select *
from AGRIDS.dbo.lcc_dashboard_info_scopes_NEW_backup_20170228
where POPULATION = ''
order by 2

select *
from AGRIDs_v2.dbo.lcc_ciudades_tipo_Project_V9 v
inner join AGRIDS.dbo.lcc_dashboard_info_scopes_NEW_backup_20170228 d
on (v.entity_name=d.entities_bbdd and v.pob13=d.population )

