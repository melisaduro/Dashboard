USE [AddedValue]
GO
/****** Object:  StoredProcedure [dbo].[plcc_voice_statistics_Columns_new_Williams]    Script Date: 21/03/2018 11:43:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


ALTER PROCEDURE [dbo].[plcc_voice_statistics_Columns_new_Williams]
  
     @monthyear as nvarchar(50)
    ,@ReportWeek as nvarchar(50)

AS

--declare @monthyear as nvarchar(50) = '201710'
--declare @ReportWeek as nvarchar(50) = 'W40'
 --Declaramos variables --

 declare @filtro_report as varchar(12)

----------------------------
truncate table _Percentiles_Voz
truncate table _Desviaciones_Voz

if (select name from sys.tables where name='_Percentiles_Voz_Williams') is null
begin
	CREATE TABLE [dbo].[_Percentiles_Voz_Williams](
		[entidad] [varchar](255) NULL,
		[Percentil95_CST_MOMT_AL] [float] NULL,
		[Percentil95_CST_MOMT_CO] [float] NULL,
		[Percentil5_MOS_OVERALL] [float] NULL,
		[Percentil5_MOS_NB] [float] NULL,
		[Median_MOS_WB] [float] NULL,
		[Percentil95_CST_MOMT_AL_SCOPE] [float] NULL,
		[Percentil95_CST_MOMT_CO_SCOPE] [float] NULL,
		[Percentil5_MOS_OVERALL_SCOPE] [float] NULL,
		[Percentil5_MOS_NB_SCOPE] [float] NULL,
		[Median_MOS_WB_SCOPE] [float] NULL,
		[mnc] [int] NOT NULL,
		[meas_tech] [varchar](17) NOT NULL,
		[report_qlik] [varchar](255) NULL,
		[scope] [varchar](255) NULL,
		[Scope_QLIK] [varchar](25) NOT NULL,
		[MonthYear] [nvarchar] (50) NOT NULL,
		[ReportWeek] [nvarchar] (50) NOT NULL
	) ON [PRIMARY]

end

if (select name from sys.tables where name='_Desviaciones_Voz_Williams') is null
begin
	CREATE TABLE [dbo].[_Desviaciones_Voz_Williams](
		[entidad] [varchar](255) NULL,
		[Desviacion_NB] [float] NULL,
		[Desviacion_OVERALL] [float] NULL,
		[Desviacion_NB_SCOPE] [float] NULL,
		[Desviacion_OVERALL_SCOPE] [float] NULL,
		[mnc] [int] NOT NULL,
		[meas_tech] [varchar](17) NOT NULL,
		[report_qlik] [varchar](255) NULL,
		[scope] [varchar](255) NULL,
		[Scope_QLIK] [varchar](25) NOT NULL,
		[MonthYear] [nvarchar] (50) NOT NULL,
		[ReportWeek] [nvarchar] (50) NOT NULL
	) ON [PRIMARY]

end

-- Inicializamos la vb con el tipo de reporte para el que hemos calculado los percentiles y las desviaciones --

set @filtro_report = (select distinct(report_qlik) from _Resultados_Percentiles)

--------------------------------------------------------------------------------------------


---------------------------------------------------------------
	-- 1. Estructura de réplicas
--------------------------------------------------------------- 

print '1. Réplica de entidades' 	

exec sp_lcc_dropifexists '_Resultados_Percentiles_Entidades_Williams'

select entities_bbdd as entidad,s.mnc,@filtro_report as report_qlik,s.test_type,s.meas_tech,s.percentil,Resultado_Percentil,
		Case when scope like '%EXTRA%' then LEFT(scope,len(scope)-5) else scope end as scope,Scope_QLIK
into _Resultados_Percentiles_Entidades_Williams
from (
	select *, Case When Scope in ('MAIN CITIES','SMALLER CITIES') then 'BIG CITIES'
				   when Scope in ('ADD-ON CITIES','ADD-ON CITIES EXTRA','TOURISTIC AREA') then 'SMALLER CITIES QLIK'
				   when Scope in ('MAIN HIGHWAYS') and meas_tech in ('Road 4G_1','Road 4GOnly_1')then 'MAIN HIGHWAYS QLIK' ELSE '' end as Scope_QLIK
	from (Select * from [AGRIDS].[dbo].[vlcc_dashboard_info_scopes_NEW] where report = @filtro_report) o,
		(select 1 as mnc union select 7 as mnc union select 3 as mnc union select 4 as mnc) p,   --Le asigna operador a todas las entidades del Scope. Y si una no está en un operador?????
		(select 'VOLTE ALL'  as Meas_Tech union select 'VOLTE RealVolte'
			) tech,
		(	select 'CST_MOMT_AL' as test_type,0.95 as Percentil union
			select 'CST_MOMT_CO' as test_type,0.95 as Percentil union
			select 'MOS_OVERALL' as test_type,0.05 as Percentil union
			select 'MOS_NB' as test_type,0.05 as Percentil union
			select 'MOS_WB' as test_type,0.5 as Percentil) t
		
	) s
	left join _Resultados_Percentiles r
		on (entidad=entities_bbdd or entidad=entities_dashboard) and s.mnc=r.mnc and s.test_type=r.test_type and s.Percentil=r.Percentil and s.Meas_Tech=r.Meas_Tech


set @filtro_report = (select distinct(report_qlik) from _Resultados_STDV)

exec sp_lcc_dropifexists '_Resultados_Desviaciones_Entidades_Williams'

select entities_bbdd as entidad,s.mnc,@filtro_report as report_qlik,s.test_type,s.meas_tech,Resultado_Desviacion,
		Case when scope like '%EXTRA%' then LEFT(scope,len(scope)-5) else scope end as scope,Scope_QLIK
into _Resultados_Desviaciones_Entidades_Williams
from (
	select *, Case When Scope in ('MAIN CITIES','SMALLER CITIES') then 'BIG CITIES'
				   when Scope in ('ADD-ON CITIES','ADD-ON CITIES EXTRA','TOURISTIC AREA') then 'SMALLER CITIES QLIK'
				   when Scope in ('MAIN HIGHWAYS') and meas_tech in ('Road 4G_1','Road 4GOnly_1')then 'MAIN HIGHWAYS QLIK' ELSE '' end as Scope_QLIK
	from (Select * from [AGRIDS].[dbo].[vlcc_dashboard_info_scopes_NEW] where report = @filtro_report) o,
		(select 1 as mnc union select 7 as mnc union select 3 as mnc union select 4 as mnc) p,   --Le asigna operador a todas las entidades del Scope. Y si una no está en un operador?????
		(select 'VOLTE ALL'  as Meas_Tech union select 'VOLTE RealVolte') tech,
		(	select 'MOS_NB' as test_type union
			select 'MOS_OVERALL' as test_type) t
		
	) s
	left join _Resultados_STDV r
		on (entidad=entities_bbdd or entidad=entities_dashboard) and s.mnc=r.mnc and s.test_type=r.test_type and s.Meas_Tech=r.Meas_Tech
	  

---------------------------------------------------------------
	-- 2. Estructura por Columnas --- PERCENTILES
--------------------------------------------------------------- 

print '2. Estructura por Columnas Percentiles' 	


truncate table [_Percentiles_Voz_Williams]


insert into _Percentiles_Voz_Williams
select b.entidad,
	t_CST_MOMT_AL.Percentil95_CST_MOMT_AL,
	t_CST_MOMT_CO.Percentil95_CST_MOMT_CO,
	t_MOS_OVERALL.Percentil5_MOS_OVERALL,
	t_MOS_NB.Percentil5_MOS_NB,
	t_MOS_WB.Median_MOS_WB,
	t_CST_MOMT_AL_SCOPE.Percentil95_CST_MOMT_AL_SCOPE,
	t_CST_MOMT_CO_SCOPE.Percentil95_CST_MOMT_CO_SCOPE,
	t_MOS_OVERALL_SCOPE.Percentil5_MOS_OVERALL_SCOPE,
	t_MOS_NB_SCOPE.Percentil5_MOS_NB_SCOPE,
	t_MOS_WB_SCOPE.Median_MOS_WB_SCOPE,
	b.mnc,
	b.meas_tech,
	b.report_qlik,
	b.scope,
	b.Scope_QLIK,
	@monthYear as MonthYear,
	@ReportWeek as ReportWeek

from
(
select entidad,mnc,meas_tech,report_qlik,scope,Scope_QLIK
from _Resultados_Percentiles_Entidades_Williams
group by entidad,mnc,meas_tech,report_qlik,scope,Scope_QLIK
)b
left join
(
select entidad,mnc,meas_tech,report_qlik,scope,Scope_QLIK,Resultado_Percentil as 'Percentil95_CST_MOMT_AL'
from _Resultados_Percentiles_Entidades_Williams
where Test_type = 'CST_MOMT_AL' and percentil=0.95 
) t_CST_MOMT_AL
on (t_CST_MOMT_AL.mnc=b.mnc and t_CST_MOMT_AL.entidad=b.entidad and t_CST_MOMT_AL.meas_tech=b.meas_tech
	and t_CST_MOMT_AL.report_qlik= b.report_qlik and t_CST_MOMT_AL.scope= b.scope and t_CST_MOMT_AL.scope_QLIK= b.scope_QLIK)
left join
(
select entidad,mnc,meas_tech,report_qlik,scope,Scope_QLIK,Resultado_Percentil as 'Percentil95_CST_MOMT_CO'
from _Resultados_Percentiles_Entidades_Williams
where Test_type = 'CST_MOMT_CO' and percentil=0.95 
) t_CST_MOMT_CO
on (t_CST_MOMT_CO.mnc=b.mnc and t_CST_MOMT_CO.entidad=b.entidad and t_CST_MOMT_CO.meas_tech=b.meas_tech
	and t_CST_MOMT_CO.report_qlik= b.report_qlik and t_CST_MOMT_CO.scope= b.scope and t_CST_MOMT_CO.scope_QLIK= b.scope_QLIK)
left join
(
select entidad,mnc,meas_tech,report_qlik,scope,Scope_QLIK,Resultado_Percentil as 'Percentil5_MOS_OVERALL'
from _Resultados_Percentiles_Entidades_Williams
where Test_type = 'MOS_OVERALL' and percentil=0.05
) t_MOS_OVERALL
on (t_MOS_OVERALL.mnc=b.mnc and t_MOS_OVERALL.entidad=b.entidad and t_MOS_OVERALL.meas_tech=b.meas_tech
	and t_MOS_OVERALL.report_qlik= b.report_qlik and t_MOS_OVERALL.scope= b.scope and t_MOS_OVERALL.scope_QLIK= b.scope_QLIK)
left join
(
select entidad,mnc,meas_tech,report_qlik,scope,Scope_QLIK,Resultado_Percentil as 'Percentil5_MOS_NB'
from _Resultados_Percentiles_Entidades_Williams
where Test_type = 'MOS_NB' and percentil=0.05 
) t_MOS_NB
on (t_MOS_NB.mnc=b.mnc and t_MOS_NB.entidad=b.entidad and t_MOS_NB.meas_tech=b.meas_tech
	and t_MOS_NB.report_qlik= b.report_qlik and t_MOS_NB.scope= b.scope and t_MOS_NB.scope_QLIK= b.scope_QLIK)
left join
(
select entidad,mnc,meas_tech,report_qlik,scope,Scope_QLIK,Resultado_Percentil as 'Median_MOS_WB'
from _Resultados_Percentiles_Entidades_Williams
where Test_type = 'MOS_WB' and percentil=0.5 
) t_MOS_WB
on (t_MOS_WB.mnc=b.mnc and t_MOS_WB.entidad=b.entidad and t_MOS_WB.meas_tech=b.meas_tech
	and t_MOS_WB.report_qlik= b.report_qlik and t_MOS_WB.scope= b.scope and t_MOS_WB.scope_QLIK= b.scope_QLIK)

-- Añadimos los percentiles por SCOPE --

left join 
(
select entidad,mnc,meas_tech,report_qlik,Resultado_Percentil as 'Percentil95_CST_MOMT_AL_SCOPE'
from _Resultados_Percentiles
where Test_type = 'CST_MOMT_AL' and percentil=0.95 AND entidad in ('ADD-ON CITIES WILLIAMS')
) t_CST_MOMT_AL_SCOPE
on (t_CST_MOMT_AL_SCOPE.mnc=b.mnc and t_CST_MOMT_AL_SCOPE.meas_tech=b.meas_tech and t_CST_MOMT_AL_SCOPE.entidad=b.scope and t_CST_MOMT_AL_SCOPE.report_qlik= b.report_qlik)
left join 
(
select entidad,mnc,meas_tech,report_qlik,Resultado_Percentil as 'Percentil95_CST_MOMT_CO_SCOPE'
from _Resultados_Percentiles
where Test_type = 'CST_MOMT_CO' and percentil=0.95 AND entidad in ('ADD-ON CITIES WILLIAMS')
) t_CST_MOMT_CO_SCOPE
on (t_CST_MOMT_CO_SCOPE.mnc=b.mnc and t_CST_MOMT_CO_SCOPE.meas_tech=b.meas_tech and t_CST_MOMT_CO_SCOPE.entidad=b.scope and t_CST_MOMT_CO_SCOPE.report_qlik= b.report_qlik)
left join 
(
select entidad,mnc,meas_tech,report_qlik,Resultado_Percentil as 'Percentil5_MOS_OVERALL_SCOPE'
from _Resultados_Percentiles
where Test_type = 'MOS_OVERALL' and percentil=0.05 AND entidad in ('ADD-ON CITIES WILLIAMS')
) t_MOS_OVERALL_SCOPE
on (t_MOS_OVERALL_SCOPE.mnc=b.mnc and t_MOS_OVERALL_SCOPE.meas_tech=b.meas_tech and t_MOS_OVERALL_SCOPE.entidad=b.scope and t_MOS_OVERALL_SCOPE.report_qlik= b.report_qlik)
left join 
(
select entidad,mnc,meas_tech,report_qlik,Resultado_Percentil as 'Percentil5_MOS_NB_SCOPE'
from _Resultados_Percentiles
where Test_type = 'MOS_NB' and percentil=0.05 AND entidad in ('ADD-ON CITIES WILLIAMS')
) t_MOS_NB_SCOPE
on (t_MOS_NB_SCOPE.mnc=b.mnc and t_MOS_NB_SCOPE.meas_tech=b.meas_tech and t_MOS_NB_SCOPE.entidad=b.scope and t_MOS_NB_SCOPE.report_qlik= b.report_qlik)
left join 
(
select entidad,mnc,meas_tech,report_qlik,Resultado_Percentil as 'Median_MOS_WB_SCOPE'
from _Resultados_Percentiles
where Test_type = 'MOS_WB' and percentil=0.5 AND entidad in ('ADD-ON CITIES WILLIAMS')
) t_MOS_WB_SCOPE
on (t_MOS_WB_SCOPE.mnc=b.mnc and t_MOS_WB_SCOPE.meas_tech=b.meas_tech and t_MOS_WB_SCOPE.entidad=b.scope and t_MOS_WB_SCOPE.report_qlik= b.report_qlik)


---------------------------------------------------------------
	-- DESVIACIONES TIPICAS
--------------------------------------------------------------- 

---------------------------------------------------------------
	-- 2. Estructura por Columnas -- DESVIACION TIPICA
--------------------------------------------------------------- 

print '2. Estructura por Columnas Desviaciones' 	

truncate table [_Desviaciones_Voz_Williams]


insert into _Desviaciones_Voz_Williams
select b.entidad,
	t_MOS_NB.Desviacion_MOS_NB,
	t_MOS_OVER.Desviacion_MOS_OVERALL,
	t_MOS_NB_SCOPE.Desviacion_MOS_NB_SCOPE,
	t_MOS_OVER_SCOPE.Desviacion_MOS_OVERALL_SCOPE,
	b.mnc,
	b.meas_tech,
	b.report_qlik,
	b.scope,
	b.Scope_QLIK,
	@monthyear as MonthYear,
	@ReportWeek as ReportWeek

from
(
select entidad,mnc,meas_tech,report_qlik,scope,Scope_QLIK
from _Resultados_Desviaciones_Entidades_Williams
group by entidad,mnc,meas_tech,report_qlik,scope,Scope_QLIK
)b
left join
(
select entidad,mnc,meas_tech,report_qlik,scope,Scope_QLIK,Resultado_desviacion as 'Desviacion_MOS_NB'
from _Resultados_Desviaciones_Entidades_Williams
where Test_type = 'MOS_NB'
) t_MOS_NB
on (t_MOS_NB.mnc=b.mnc and t_MOS_NB.entidad=b.entidad and t_MOS_NB.meas_tech=b.meas_tech
	 and t_MOS_NB.report_qlik= b.report_qlik and t_MOS_NB.scope= b.scope and t_MOS_NB.scope_QLIK= b.scope_QLIK)
left join
(
select entidad,mnc,meas_tech,report_qlik,scope,Scope_QLIK,Resultado_desviacion as 'Desviacion_MOS_OVERALL'
from _Resultados_Desviaciones_Entidades_Williams
where Test_type = 'MOS_OVERALL'
) t_MOS_OVER
on (t_MOS_OVER.mnc=b.mnc and t_MOS_OVER.entidad=b.entidad and t_MOS_OVER.meas_tech=b.meas_tech
	 and t_MOS_OVER.report_qlik= b.report_qlik and t_MOS_NB.scope= b.scope and t_MOS_NB.scope_QLIK= b.scope_QLIK)

-- Añadimos los percentiles por SCOPE --

left join 
(
select entidad,mnc,meas_tech,report_qlik,Resultado_desviacion as 'Desviacion_MOS_NB_SCOPE'
from _Resultados_STDV
where Test_type = 'MOS_NB' AND entidad in ('ADD-ON CITIES WILLIAMS')
) t_MOS_NB_SCOPE
on (t_MOS_NB_SCOPE.mnc=b.mnc and t_MOS_NB_SCOPE.meas_tech=b.meas_tech and t_MOS_NB_SCOPE.entidad=b.scope and t_MOS_NB_SCOPE.report_qlik= b.report_qlik)

left join 
(
select entidad,mnc,meas_tech,report_qlik,Resultado_desviacion as 'Desviacion_MOS_OVERALL_SCOPE'
from _Resultados_STDV
where Test_type = 'MOS_OVERALL' AND entidad in ('ADD-ON CITIES WILLIAMS')
) t_MOS_OVER_SCOPE
on (t_MOS_OVER_SCOPE.mnc=b.mnc and t_MOS_OVER_SCOPE.meas_tech=b.meas_tech and t_MOS_OVER_SCOPE.entidad=b.scope and t_MOS_OVER_SCOPE.report_qlik= b.report_qlik)




