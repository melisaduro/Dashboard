USE [AddedValue]
GO
/****** Object:  StoredProcedure [dbo].[plcc_Data_statistics_Columns_new_Williams]    Script Date: 21/03/2018 12:05:24 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


ALTER PROCEDURE [dbo].[plcc_Data_statistics_Columns_new_Williams]

	 @monthyear as nvarchar(50)
    ,@ReportWeek as nvarchar(50)
AS

--declare @monthyear as nvarchar(50) = '201710'
--declare @ReportWeek as nvarchar(50) = 'W41'


declare @filtro_report as varchar(12)

if (select name from sys.tables where name='_Percentiles_Data_Williams') is null
begin

  CREATE TABLE [dbo]._Percentiles_Data_Williams(
	[entidad] [varchar](255) NULL,
	[Percentil10_DL_CE][float] NULL,
	[Percentil90_DL_CE][float] NULL,
	[Percentil10_UL_CE][float] NULL,
	[Percentil90_UL_CE][float] NULL,
	[Percentil10_DL_NC][float] NULL,
	[Percentil90_DL_NC][float] NULL,
	[Percentil10_UL_NC][float] NULL,
	[Percentil90_UL_NC][float] NULL,
	[Percentil_PING][float] NULL,
	[Percentil10_DL_CE_SCOPE][float] NULL,
	[Percentil90_DL_CE_SCOPE][float] NULL,
	[Percentil10_UL_CE_SCOPE][float] NULL,
	[Percentil90_UL_CE_SCOPE][float] NULL,
	[Percentil10_DL_NC_SCOPE][float] NULL,
	[Percentil90_DL_NC_SCOPE][float] NULL,
	[Percentil10_UL_NC_SCOPE][float] NULL,
	[Percentil90_UL_NC_SCOPE][float] NULL,
	[Percentil_PING_SCOPE][float] NULL,
	
	[mnc][int] NOT NULL,
	[meas_tech][varchar](17) NOT NULL,
	[report_qlik][varchar](255) NULL,
	[scope][varchar](255) NULL,
	[Scope_QLIK][varchar](50) NOT NULL,
	[MonthYear][nvarchar] (50) NOT NULL,
	[ReportWeek][nvarchar] (50) NOT NULL
  ) ON [PRIMARY]
END

if (select name from sys.tables where name='_Desviaciones_Data_Williams') is null
begin

  CREATE TABLE [dbo]._Desviaciones_Data_Williams(
	[entidad] [varchar](255) NULL,
	[Desviacion_DL_CE][float] NULL,
	[Desviacion_UL_CE][float] NULL,
	[Desviacion_DL_NC][float] NULL,
	[Desviacion_UL_NC][float] NULL,
	[Desviacion_DL_CE_SCOPE][float] NULL,
	[Desviacion_DL_NC_SCOPE][float] NULL,
	[Desviacion_UL_CE_SCOPE][float] NULL,
	[Desviacion_UL_NC_SCOPE][float] NULL,

	[mnc][int] NOT NULL,
	[meas_tech][varchar](17) NOT NULL,
	[report_qlik][varchar](255) NULL,
	[scope][varchar](255) NULL,
	[Scope_QLIK][varchar](50) NOT NULL,
	[MonthYear][nvarchar] (50) NOT NULL,
	[ReportWeek][nvarchar] (50) NOT NULL
  ) ON [PRIMARY]
END


set @filtro_report = (select distinct(report_qlik) from _Resultados_Percentiles)

---------------------------------------------------------------
	-- 1. Estructura de réplicas
--------------------------------------------------------------- 

print '1. Réplica de entidades' 	


drop table _Resultados_Percentiles_Entidades_Williams


select entities_bbdd as entidad,s.mnc,@filtro_report as report_qlik,s.test_type,s.meas_tech,s.percentil,Resultado_Percentil,
	   Case when scope like '%EXTRA%' then LEFT(scope,len(scope)-5) else scope end as scope,Scope_QLIK
into _Resultados_Percentiles_Entidades_Williams
from (
	select *,Case When Scope in ('MAIN CITIES','SMALLER CITIES') then 'BIG CITIES'
				   when Scope in ('ADD-ON CITIES','TOURISTIC AREA','ADD-ON CITIES EXTRA') then 'SMALLER CITIES QLIK'
				   when Scope in ('MAIN HIGHWAYS') and meas_tech in ('Road 4G_1','Road 4GOnly_1')then 'MAIN HIGHWAYS QLIK' ELSE '' end as Scope_QLIK
	from  (select * from [AGRIDS].[dbo].[vlcc_dashboard_info_scopes_NEW] where report = @filtro_report) s,
		(select 1 as mnc union select 7 as mnc union select 3 as mnc union select 4 as mnc) p,
		(select '3G' as Meas_Tech 
			union select '4G' union select '4G_CA_Only' union select '4GOnly'
			union select 'Road 4G' union select 'Road 4G_CA_Only' union select 'Road 4GOnly'
			union select 'Road 4G_1' union select 'Road 4G_CA_Only_1' union select 'Road 4GOnly_1') tech,
		(select 'CE_DL' as test_type,0.1 as Percentil union
			select 'CE_DL' as test_type,0.9 as Percentil union
			select 'CE_UL' as test_type,0.1 as Percentil union
			select 'CE_UL' as test_type,0.9 as Percentil union
			select 'NC_DL' as test_type,0.1 as Percentil union
			select 'NC_DL' as test_type,0.9 as Percentil union
			select 'NC_UL' as test_type,0.1 as Percentil union
			select 'NC_UL' as test_type,0.9 as Percentil union
			select 'PING' as test_type,0.5 as Percentil) t

	) s
	left join _Resultados_Percentiles r
		on (entidad=entities_bbdd or entidad=entities_dashboard) and s.mnc=r.mnc and s.test_type=r.test_type and s.Percentil=r.Percentil and s.Meas_Tech=r.Meas_Tech

print '1. Réplica de entidades' 	


drop table _Resultados_Desviaciones_Entidades_Williams


select entities_bbdd as entidad,s.mnc,@filtro_report as report_qlik,s.test_type,s.meas_tech,Resultado_desviacion,
	   Case when scope like '%EXTRA%' then LEFT(scope,len(scope)-5) else scope end as scope,Scope_QLIK
into _Resultados_Desviaciones_Entidades_Williams
from (
	select *,Case When Scope in ('MAIN CITIES','SMALLER CITIES') then 'BIG CITIES'
				   when Scope in ('ADD-ON CITIES','TOURISTIC AREA','ADD-ON CITIES EXTRA') then 'SMALLER CITIES QLIK'
				   when Scope in ('MAIN HIGHWAYS') and meas_tech in ('Road 4G_1','Road 4GOnly_1')then 'MAIN HIGHWAYS QLIK' ELSE '' end as Scope_QLIK
	from  (select * from [AGRIDS].[dbo].[vlcc_dashboard_info_scopes_NEW] where report = @filtro_report) s,
		(select 1 as mnc union select 7 as mnc union select 3 as mnc union select 4 as mnc) p,
		(select '3G' as Meas_Tech 
			union select '4G' union select '4G_CA_Only' union select '4GOnly'
			union select 'Road 4G' union select 'Road 4G_CA_Only' union select 'Road 4GOnly'
			union select 'Road 4G_1' union select 'Road 4G_CA_Only_1' union select 'Road 4GOnly_1') tech,
		(select 'CE_DL' as test_type union
			select 'CE_UL' as test_type union
			select 'NC_DL' as test_type union
			select 'NC_UL' as test_type) t

	) s
	left join _Resultados_STDV r
		on (entidad=entities_bbdd or entidad=entities_dashboard) and s.mnc=r.mnc and s.test_type=r.test_type and s.Meas_Tech=r.Meas_Tech



-- select * from _Resultados_Percentiles where  entidad = 'MADRID' AND mnc = 04 and meas_tech = '4G_CA_ONLY'


---------------------------------------------------------------
	-- 2. Estructura por Columnas
--------------------------------------------------------------- 

print '2. Estructura por Columnas Percentiles' 	

truncate table [_Percentiles_Data_Williams]

insert into _Percentiles_Data_Williams
select b.entidad,t_DL_CE_10.Percentil10_DL_CE,t_DL_CE_90.Percentil90_DL_CE,t_UL_CE_10.Percentil10_UL_CE,t_UL_CE_90.Percentil90_UL_CE,
	   t_DL_NC_10.Percentil10_DL_NC,t_DL_NC_90.Percentil90_DL_NC,t_UL_NC_10.Percentil10_UL_NC,t_UL_NC_90.Percentil90_UL_NC,t_PING_50.Percentil_PING,
	   t_SCOPE_CE_DL_10.Percentil10_DL_CE_SCOPE,t_SCOPE_CE_DL_90.Percentil90_DL_CE_SCOPE,t_SCOPE_CE_UL_10.Percentil10_UL_CE_SCOPE,t_SCOPE_CE_UL_90.Percentil90_UL_CE_SCOPE,
	   t_SCOPE_NC_DL_10.Percentil10_DL_NC_SCOPE,t_SCOPE_NC_DL_90.Percentil90_DL_NC_SCOPE,t_SCOPE_NC_UL_10.Percentil10_UL_NC_SCOPE,t_SCOPE_NC_UL_90.Percentil90_UL_NC_SCOPE,t_SCOPE_PING_50.Percentil_PING_SCOPE,
	   b.mnc,b.meas_tech,b.report_qlik,b.scope,b.Scope_QLIK,@monthyear as MonthYear,@ReportWeek as ReportWeek
--into _Percentiles_Data
from
(
select entidad,mnc,meas_tech,report_qlik,scope,Scope_QLIK
from _Resultados_Percentiles_Entidades_Williams
--where meas_tech = '4G_CA_ONLY' and mnc = 01 and scope = 'MAIN CITIES'
group by entidad,mnc,meas_tech,report_qlik,scope,Scope_QLIK
) b
left join
(
select entidad,mnc,meas_tech,report_qlik,scope,Scope_QLIK,Resultado_Percentil as 'Percentil10_DL_CE'
from _Resultados_Percentiles_Entidades_Williams
where Test_type = 'CE_DL'and percentil=0.1 
) t_DL_CE_10
on (t_DL_CE_10.mnc=b.mnc and t_DL_CE_10.entidad=b.entidad and t_DL_CE_10.meas_tech=b.meas_tech
	and t_DL_CE_10.report_qlik= b.report_qlik and t_DL_CE_10.scope= b.scope and t_DL_CE_10.scope_QLIK= b.scope_QLIK)
left join
(
select entidad,mnc,meas_tech,report_qlik,scope,Scope_QLIK,Resultado_Percentil as 'Percentil90_DL_CE'
from _Resultados_Percentiles_Entidades_Williams
where Test_type = 'CE_DL' and percentil=0.9 
) t_DL_CE_90
on (t_DL_CE_90.mnc=b.mnc and t_DL_CE_90.entidad=b.entidad and t_DL_CE_90.meas_tech=b.meas_tech
	and t_DL_CE_90.report_qlik= b.report_qlik and t_DL_CE_90.scope= b.scope and t_DL_CE_90.scope_QLIK= b.scope_QLIK)
left join
(
select entidad,mnc,meas_tech,report_qlik,scope,Scope_QLIK,Resultado_Percentil as 'Percentil10_UL_CE'
from _Resultados_Percentiles_Entidades_Williams
where Test_type = 'CE_UL' and percentil=0.1 
) t_UL_CE_10
on (t_UL_CE_10.mnc=b.mnc and t_UL_CE_10.entidad=b.entidad and t_UL_CE_10.meas_tech=b.meas_tech
	and t_UL_CE_10.report_qlik= b.report_qlik and t_UL_CE_10.scope= b.scope and t_UL_CE_10.scope_QLIK= b.scope_QLIK)
left join
(
select entidad,mnc,meas_tech,report_qlik,scope,Scope_QLIK,Resultado_Percentil as 'Percentil90_UL_CE'
from _Resultados_Percentiles_Entidades_Williams
where Test_type = 'CE_UL' and percentil=0.9 
) t_UL_CE_90
on (t_UL_CE_90.mnc=b.mnc and t_UL_CE_90.entidad=b.entidad and t_UL_CE_90.meas_tech=b.meas_tech
	and t_UL_CE_90.report_qlik= b.report_qlik and t_UL_CE_90.scope= b.scope and t_UL_CE_90.scope_QLIK= b.scope_QLIK)
left join
(
select entidad,mnc,meas_tech,report_qlik,scope,Scope_QLIK,Resultado_Percentil as 'Percentil10_DL_NC'
from _Resultados_Percentiles_Entidades_Williams
where Test_type = 'NC_DL' and percentil=0.1 
) t_DL_NC_10
on (t_DL_NC_10.mnc=b.mnc and t_DL_NC_10.entidad=b.entidad and t_DL_NC_10.meas_tech=b.meas_tech
	and t_DL_NC_10.report_qlik= b.report_qlik and t_DL_NC_10.scope= b.scope and t_DL_NC_10.scope_QLIK= b.scope_QLIK)
left join
(
select entidad,mnc,meas_tech,report_qlik,scope,Scope_QLIK,Resultado_Percentil as 'Percentil90_DL_NC'
from _Resultados_Percentiles_Entidades_Williams
where Test_type = 'NC_DL' and percentil=0.9 
) t_DL_NC_90
on (t_DL_NC_90.mnc=b.mnc and t_DL_NC_90.entidad=b.entidad and t_DL_NC_90.meas_tech=b.meas_tech
	and t_DL_NC_90.report_qlik= b.report_qlik and t_DL_NC_90.scope= b.scope and t_DL_NC_90.scope_QLIK= b.scope_QLIK)
left join
(
select entidad,mnc,meas_tech,report_qlik,scope,Scope_QLIK,Resultado_Percentil as 'Percentil10_UL_NC'
from _Resultados_Percentiles_Entidades_Williams
where Test_type = 'NC_UL' and percentil=0.1 
) t_UL_NC_10
on (t_UL_NC_10.mnc=b.mnc and t_UL_NC_10.entidad=b.entidad and t_UL_NC_10.meas_tech=b.meas_tech
	and t_UL_NC_10.report_qlik= b.report_qlik and t_UL_NC_10.scope= b.scope and t_UL_NC_10.scope_QLIK= b.scope_QLIK)
left join
(
select entidad,mnc,meas_tech,report_qlik,scope,Scope_QLIK,Resultado_Percentil as 'Percentil90_UL_NC'
from _Resultados_Percentiles_Entidades_Williams
where Test_type = 'NC_UL' and percentil=0.9 
) t_UL_NC_90
on (t_UL_NC_90.mnc=b.mnc and t_UL_NC_90.entidad=b.entidad and t_UL_NC_90.meas_tech=b.meas_tech
	and t_UL_NC_90.report_qlik= b.report_qlik and t_UL_NC_90.scope= b.scope and t_UL_NC_90.scope_QLIK= b.scope_QLIK)
left join
(
select entidad,mnc,meas_tech,report_qlik,scope,Scope_QLIK,Resultado_Percentil as 'Percentil_PING'
from _Resultados_Percentiles_Entidades_Williams
where Test_type = 'PING' and percentil=0.5 
) t_PING_50
on (t_PING_50.mnc=b.mnc and t_PING_50.entidad=b.entidad and t_PING_50.meas_tech=b.meas_tech
	and t_PING_50.report_qlik= b.report_qlik and t_PING_50.scope= b.scope and t_PING_50.scope_QLIK= b.scope_QLIK)

-- Añadimos percentiles por Scope --
left join
(
select entidad,mnc,meas_tech,report_qlik,Resultado_Percentil as 'Percentil10_DL_CE_SCOPE'
from _Resultados_Percentiles
where Test_type = 'CE_DL' and percentil=0.1 and entidad = ('ADD-ON CITIES WILLIAMS')
) t_SCOPE_CE_DL_10 
on (t_SCOPE_CE_DL_10.mnc=b.mnc and t_SCOPE_CE_DL_10.meas_tech=b.meas_tech and t_SCOPE_CE_DL_10.entidad=b.scope and t_SCOPE_CE_DL_10.report_qlik= b.report_qlik)
left join
(
select entidad,mnc,meas_tech,report_qlik,Resultado_Percentil as 'Percentil90_DL_CE_SCOPE'
from _Resultados_Percentiles
where Test_type = 'CE_DL' and percentil=0.9 and entidad = ('ADD-ON CITIES WILLIAMS')
) t_SCOPE_CE_DL_90
on (t_SCOPE_CE_DL_90.mnc=b.mnc and t_SCOPE_CE_DL_90.meas_tech=b.meas_tech and t_SCOPE_CE_DL_90.entidad=b.scope and t_SCOPE_CE_DL_90.report_qlik= b.report_qlik)
left join
(
select entidad,mnc,meas_tech,report_qlik,Resultado_Percentil as 'Percentil10_UL_CE_SCOPE'
from _Resultados_Percentiles
where Test_type = 'CE_UL' and percentil=0.1 and entidad = ('ADD-ON CITIES WILLIAMS')
) t_SCOPE_CE_UL_10
on (t_SCOPE_CE_UL_10.mnc=b.mnc and t_SCOPE_CE_UL_10.meas_tech=b.meas_tech and t_SCOPE_CE_UL_10.entidad=b.scope and t_SCOPE_CE_UL_10.report_qlik= b.report_qlik)
left join
(
select entidad,mnc,meas_tech,report_qlik,Resultado_Percentil as 'Percentil90_UL_CE_SCOPE'
from _Resultados_Percentiles
where Test_type = 'CE_UL' and percentil=0.9 and entidad = ('ADD-ON CITIES WILLIAMS')
) t_SCOPE_CE_UL_90
on (t_SCOPE_CE_UL_90.mnc=b.mnc and t_SCOPE_CE_UL_90.meas_tech=b.meas_tech and t_SCOPE_CE_UL_90.entidad=b.scope and t_SCOPE_CE_UL_90.report_qlik= b.report_qlik)
left join
(
select entidad,mnc,meas_tech,report_qlik,Resultado_Percentil as 'Percentil10_DL_NC_SCOPE'
from _Resultados_Percentiles
where Test_type = 'NC_DL' and percentil=0.1 and entidad = ('ADD-ON CITIES WILLIAMS')
) t_SCOPE_NC_DL_10
on (t_SCOPE_NC_DL_10.mnc=b.mnc and t_SCOPE_NC_DL_10.meas_tech=b.meas_tech and t_SCOPE_NC_DL_10.entidad=b.scope and t_SCOPE_NC_DL_10.report_qlik= b.report_qlik)
left join
(
select entidad,mnc,meas_tech,report_qlik,Resultado_Percentil as 'Percentil90_DL_NC_SCOPE'
from _Resultados_Percentiles
where Test_type = 'NC_DL' and percentil=0.9 and entidad = ('ADD-ON CITIES WILLIAMS')
) t_SCOPE_NC_DL_90
on (t_SCOPE_NC_DL_90.mnc=b.mnc and t_SCOPE_NC_DL_90.meas_tech=b.meas_tech and t_SCOPE_NC_DL_90.entidad=b.scope and t_SCOPE_NC_DL_90.report_qlik= b.report_qlik)
left join
(
select entidad,mnc,meas_tech,report_qlik,Resultado_Percentil as 'Percentil10_UL_NC_SCOPE'
from _Resultados_Percentiles
where Test_type = 'NC_UL' and percentil=0.1 and entidad = ('ADD-ON CITIES WILLIAMS')
) t_SCOPE_NC_UL_10
on (t_SCOPE_NC_UL_10.mnc=b.mnc and t_SCOPE_NC_UL_10.meas_tech=b.meas_tech and t_SCOPE_NC_UL_10.entidad=b.scope and t_SCOPE_NC_UL_10.report_qlik= b.report_qlik)
left join
(
select entidad,mnc,meas_tech,report_qlik,Resultado_Percentil as 'Percentil90_UL_NC_SCOPE'
from _Resultados_Percentiles
where Test_type = 'NC_UL' and percentil=0.9 and entidad = ('ADD-ON CITIES WILLIAMS')
) t_SCOPE_NC_UL_90
on (t_SCOPE_NC_UL_90.mnc=b.mnc and t_SCOPE_NC_UL_90.meas_tech=b.meas_tech and t_SCOPE_NC_UL_90.entidad=b.scope and t_SCOPE_NC_UL_90.report_qlik= b.report_qlik)
left join
(
select entidad,mnc,meas_tech,report_qlik,Resultado_Percentil as 'Percentil_PING_SCOPE'
from _Resultados_Percentiles
where Test_type = 'PING' and percentil=0.5 and entidad = ('ADD-ON CITIES WILLIAMS')
) t_SCOPE_PING_50
on (t_SCOPE_PING_50.mnc=b.mnc and t_SCOPE_PING_50.meas_tech=b.meas_tech and t_SCOPE_PING_50.entidad=b.scope and t_SCOPE_PING_50.report_qlik= b.report_qlik)



--select * from _Percentiles_Data where ENTIDAD = 'ADD-ON CITIES'

print '2. Estructura por Columnas Desviaciones' 	

truncate table [_Desviaciones_Data_Williams]

insert into _Desviaciones_Data_Williams
select b.entidad,t_DL_CE.Desviacion_DL_CE,t_UL_CE.Desviacion_UL_CE,t_DL_NC.Desviacion_DL_NC,t_UL_NC.Desviacion_UL_NC,
	   t_SCOPE_DL_CE.Desviacion_DL_CE_SCOPE,t_SCOPE_UL_CE.Desviacion_UL_CE_SCOPE,t_SCOPE_DL_NC.Desviacion_DL_NC_SCOPE,t_SCOPE_UL_NC.Desviacion_UL_NC_SCOPE,
	   b.mnc,b.meas_tech,b.report_qlik,b.scope,b.Scope_QLIK,@monthyear as MonthYear,@ReportWeek as ReportWeek
--into _Percentiles_Data
from
(
select entidad,mnc,meas_tech,report_qlik,scope,Scope_QLIK
from _Resultados_Percentiles_Entidades_Williams
--where meas_tech = '4G_CA_ONLY' and mnc = 01 and scope = 'MAIN CITIES'
group by entidad,mnc,meas_tech,report_qlik,scope,Scope_QLIK
) b
left join
(
select entidad,mnc,meas_tech,report_qlik,scope,Scope_QLIK,Resultado_desviacion as 'Desviacion_DL_CE'
from _Resultados_Desviaciones_Entidades_Williams
where Test_type = 'CE_DL'
) t_DL_CE
on (t_DL_CE.mnc=b.mnc and t_DL_CE.entidad=b.entidad and t_DL_CE.meas_tech=b.meas_tech
	and t_DL_CE.report_qlik= b.report_qlik and t_DL_CE.scope= b.scope and t_DL_CE.scope_QLIK= b.scope_QLIK)
left join
(
select entidad,mnc,meas_tech,report_qlik,scope,Scope_QLIK,Resultado_desviacion as 'Desviacion_UL_CE'
from _Resultados_Desviaciones_Entidades_Williams
where Test_type = 'CE_UL'
) t_UL_CE
on (t_UL_CE.mnc=b.mnc and t_UL_CE.entidad=b.entidad and t_UL_CE.meas_tech=b.meas_tech
	and t_UL_CE.report_qlik= b.report_qlik and t_UL_CE.scope= b.scope and t_UL_CE.scope_QLIK= b.scope_QLIK)
left join
(
select entidad,mnc,meas_tech,report_qlik,scope,Scope_QLIK,Resultado_desviacion as 'Desviacion_DL_NC'
from _Resultados_Desviaciones_Entidades_Williams
where Test_type = 'NC_DL'
) t_DL_NC
on (t_DL_NC.mnc=b.mnc and t_DL_NC.entidad=b.entidad and t_DL_NC.meas_tech=b.meas_tech
	and t_DL_NC.report_qlik= b.report_qlik and t_DL_NC.scope= b.scope and t_DL_NC.scope_QLIK= b.scope_QLIK)
left join
(
select entidad,mnc,meas_tech,report_qlik,scope,Scope_QLIK,Resultado_desviacion as 'Desviacion_UL_NC'
from _Resultados_Desviaciones_Entidades_Williams
where Test_type = 'NC_UL'
) t_UL_NC
on (t_UL_NC.mnc=b.mnc and t_UL_NC.entidad=b.entidad and t_UL_NC.meas_tech=b.meas_tech
	and t_UL_NC.report_qlik= b.report_qlik and t_UL_NC.scope= b.scope and t_UL_NC.scope_QLIK= b.scope_QLIK)

-- Añadimos percentiles por Scope --
left join
(
select entidad,mnc,meas_tech,report_qlik,Resultado_desviacion as 'Desviacion_DL_CE_SCOPE'
from _Resultados_STDV
where Test_type = 'CE_DL' and entidad = ('ADD-ON CITIES WILLIAMS')
) t_SCOPE_DL_CE 
on (t_SCOPE_DL_CE.mnc=b.mnc and t_SCOPE_DL_CE.meas_tech=b.meas_tech and t_SCOPE_DL_CE.entidad=b.scope and t_SCOPE_DL_CE.report_qlik= b.report_qlik)
left join
(
select entidad,mnc,meas_tech,report_qlik,Resultado_desviacion as 'Desviacion_UL_CE_SCOPE'
from _Resultados_STDV
where Test_type = 'CE_UL' and entidad = ('ADD-ON CITIES WILLIAMS')
) t_SCOPE_UL_CE 
on (t_SCOPE_UL_CE.mnc=b.mnc and t_SCOPE_UL_CE.meas_tech=b.meas_tech and t_SCOPE_UL_CE.entidad=b.scope and t_SCOPE_UL_CE.report_qlik= b.report_qlik)
left join
(
select entidad,mnc,meas_tech,report_qlik,Resultado_desviacion as 'Desviacion_DL_NC_SCOPE'
from _Resultados_STDV
where Test_type = 'NC_DL' and entidad = ('ADD-ON CITIES WILLIAMS')
) t_SCOPE_DL_NC
on (t_SCOPE_DL_NC.mnc=b.mnc and t_SCOPE_DL_NC.meas_tech=b.meas_tech and t_SCOPE_DL_NC.entidad=b.scope and t_SCOPE_DL_NC.report_qlik= b.report_qlik)
left join
(
select entidad,mnc,meas_tech,report_qlik,Resultado_desviacion as 'Desviacion_UL_NC_SCOPE'
from _Resultados_STDV
where Test_type = 'NC_UL' and entidad = ('ADD-ON CITIES WILLIAMS')
) t_SCOPE_UL_NC 
on (t_SCOPE_UL_NC.mnc=b.mnc and t_SCOPE_UL_NC.meas_tech=b.meas_tech and t_SCOPE_UL_NC.entidad=b.scope and t_SCOPE_UL_NC.report_qlik= b.report_qlik)
