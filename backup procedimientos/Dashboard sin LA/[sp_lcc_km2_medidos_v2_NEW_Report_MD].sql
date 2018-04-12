USE [master]
GO
/****** Object:  StoredProcedure [dbo].[sp_lcc_km2_medidos_v2_NEW_Report_MD]    Script Date: 20/06/2017 13:08:56 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/****************************************************************************************

+++ Procedimiento que calcula la cantidad de parcelas que medimos, el área cubierta +++
+++ y el porcentaje medido con respecto al total de la entidad						+++

****************************************************************************************/


ALTER procedure [dbo].[sp_lcc_km2_medidos_v2_NEW_Report_MD] (
	@prefix as varchar(256),
	@sheetTech as varchar (256),
	@report as varchar(256)
)
as

-- Definición de variables
--declare @prefix as varchar(256)= 'UPDATE_AGGRData4G_'
--declare @sheetTech as varchar(256) =''
--declare @la bit=1

DECLARE @SQLString nvarchar(4000)
declare @database as varchar (256)= 'DASHBOARD'


-- Para introducir el procedimiento el todas las BBDD del sistema
--exec sp_ms_marksystemobject sp_lcc_km2_medidos

-- Borra la tabla donde almacenamos los datos en el caso de que exista
exec dashboard.dbo.sp_lcc_dropifexists 'lcc_km2_chequeo_mallado'
exec dashboard.dbo.sp_lcc_dropifexists 'lcc_km2_medidos'
exec dashboard.dbo.sp_lcc_dropifexists 'lcc_km2_totales'

-- Sacamos el total de las parcelas para cada entidad
SET @SQLString =N'
				select  a.Entidad_contenedora,
				count(a.nombre) as total_parcelas,
				count(a.Entidad_contenedora)*0.25 as [AreaTotal(km2)]
				into dashboard.dbo.lcc_km2_totales
				from agrids.dbo.lcc_parcelas a
				group by a.Entidad_contenedora'
EXECUTE sp_executesql @SQLString

-- Calculamos las parcelas y el area que medimos de cada entidad

if @sheetTech <> '_CA_ONLY'
begin	
SET @SQLString =N'
					select
						a.entidad,
						count(a.entidad) as Parcelas,
						count(a.entidad)*0.25 as [Area(km2)],
						a.Meas_date						
					into dashboard.dbo.lcc_km2_medidos
					from(
						select a.parcel, a.meas_date, a.entidad,a.entorno
						from 
							(select parcel,meas_Date,entidad,entorno
								from '+@database+'.dbo.'+@prefix+'lcc_aggr_sp_MDD_Data_DL_Thput_CE'+@sheetTech+'
								--where mnc=01
								where Report_Type = '''+@report+'''
								group by parcel,meas_Date,entidad,entorno
							Union all
								select parcel,meas_Date,entidad,entorno
								from '+@database+'.dbo.'+@prefix+'lcc_aggr_sp_MDD_Data_DL_Thput_NC'+@sheetTech+'
								--where mnc=01
								where Report_Type = '''+@report+'''
								group by parcel,meas_Date,entidad,entorno
							Union all
								select parcel,meas_Date,entidad,entorno
								from '+@database+'.dbo.'+@prefix+'lcc_aggr_sp_MDD_Data_Ping'+@sheetTech+'
								--where mnc=01
								where Report_Type = '''+@report+'''
								group by parcel,meas_Date,entidad,entorno 
							Union all
								select parcel,meas_Date,entidad,entorno
								from '+@database+'.dbo.'+@prefix+'lcc_aggr_sp_MDD_Data_UL_Thput_CE'+@sheetTech+'
								--where mnc=01
								where Report_Type = '''+@report+'''
								group by parcel,meas_Date,entidad,entorno
							union all
								select parcel,meas_Date,entidad,entorno
								from '+@database+'.dbo.'+@prefix+'lcc_aggr_sp_MDD_Data_UL_Thput_NC'+@sheetTech+'
								--where mnc=01
								where Report_Type = '''+@report+'''
								group by parcel,meas_Date,entidad,entorno
							union all
								select parcel,meas_Date,entidad,entorno
								from '+@database+'.dbo.'+@prefix+'lcc_aggr_sp_MDD_Data_Web'+@sheetTech+'
								--where mnc=01
								where Report_Type = '''+@report+'''
								group by parcel,meas_Date,entidad,entorno
							union all
								select parcel,meas_Date,entidad,entorno
								from '+@database+'.dbo.'+@prefix+'lcc_aggr_sp_MDD_Data_Youtube'+@sheetTech+'
								--where mnc=01
								where Report_Type = '''+@report+'''
								group by parcel,meas_Date,entidad,entorno
							union all
								select parcel,meas_Date,entidad,entorno
								from '+@database+'.dbo.'+@prefix+'lcc_aggr_sp_MDD_Data_Youtube_HD'+@sheetTech+'
								--where mnc=01
								where Report_Type = '''+@report+'''
								group by parcel,meas_Date,entidad,entorno) a
								group by parcel,meas_date,entidad,entorno ) a
							group by a.entidad,a.meas_Date'
