USE [master]
GO
/****** Object:  StoredProcedure [dbo].[sp_lcc_km2_medidos_voz]    Script Date: 29/05/2017 15:21:42 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

--/****************************************************************************************

--+++ Procedimiento que calcula la cantidad de parcelas que medimos, el área cubierta +++
--+++ y el porcentaje medido con respecto al total de la entidad						+++

--****************************************************************************************/


ALTER procedure [dbo].[sp_lcc_km2_medidos_voz] (
	@prefix as varchar(256),
	@sheetTech as varchar (256),
	@LA as bit
)
as

-- Definición de variables
--declare @prefix as varchar(256)= 'UPDATE_AGGRVoice4G_'
--declare @sheetTech as varchar(256) =''
--declare @la bit=0

DECLARE @SQLString nvarchar(4000)
declare @LAfilter as varchar(256)
declare @database as varchar (256)= 'DASHBOARD'


if @la = 1 set @LAfilter =' a.entorno not like ''%LA%'' and a.entorno in (''8G'',''32G'')' 
else set @LAfilter= ' a.entorno like ''%%'' or a.entorno is null'

-- Para introducir el procedimiento el todas las BBDD del sistema
--exec sp_ms_marksystemobject sp_lcc_km2_medidos

-- Borra la tabla donde almacenamos los datos en el caso de que exista
exec dashboard.dbo.sp_lcc_dropifexists 'lcc_km2_chequeo_mallado_voz'
exec dashboard.dbo.sp_lcc_dropifexists 'lcc_km2_medidos'
exec dashboard.dbo.sp_lcc_dropifexists 'lcc_km2_totales'

-- Sacamos el total de las parcelas para cada entidad
SET @SQLString =N'
				select  a.Entidad_contenedora,
				count(a.nombre) as total_parcelas,
				count(a.Entidad_contenedora)*0.25 as [AreaTotal(km2)]
				into dashboard.dbo.lcc_km2_totales
				from agrids.dbo.lcc_parcelas a
				where '+ @LAfilter +'
				group by a.Entidad_contenedora'
EXECUTE sp_executesql @SQLString

-- Calculamos las parcelas y el area que medimos de cada entidad
SET @SQLString =N'
					select
						a.entidad,
						count(a.entidad) as Parcelas,
						count(a.entidad)*0.25 as [Area(km2)],
						a.Meas_date						
					into dashboard.dbo.lcc_km2_medidos
					from(
							select parcel,meas_Date,entidad,entorno
							from '+@database+'.dbo.'+@prefix+'lcc_aggr_sp_MDD_Voice_mallado'+@sheetTech+'
							group by parcel,meas_Date,entidad,entorno) a
					where '+ @LAfilter +' 
					group by a.entidad,a.meas_Date'
EXECUTE sp_executesql @SQLString

----Cruzamos las tablas de las parcelas que medimos con las totales para sacar los porcentajes
select m.Entidad,
m.meas_date,
m.Parcelas,
m.[Area(km2)],
--db_name() DDBB,
(m.Parcelas*1.0/t.total_parcelas)*100 as [Porcentaje_medido],
t.total_parcelas,
t.[AreaTotal(km2)]
--m.Entorno
into dashboard.dbo.lcc_km2_chequeo_mallado_voz
from
dashboard.dbo.lcc_km2_medidos m, dashboard.dbo.lcc_km2_totales t
where m.Entidad = t.Entidad_contenedora

-- Borramos las tablas temporales
drop table dashboard.dbo.lcc_km2_medidos,dashboard.dbo.lcc_km2_totales