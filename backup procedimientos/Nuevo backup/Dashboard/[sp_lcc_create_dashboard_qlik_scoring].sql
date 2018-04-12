USE [master]
GO
/****** Object:  StoredProcedure [dbo].[sp_lcc_create_dashboard_qlik_scoring]    Script Date: 13/11/2017 10:49:50 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER procedure [dbo].[sp_lcc_create_dashboard_qlik_scoring] 
as

-------------------------------------------------------------------------------
-- 1.-- Inicialización de variables
-------------------------------------------------------------------------------
declare @NumOperators as int
declare @targetV5 as float=0.97
declare @targetV6 as float=0.017

DECLARE @SQLString nvarchar(4000)

-------------------------------------------------------------------------------
-- 2.-- Cálculo del Score para datos
-------------------------------------------------------------------------------
-- 2.1-- Tabla con los KPIs involucrados en el score, ordenados de menor a mayor
drop table [DASHBOARD].[dbo].lcc_data_kpis_region
select a.[TARGET ON SCOPE] as Scope
		,a.ENTITIES_DASHBOARD as Entidad
		,a.mnc
		,a.DL_CE_D1 as D1
		,ROW_NUMBER() OVER (PARTITION BY a.ENTITIES_DASHBOARD ORDER BY a.DL_CE_D1 asc) AS RowNumber_D1
		,a.DL_CE_D2 as D2
		,ROW_NUMBER() OVER (PARTITION BY a.ENTITIES_DASHBOARD ORDER BY a.DL_CE_D2 asc) AS RowNumber_D2
		,a.UL_CE_D3 as D3
		,ROW_NUMBER() OVER (PARTITION BY a.ENTITIES_DASHBOARD ORDER BY a.UL_CE_D3 asc) AS RowNumber_D3
		,a.LAT_MEDIAN as D4
		,ROW_NUMBER() OVER (PARTITION BY a.ENTITIES_DASHBOARD ORDER BY a.LAT_MEDIAN desc) AS RowNumber_D4
		,a.WEB_D5 as D5
		,ROW_NUMBER() OVER (PARTITION BY a.ENTITIES_DASHBOARD ORDER BY a.WEB_D5 desc) AS RowNumber_D5
		,1.0*a.DL_CE_CONNECTIONS_TH_1MBPS/(a.DL_CE_ATTEMPTS-DL_CE_ERRORS_ACCESSIBILITY-DL_CE_ERRORS_RETAINABILITY) as D6
		,ROW_NUMBER() OVER (PARTITION BY a.ENTITIES_DASHBOARD ORDER BY 1.0*a.DL_CE_CONNECTIONS_TH_1MBPS/(a.DL_CE_ATTEMPTS-DL_CE_ERRORS_ACCESSIBILITY-DL_CE_ERRORS_RETAINABILITY) asc) AS RowNumber_D6
into [DASHBOARD].[dbo].lcc_data_kpis_region
from [DASHBOARD].[dbo].lcc_data_dashboard_results_region_road_step1 a
order by mnc,ENTITIES_DASHBOARD

-- 2.2-- Número de operadores a tener en cuenta. Tras el ordenado de la tabla anterior, el líder coincidirá con el número de operadores.
set @NumOperators= (select count(a.mnc) as operator from (select distinct mnc from [DASHBOARD].[dbo].lcc_data_kpis_region) a)

-- 2.3-- Tabla con las regiones a considerar
drop table [DASHBOARD].[dbo].lcc_qlik_scoring_regions
select distinct entidad
into [DASHBOARD].[dbo].lcc_qlik_scoring_regions
from [DASHBOARD].[dbo].lcc_data_kpis_region

-- 2.4-- Tabla con el score por KPI de datos
drop table [DASHBOARD].[dbo].lcc_data_leadersBYregion
select w.entidad
		,case when a.mnc=1 then 1
			else 0 
			end as D1_leader 
		,case when b.mnc=1 then 1
			else 0 
			end as D2_leader
		,case when c.mnc=1 then 1 
			else 0
			end as D3_leader
		,case when d.mnc=1 then 1
			else 0
			end as D4_leader
		,case when e.mnc=1 then 1 
			else 0
			end as D5_leader
		,case when f.mnc=1 then 1
			else 0
			end as D6_leader
into [DASHBOARD].[dbo].lcc_data_leadersBYregion
from [DASHBOARD].[dbo].lcc_qlik_scoring_regions w
,(select entidad,mnc
from [DASHBOARD].[dbo].lcc_data_kpis_region
where RowNumber_D1=@NumOperators) a
,(select entidad,mnc
from [DASHBOARD].[dbo].lcc_data_kpis_region
where RowNumber_D2=@NumOperators) b
,(select entidad,mnc
from [DASHBOARD].[dbo].lcc_data_kpis_region
where RowNumber_D3=@NumOperators) c
,(select entidad,mnc
from [DASHBOARD].[dbo].lcc_data_kpis_region
where RowNumber_D4=@NumOperators) d
,(select entidad,mnc
from [DASHBOARD].[dbo].lcc_data_kpis_region
where RowNumber_D5=@NumOperators) e
,(select entidad,mnc
from [DASHBOARD].[dbo].lcc_data_kpis_region
where RowNumber_D6=@NumOperators) f
where w.entidad=a.entidad and w.entidad=b.entidad and w.entidad=c.entidad and w.entidad=d.entidad
	and w.entidad=e.entidad and w.entidad=f.entidad

-------------------------------------------------------------------------------
-- 3.-- Cálculo del Score para voz
-------------------------------------------------------------------------------
-- 3.1-- Tabla con los KPIs involucrados en el score, ordenados de menor a mayor
drop table [DASHBOARD].[dbo].lcc_voice_kpis_region
select a.[TARGET_SCOPE] as Scope
		,a.ENTITIES_DASHBOARD as Entidad
		,a.mnc
		,1-(1.0*a.CALLS_FAILURES/a.CALLS_ATTEMPTS) as V5
		,ROW_NUMBER() OVER (PARTITION BY a.ENTITIES_DASHBOARD ORDER BY 1-(1.0*a.CALLS_FAILURES/a.CALLS_ATTEMPTS) asc) AS RowNumber_V5
		,1.0*a.CALLS_DROPS/(a.CALLS_ATTEMPTS-a.CALLS_FAILURES) as V6
		,ROW_NUMBER() OVER (PARTITION BY a.ENTITIES_DASHBOARD ORDER BY 1.0*a.CALLS_DROPS/(a.CALLS_ATTEMPTS-a.CALLS_FAILURES) desc) AS RowNumber_V6
into [DASHBOARD].[dbo].lcc_voice_kpis_region
from [DASHBOARD].[dbo].lcc_voice_dashboard_results_4G_M2M_region_road_step1 a
order by mnc,ENTITIES_DASHBOARD

-- 3.2-- Número de operadores a tener en cuenta. Tras el ordenado de la tabla anterior, el líder coincidirá con el número de operadores.
set @NumOperators= (select count(a.mnc) as operator from (select distinct mnc from [DASHBOARD].[dbo].lcc_voice_kpis_region) a)

-- 3.3-- Tabla con las regiones a considerar
drop table [DASHBOARD].[dbo].lcc_qlik_scoring_regions
select distinct entidad
into [DASHBOARD].[dbo].lcc_qlik_scoring_regions
from [DASHBOARD].[dbo].lcc_voice_kpis_region

-- 3.4-- Tabla con el score por KPI de datos
drop table [DASHBOARD].[dbo].lcc_voice_leadersBYregion
select w.entidad,V5,V6
		,case	when a.mnc=1 and V5 >= @targetV5 then 2
				when a.mnc=1 and V5 < @targetV5 then 1
				else 0 
		end as V5_leader 
		,case	when b.mnc=1 and V6 < @targetV6 then 4
				when b.mnc=1 and V6 >= @targetV6 then 2
				else 0 
		end as V6_leader
into [DASHBOARD].[dbo].lcc_voice_leadersBYregion
from [DASHBOARD].[dbo].lcc_qlik_scoring_regions w
,(select entidad,mnc,V5
from [DASHBOARD].[dbo].lcc_voice_kpis_region
where RowNumber_V5=@NumOperators) a
,(select entidad,mnc,V6
from [DASHBOARD].[dbo].lcc_voice_kpis_region
where RowNumber_V6=@NumOperators) b
where w.entidad=a.entidad and w.entidad=b.entidad

-------------------------------------------------------------------------------
-- 4.-- Resultado final
-------------------------------------------------------------------------------
drop table [DASHBOARD].[dbo].lcc_qlik_scoring
select d.entidad as Region
		 ,d.D1_leader+d.D2_leader+d.D3_leader+d.D4_leader+d.D5_leader+d.D6_leader as Score_data
		 ,v.V5_leader+v.V6_leader as Score_voz
		 ,d.D1_leader+d.D2_leader+d.D3_leader+d.D4_leader+d.D5_leader+d.D6_leader+v.V5_leader+v.V6_leader as Score
		 ,case	when (d.D1_leader+d.D2_leader+d.D3_leader+d.D4_leader+d.D5_leader+d.D6_leader+v.V5_leader+v.V6_leader) >12 then 'NOK'
				when (d.D1_leader+d.D2_leader+d.D3_leader+d.D4_leader+d.D5_leader+d.D6_leader+v.V5_leader+v.V6_leader) <=12 then 'OK'
		 end as Check_Score
into [DASHBOARD].[dbo].lcc_qlik_scoring
from [DASHBOARD].[dbo].lcc_data_leadersBYregion d
	,[DASHBOARD].[dbo].lcc_voice_leadersBYregion v
	where d.entidad=v.entidad