end
if @sheetTech = '_CA_ONLY'
begin
SET @SQLString =N'
					select
						a.entidad,
						count(a.entidad) as Parcelas,
						count(a.entidad)*0.25 as [Area(km2)],
						a.Meas_date						
					into dashboard.dbo.lcc_km2_medidos
					from(
						select a.parcel, a.meas_date, a.entidad,a.entorno
						from 
							(select parcel,meas_Date,entidad,entorno
								from '+@database+'.dbo.'+@prefix+'lcc_aggr_sp_MDD_Data_DL_Thput_CE'+@sheetTech+'
								--where mnc=01
								where Report_Type = '''+@report+'''
								group by parcel,meas_Date,entidad,entorno
							Union all
								select parcel,meas_Date,entidad,entorno
								from '+@database+'.dbo.'+@prefix+'lcc_aggr_sp_MDD_Data_DL_Thput_NC'+@sheetTech+'
								--where mnc=01
								where Report_Type = '''+@report+'''
								group by parcel,meas_Date,entidad,entorno
							Union all
								select parcel,meas_Date,entidad,entorno
								from '+@database+'.dbo.'+@prefix+'lcc_aggr_sp_MDD_Data_Ping'+@sheetTech+'
								--where mnc=01
								where Report_Type = '''+@report+'''
								group by parcel,meas_Date,entidad,entorno 
							Union all
								select parcel,meas_Date,entidad,entorno
								from '+@database+'.dbo.'+@prefix+'lcc_aggr_sp_MDD_Data_UL_Thput_CE'+@sheetTech+'
								--where mnc=01
								where Report_Type = '''+@report+'''
								group by parcel,meas_Date,entidad,entorno
							union all
								select parcel,meas_Date,entidad,entorno
								from '+@database+'.dbo.'+@prefix+'lcc_aggr_sp_MDD_Data_UL_Thput_NC'+@sheetTech+'
								--where mnc=01
								where Report_Type = '''+@report+'''
								group by parcel,meas_Date,entidad,entorno
							union all
								select parcel,meas_Date,entidad,entorno
								from '+@database+'.dbo.'+@prefix+'lcc_aggr_sp_MDD_Data_Web'+@sheetTech+'
								--where mnc=01
								where Report_Type = '''+@report+'''
								group by parcel,meas_Date,entidad,entorno
							union all
								select parcel,meas_Date,entidad,entorno
								from '+@database+'.dbo.'+@prefix+'lcc_aggr_sp_MDD_Data_Youtube_HD'+@sheetTech+'
								--where mnc=01
								where Report_Type = '''+@report+'''
								group by parcel,meas_Date,entidad,entorno) a
								group by parcel,meas_date,entidad,entorno ) a
							group by a.entidad,a.meas_Date'
end	

EXECUTE sp_executesql @SQLString

----Cruzamos las tablas de las parcelas que medimos con las totales para sacar los porcentajes
select m.Entidad,
m.meas_date,
m.Parcelas,
m.[Area(km2)],
--db_name() DDBB,
--(m.Parcelas*1.0/t.total_parcelas)*100 as [Porcentaje_medido],
case 
	when ((m.Parcelas*1.0/t.total_parcelas)*100) >100 then 100
	else (m.Parcelas*1.0/t.total_parcelas)*100 end as [Porcentaje_medido],
t.total_parcelas,
t.[AreaTotal(km2)]
--m.Entorno
into dashboard.dbo.lcc_km2_chequeo_mallado
from
dashboard.dbo.lcc_km2_medidos m, dashboard.dbo.lcc_km2_totales t
where m.Entidad = t.Entidad_contenedora

-- Borramos las tablas temporales
drop table dashboard.dbo.lcc_km2_medidos,dashboard.dbo.lcc_km2_totales

