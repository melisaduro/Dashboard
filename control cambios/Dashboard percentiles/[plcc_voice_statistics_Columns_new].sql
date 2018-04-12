USE [AddedValue]
GO
/****** Object:  StoredProcedure [dbo].[plcc_voice_statistics_Columns_new]    Script Date: 12/04/2018 10:23:35 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


ALTER PROCEDURE [dbo].[plcc_voice_statistics_Columns_new]
  
     @monthyear as nvarchar(50)
    ,@ReportWeek as nvarchar(50)

AS

--declare @monthyear as nvarchar(50) = '201801'
--declare @ReportWeek as nvarchar(50) = 'W5'
 --Declaramos variables --

 declare @filtro_report as varchar(12)

----------------------------
truncate table _Percentiles_Voz
truncate table _Desviaciones_Voz

if (select name from sys.tables where name='_Percentiles_Voz') is null
begin
	CREATE TABLE [dbo].[_Percentiles_Voz](
		[entidad] [varchar](255) NULL,
		[Percentil95_CST_MO_AL] [float] NULL,
		[Percentil95_CST_MT_AL] [float] NULL,
		[Percentil95_CST_MOMT_AL] [float] NULL,
		[Percentil95_CST_MO_CO] [float] NULL,
		[Percentil95_CST_MT_CO] [float] NULL,
		[Percentil95_CST_MOMT_CO] [float] NULL,
		[Percentil5_MOS_OVERALL] [float] NULL,
		[Percentil5_MOS_NB] [float] NULL,
		[Median_MOS_WB] [float] NULL,
		[Percentil95_CST_MO_AL_SCOPE] [float] NULL,
		[Percentil95_CST_MT_AL_SCOPE] [float] NULL,
		[Percentil95_CST_MOMT_AL_SCOPE] [float] NULL,
		[Percentil95_CST_MO_CO_SCOPE] [float] NULL,
		[Percentil95_CST_MT_CO_SCOPE] [float] NULL,
		[Percentil95_CST_MOMT_CO_SCOPE] [float] NULL,
		[Percentil5_MOS_OVERALL_SCOPE] [float] NULL,
		[Percentil5_MOS_NB_SCOPE] [float] NULL,
		[Median_MOS_WB_SCOPE] [float] NULL,
		[Percentil95_CST_MO_AL_SCOPE_QLIK] [float] NULL,
		[Percentil95_CST_MT_AL_SCOPE_QLIK] [float] NULL,
		[Percentil95_CST_MOMT_AL_SCOPE_QLIK] [float] NULL,
		[Percentil95_CST_MO_CO_SCOPE_QLIK] [float] NULL,
		[Percentil95_CST_MT_CO_SCOPE_QLIK] [float] NULL,
		[Percentil95_CST_MOMT_CO_SCOPE_QLIK] [float] NULL,
		[Percentil5_MOS_OVERALL_SCOPE_QLIK] [float] NULL,
		[Percentil5_MOS_NB_SCOPE_QLIK] [float] NULL,
		[Median_MOS_WB_SCOPE_QLIK] [float] NULL,
		[mnc] [int] NOT NULL,
		[meas_tech] [varchar](17) NOT NULL,
		[report_qlik] [varchar](255) NULL,
		[scope] [varchar](255) NULL,
		[Scope_QLIK] [varchar](25) NOT NULL,
		[MonthYear] [nvarchar] (50) NOT NULL,
		[ReportWeek] [nvarchar] (50) NOT NULL
	) ON [PRIMARY]

end

if (select name from sys.tables where name='_Desviaciones_Voz') is null
begin
	CREATE TABLE [dbo].[_Desviaciones_Voz](
		[entidad] [varchar](255) NULL,
		[Desviacion_NB] [float] NULL,
		[Desviacion_OVERALL] [float] NULL,
		[Desviacion_NB_SCOPE] [float] NULL,
		[Desviacion_OVERALL_SCOPE] [float] NULL,
		[Desviacion_NB_SCOPE_QLIK] [float] NULL,
		[Desviacion_OVERALL_SCOPE_QLIK] [float] NULL,
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

set @filtro_report = (select distinct(report_qlik) from TablaPercentilVoz)

--------------------------------------------------------------------------------------------


---------------------------------------------------------------
	-- 1. Estructura de réplicas
--------------------------------------------------------------- 

print '1. Réplica de entidades' 	

exec sp_lcc_dropifexists '_Resultados_Percentiles_Entidades'

select entities_bbdd as entidad,s.mnc,@filtro_report as report_qlik,s.test_type,s.meas_tech,s.percentil,Resultado_Percentil,
		Case when scope like '%EXTRA%' then LEFT(scope,len(scope)-5) else scope end as scope,Scope_QLIK
into _Resultados_Percentiles_Entidades
from (
	select *, Case When Scope in ('MAIN CITIES','SMALLER CITIES') then 'BIG CITIES'
				   when Scope in ('ADD-ON CITIES','ADD-ON CITIES EXTRA','TOURISTIC AREA') then 'SMALLER CITIES QLIK'
				   when Scope in ('MAIN HIGHWAYS') and meas_tech in ('Road 4G_1','Road 4GOnly_1','VOLTE ALL Road_1','VOLTE RealVolte Road_1')then 'MAIN HIGHWAYS QLIK' ELSE '' end as Scope_QLIK
	from (Select * from [AGRIDS].[dbo].[vlcc_dashboard_info_scopes_NEW] where report = @filtro_report) o,
		(select 1 as mnc union select 7 as mnc union select 3 as mnc union select 4 as mnc) p,   --Le asigna operador a todas las entidades del Scope. Y si una no está en un operador?????
		(select '3G' as Meas_Tech 
			union select '4G' union select '4G_CA_Only' union select '4GOnly'
			union select 'Road 4G' union select 'Road 4G_CA_Only' union select 'Road 4GOnly'
			union select 'Road 4G_1' union select 'Road 4G_CA_Only_1' union select 'Road 4GOnly_1'
			union select 'VOLTE ALL' union select 'VOLTE RealVolte' union select 'VOLTE ALL Road' 
			union select 'VOLTE RealVolte Road' union select 'VOLTE ALL Road_1' 
			union select 'VOLTE RealVolte Road_1') tech,
		(select 'CST_MO_AL' as test_type,0.95 as Percentil union
			select 'CST_MT_AL' as test_type,0.95 as Percentil union
			select 'CST_MOMT_AL' as test_type,0.95 as Percentil union
			select 'CST_MO_CO' as test_type,0.95 as Percentil union
			select 'CST_MT_CO' as test_type,0.95 as Percentil union
			select 'CST_MOMT_CO' as test_type,0.95 as Percentil union
			select 'MOS_OVERALL' as test_type,0.05 as Percentil union
			select 'MOS_NB' as test_type,0.05 as Percentil union
			select 'MOS_WB' as test_type,0.5 as Percentil) t
		
	) s
	left join TablaPercentilVoz r
		on (entidad=entities_bbdd or entidad=entities_dashboard) and s.mnc=r.mnc and s.test_type=r.test_type and s.Percentil=r.Percentil and s.Meas_Tech=r.Meas_Tech


set @filtro_report = (select distinct(report_qlik) from TablaSTDVVoz)

exec sp_lcc_dropifexists '_Resultados_Desviaciones_Entidades'

select entities_bbdd as entidad,s.mnc,@filtro_report as report_qlik,s.test_type,s.meas_tech,Resultado_Desviacion,
		Case when scope like '%EXTRA%' then LEFT(scope,len(scope)-5) else scope end as scope,Scope_QLIK
into _Resultados_Desviaciones_Entidades
from (
	select *, Case When Scope in ('MAIN CITIES','SMALLER CITIES') then 'BIG CITIES'
				   when Scope in ('ADD-ON CITIES','ADD-ON CITIES EXTRA','TOURISTIC AREA') then 'SMALLER CITIES QLIK'
				   when Scope in ('MAIN HIGHWAYS') and meas_tech in ('Road 4G_1','Road 4GOnly_1','VOLTE ALL Road_1','VOLTE RealVolte Road_1')then 'MAIN HIGHWAYS QLIK' ELSE '' end as Scope_QLIK
	from (Select * from [AGRIDS].[dbo].[vlcc_dashboard_info_scopes_NEW] where report = @filtro_report) o,
		(select 1 as mnc union select 7 as mnc union select 3 as mnc union select 4 as mnc) p,   --Le asigna operador a todas las entidades del Scope. Y si una no está en un operador?????
		(select '3G' as Meas_Tech 
			union select '4G' union select '4G_CA_Only' union select '4GOnly'
			union select 'Road 4G' union select 'Road 4G_CA_Only' union select 'Road 4GOnly'
			union select 'Road 4G_1' union select 'Road 4G_CA_Only_1' union select 'Road 4GOnly_1'
			union select 'VOLTE ALL' union select 'VOLTE RealVOLTE'
			union select 'VOLTE ALL Road' union select 'VOLTE RealVOLTE Road' union select 'VOLTE ALL Road_1' 
			union select 'VOLTE RealVolte Road_1') tech,
		(	select 'MOS_NB' as test_type union
			select 'MOS_OVERALL' as test_type) t
		
	) s
	left join TablaSTDVVoz r
		on (entidad=entities_bbdd or entidad=entities_dashboard) and s.mnc=r.mnc and s.test_type=r.test_type and s.Meas_Tech=r.Meas_Tech
	  

---------------------------------------------------------------
	-- 2. Estructura por Columnas --- PERCENTILES
--------------------------------------------------------------- 

print '2. Estructura por Columnas Percentiles' 	


truncate table [_Percentiles_Voz]


insert into _Percentiles_Voz
select b.entidad,
	t_CST_MO_AL.Percentil95_CST_MO_AL,
	t_CST_MT_AL.Percentil95_CST_MT_AL,
	t_CST_MOMT_AL.Percentil95_CST_MOMT_AL,
	t_CST_MO_CO.Percentil95_CST_MO_CO,
	t_CST_MT_CO.Percentil95_CST_MT_CO,
	t_CST_MOMT_CO.Percentil95_CST_MOMT_CO,
	t_MOS_OVERALL.Percentil5_MOS_OVERALL,
	t_MOS_NB.Percentil5_MOS_NB,
	t_MOS_WB.Median_MOS_WB,
	t_CST_MO_AL_SCOPE.Percentil95_CST_MO_AL_SCOPE,
	t_CST_MT_AL_SCOPE.Percentil95_CST_MT_AL_SCOPE,
	t_CST_MOMT_AL_SCOPE.Percentil95_CST_MOMT_AL_SCOPE,
	t_CST_MO_CO_SCOPE.Percentil95_CST_MO_CO_SCOPE,
	t_CST_MT_CO_SCOPE.Percentil95_CST_MT_CO_SCOPE,
	t_CST_MOMT_CO_SCOPE.Percentil95_CST_MOMT_CO_SCOPE,
	t_MOS_OVERALL_SCOPE.Percentil5_MOS_OVERALL_SCOPE,
	t_MOS_NB_SCOPE.Percentil5_MOS_NB_SCOPE,
	t_MOS_WB_SCOPE.Median_MOS_WB_SCOPE,
	t_CST_MO_AL_SCOPE_QLIK.Percentil95_CST_MO_AL_SCOPE_QLIK,
	t_CST_MT_AL_SCOPE_QLIK.Percentil95_CST_MT_AL_SCOPE_QLIK,
	t_CST_MOMT_AL_SCOPE_QLIK.Percentil95_CST_MOMT_AL_SCOPE_QLIK,
	t_CST_MO_CO_SCOPE_QLIK.Percentil95_CST_MO_CO_SCOPE_QLIK,
	t_CST_MT_CO_SCOPE_QLIK.Percentil95_CST_MT_CO_SCOPE_QLIK,
	t_CST_MOMT_CO_SCOPE_QLIK.Percentil95_CST_MOMT_CO_SCOPE_QLIK,
	t_MOS_OVERALL_SCOPE_QLIK.Percentil5_MOS_OVERALL_SCOPE_QLIK,
	t_MOS_NB_SCOPE_QLIK.Percentil5_MOS_NB_SCOPE_QLIK,
	t_MOS_WB_SCOPE_QLIK.Median_MOS_WB_SCOPE_QLIK,
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
from _Resultados_Percentiles_Entidades
group by entidad,mnc,meas_tech,report_qlik,scope,Scope_QLIK
)b
left join
(
select entidad,mnc,meas_tech,report_qlik,scope,Scope_QLIK,Resultado_Percentil as 'Percentil95_CST_MO_AL'
from _Resultados_Percentiles_Entidades
where Test_type = 'CST_MO_AL' and percentil=0.95 
) t_CST_MO_AL
on (t_CST_MO_AL.mnc=b.mnc and t_CST_MO_AL.entidad=b.entidad and t_CST_MO_AL.meas_tech=b.meas_tech
	 and t_CST_MO_AL.report_qlik= b.report_qlik and t_CST_MO_AL.scope= b.scope and t_CST_MO_AL.scope_QLIK= b.scope_QLIK)
left join
(
select entidad,mnc,meas_tech,report_qlik,scope,Scope_QLIK,Resultado_Percentil as 'Percentil95_CST_MT_AL'
from _Resultados_Percentiles_Entidades
where Test_type = 'CST_MT_AL' and percentil=0.95
) t_CST_MT_AL
on (t_CST_MT_AL.mnc=b.mnc and t_CST_MT_AL.entidad=b.entidad and t_CST_MT_AL.meas_tech=b.meas_tech
	and t_CST_MT_AL.report_qlik= b.report_qlik and t_CST_MT_AL.scope= b.scope and t_CST_MT_AL.scope_QLIK= b.scope_QLIK)
left join
(
select entidad,mnc,meas_tech,report_qlik,scope,Scope_QLIK,Resultado_Percentil as 'Percentil95_CST_MOMT_AL'
from _Resultados_Percentiles_Entidades
where Test_type = 'CST_MOMT_AL' and percentil=0.95 
) t_CST_MOMT_AL
on (t_CST_MOMT_AL.mnc=b.mnc and t_CST_MOMT_AL.entidad=b.entidad and t_CST_MOMT_AL.meas_tech=b.meas_tech
	and t_CST_MOMT_AL.report_qlik= b.report_qlik and t_CST_MOMT_AL.scope= b.scope and t_CST_MOMT_AL.scope_QLIK= b.scope_QLIK)
left join
(
select entidad,mnc,meas_tech,report_qlik,scope,Scope_QLIK,Resultado_Percentil as 'Percentil95_CST_MO_CO'
from _Resultados_Percentiles_Entidades
where Test_type = 'CST_MO_CO' and percentil=0.95
) t_CST_MO_CO
on (t_CST_MO_CO.mnc=b.mnc and t_CST_MO_CO.entidad=b.entidad and t_CST_MO_CO.meas_tech=b.meas_tech
	and t_CST_MO_CO.report_qlik= b.report_qlik and t_CST_MO_CO.scope= b.scope and t_CST_MO_CO.scope_QLIK= b.scope_QLIK)
left join
(
select entidad,mnc,meas_tech,report_qlik,scope,Scope_QLIK,Resultado_Percentil as 'Percentil95_CST_MT_CO'
from _Resultados_Percentiles_Entidades
where Test_type = 'CST_MT_CO' and percentil=0.95 
) t_CST_MT_CO
on (t_CST_MT_CO.mnc=b.mnc and t_CST_MT_CO.entidad=b.entidad and t_CST_MT_CO.meas_tech=b.meas_tech
	and t_CST_MT_CO.report_qlik= b.report_qlik and t_CST_MT_CO.scope= b.scope and t_CST_MT_CO.scope_QLIK= b.scope_QLIK)
left join
(
select entidad,mnc,meas_tech,report_qlik,scope,Scope_QLIK,Resultado_Percentil as 'Percentil95_CST_MOMT_CO'
from _Resultados_Percentiles_Entidades
where Test_type = 'CST_MOMT_CO' and percentil=0.95 
) t_CST_MOMT_CO
on (t_CST_MOMT_CO.mnc=b.mnc and t_CST_MOMT_CO.entidad=b.entidad and t_CST_MOMT_CO.meas_tech=b.meas_tech
	and t_CST_MOMT_CO.report_qlik= b.report_qlik and t_CST_MOMT_CO.scope= b.scope and t_CST_MOMT_CO.scope_QLIK= b.scope_QLIK)
left join
(
select entidad,mnc,meas_tech,report_qlik,scope,Scope_QLIK,Resultado_Percentil as 'Percentil5_MOS_OVERALL'
from _Resultados_Percentiles_Entidades
where Test_type = 'MOS_OVERALL' and percentil=0.05
) t_MOS_OVERALL
on (t_MOS_OVERALL.mnc=b.mnc and t_MOS_OVERALL.entidad=b.entidad and t_MOS_OVERALL.meas_tech=b.meas_tech
	and t_MOS_OVERALL.report_qlik= b.report_qlik and t_MOS_OVERALL.scope= b.scope and t_MOS_OVERALL.scope_QLIK= b.scope_QLIK)
left join
(
select entidad,mnc,meas_tech,report_qlik,scope,Scope_QLIK,Resultado_Percentil as 'Percentil5_MOS_NB'
from _Resultados_Percentiles_Entidades
where Test_type = 'MOS_NB' and percentil=0.05 
) t_MOS_NB
on (t_MOS_NB.mnc=b.mnc and t_MOS_NB.entidad=b.entidad and t_MOS_NB.meas_tech=b.meas_tech
	and t_MOS_NB.report_qlik= b.report_qlik and t_MOS_NB.scope= b.scope and t_MOS_NB.scope_QLIK= b.scope_QLIK)
left join
(
select entidad,mnc,meas_tech,report_qlik,scope,Scope_QLIK,Resultado_Percentil as 'Median_MOS_WB'
from _Resultados_Percentiles_Entidades
where Test_type = 'MOS_WB' and percentil=0.5 
) t_MOS_WB
on (t_MOS_WB.mnc=b.mnc and t_MOS_WB.entidad=b.entidad and t_MOS_WB.meas_tech=b.meas_tech
	and t_MOS_WB.report_qlik= b.report_qlik and t_MOS_WB.scope= b.scope and t_MOS_WB.scope_QLIK= b.scope_QLIK)

-- Añadimos los percentiles por SCOPE --

left join 
(
select entidad,mnc,meas_tech,report_qlik,Resultado_Percentil as 'Percentil95_CST_MO_AL_SCOPE'
from TablaPercentilVoz
where Test_type = 'CST_MO_AL' and percentil=0.95 AND entidad in ('MAIN CITIES','SMALLER CITIES','TOURISTIC AREA','ADD-ON CITIES','RAILWAYS','MAIN HIGHWAYS','PLACES OF CONCENTRATION')
) t_CST_MO_AL_SCOPE
on (t_CST_MO_AL_SCOPE.mnc=b.mnc and t_CST_MO_AL_SCOPE.meas_tech=b.meas_tech and t_CST_MO_AL_SCOPE.entidad=b.scope and t_CST_MO_AL_SCOPE.report_qlik= b.report_qlik)

left join 
(
select entidad,mnc,meas_tech,report_qlik,Resultado_Percentil as 'Percentil95_CST_MT_AL_SCOPE'
from TablaPercentilVoz
where Test_type = 'CST_MT_AL' and percentil=0.95 AND entidad in ('MAIN CITIES','SMALLER CITIES','TOURISTIC AREA','ADD-ON CITIES','RAILWAYS','MAIN HIGHWAYS','PLACES OF CONCENTRATION')
) t_CST_MT_AL_SCOPE
on (t_CST_MT_AL_SCOPE.mnc=b.mnc and t_CST_MT_AL_SCOPE.meas_tech=b.meas_tech and t_CST_MT_AL_SCOPE.entidad=b.scope and t_CST_MT_AL_SCOPE.report_qlik= b.report_qlik)
left join 
(
select entidad,mnc,meas_tech,report_qlik,Resultado_Percentil as 'Percentil95_CST_MOMT_AL_SCOPE'
from TablaPercentilVoz
where Test_type = 'CST_MOMT_AL' and percentil=0.95 AND entidad in ('MAIN CITIES','SMALLER CITIES','TOURISTIC AREA','ADD-ON CITIES','RAILWAYS','MAIN HIGHWAYS','PLACES OF CONCENTRATION')
) t_CST_MOMT_AL_SCOPE
on (t_CST_MOMT_AL_SCOPE.mnc=b.mnc and t_CST_MOMT_AL_SCOPE.meas_tech=b.meas_tech and t_CST_MOMT_AL_SCOPE.entidad=b.scope and t_CST_MOMT_AL_SCOPE.report_qlik= b.report_qlik)
left join 
(
select entidad,mnc,meas_tech,report_qlik,Resultado_Percentil as 'Percentil95_CST_MO_CO_SCOPE'
from TablaPercentilVoz
where Test_type = 'CST_MO_CO' and percentil=0.95 AND entidad in ('MAIN CITIES','SMALLER CITIES','TOURISTIC AREA','ADD-ON CITIES','RAILWAYS','MAIN HIGHWAYS','PLACES OF CONCENTRATION')
) t_CST_MO_CO_SCOPE
on (t_CST_MO_CO_SCOPE.mnc=b.mnc and t_CST_MO_CO_SCOPE.meas_tech=b.meas_tech and t_CST_MO_CO_SCOPE.entidad=b.scope and t_CST_MO_CO_SCOPE.report_qlik= b.report_qlik)
left join 
(
select entidad,mnc,meas_tech,report_qlik,Resultado_Percentil as 'Percentil95_CST_MT_CO_SCOPE'
from TablaPercentilVoz
where Test_type = 'CST_MT_CO' and percentil=0.95 AND entidad in ('MAIN CITIES','SMALLER CITIES','TOURISTIC AREA','ADD-ON CITIES','RAILWAYS','MAIN HIGHWAYS','PLACES OF CONCENTRATION')
) t_CST_MT_CO_SCOPE
on (t_CST_MT_CO_SCOPE.mnc=b.mnc and t_CST_MT_CO_SCOPE.meas_tech=b.meas_tech and t_CST_MT_CO_SCOPE.entidad=b.scope and t_CST_MT_CO_SCOPE.report_qlik= b.report_qlik)
left join 
(
select entidad,mnc,meas_tech,report_qlik,Resultado_Percentil as 'Percentil95_CST_MOMT_CO_SCOPE'
from TablaPercentilVoz
where Test_type = 'CST_MOMT_CO' and percentil=0.95 AND entidad in ('MAIN CITIES','SMALLER CITIES','TOURISTIC AREA','ADD-ON CITIES','RAILWAYS','MAIN HIGHWAYS','PLACES OF CONCENTRATION')
) t_CST_MOMT_CO_SCOPE
on (t_CST_MOMT_CO_SCOPE.mnc=b.mnc and t_CST_MOMT_CO_SCOPE.meas_tech=b.meas_tech and t_CST_MOMT_CO_SCOPE.entidad=b.scope and t_CST_MOMT_CO_SCOPE.report_qlik= b.report_qlik)
left join 
(
select entidad,mnc,meas_tech,report_qlik,Resultado_Percentil as 'Percentil5_MOS_OVERALL_SCOPE'
from TablaPercentilVoz
where Test_type = 'MOS_OVERALL' and percentil=0.05 AND entidad in ('MAIN CITIES','SMALLER CITIES','TOURISTIC AREA','ADD-ON CITIES','RAILWAYS','MAIN HIGHWAYS','PLACES OF CONCENTRATION')
) t_MOS_OVERALL_SCOPE
on (t_MOS_OVERALL_SCOPE.mnc=b.mnc and t_MOS_OVERALL_SCOPE.meas_tech=b.meas_tech and t_MOS_OVERALL_SCOPE.entidad=b.scope and t_MOS_OVERALL_SCOPE.report_qlik= b.report_qlik)
left join 
(
select entidad,mnc,meas_tech,report_qlik,Resultado_Percentil as 'Percentil5_MOS_NB_SCOPE'
from TablaPercentilVoz
where Test_type = 'MOS_NB' and percentil=0.05 AND entidad in ('MAIN CITIES','SMALLER CITIES','TOURISTIC AREA','ADD-ON CITIES','RAILWAYS','MAIN HIGHWAYS','PLACES OF CONCENTRATION')
) t_MOS_NB_SCOPE
on (t_MOS_NB_SCOPE.mnc=b.mnc and t_MOS_NB_SCOPE.meas_tech=b.meas_tech and t_MOS_NB_SCOPE.entidad=b.scope and t_MOS_NB_SCOPE.report_qlik= b.report_qlik)
left join 
(
select entidad,mnc,meas_tech,report_qlik,Resultado_Percentil as 'Median_MOS_WB_SCOPE'
from TablaPercentilVoz
where Test_type = 'MOS_WB' and percentil=0.5 AND entidad in ('MAIN CITIES','SMALLER CITIES','TOURISTIC AREA','ADD-ON CITIES','RAILWAYS','MAIN HIGHWAYS','PLACES OF CONCENTRATION')
) t_MOS_WB_SCOPE
on (t_MOS_WB_SCOPE.mnc=b.mnc and t_MOS_WB_SCOPE.meas_tech=b.meas_tech and t_MOS_WB_SCOPE.entidad=b.scope and t_MOS_WB_SCOPE.report_qlik= b.report_qlik)



-- Añadimos los percentiles por SCOPE QLIK--
left join 
(
select entidad,mnc,meas_tech,report_qlik,Resultado_Percentil as 'Percentil95_CST_MO_AL_SCOPE_QLIK'
from TablaPercentilVoz
where Test_type = 'CST_MO_AL' and percentil=0.95 AND entidad in ('BIG CITIES','SMALLER CITIES QLIK','MAIN HIGHWAYS QLIK')
) t_CST_MO_AL_SCOPE_QLIK
on (t_CST_MO_AL_SCOPE_QLIK.mnc=b.mnc and t_CST_MO_AL_SCOPE_QLIK.meas_tech=b.meas_tech and t_CST_MO_AL_SCOPE_QLIK.entidad=b.Scope_QLIK and t_CST_MO_AL_SCOPE_QLIK.report_qlik= b.report_qlik)
left join 
(
select entidad,mnc,meas_tech,report_qlik,Resultado_Percentil as 'Percentil95_CST_MT_AL_SCOPE_QLIK'
from TablaPercentilVoz
where Test_type = 'CST_MT_AL' and percentil=0.95 AND entidad in ('BIG CITIES','SMALLER CITIES QLIK','MAIN HIGHWAYS QLIK')
) t_CST_MT_AL_SCOPE_QLIK
on (t_CST_MT_AL_SCOPE_QLIK.mnc=b.mnc and t_CST_MT_AL_SCOPE_QLIK.meas_tech=b.meas_tech and t_CST_MT_AL_SCOPE_QLIK.entidad=b.Scope_QLIK and t_CST_MT_AL_SCOPE_QLIK.report_qlik= b.report_qlik)
left join 
(
select entidad,mnc,meas_tech,report_qlik,Resultado_Percentil as 'Percentil95_CST_MOMT_AL_SCOPE_QLIK'
from TablaPercentilVoz
where Test_type = 'CST_MOMT_AL' and percentil=0.95 AND entidad in ('BIG CITIES','SMALLER CITIES QLIK','MAIN HIGHWAYS QLIK')
) t_CST_MOMT_AL_SCOPE_QLIK
on (t_CST_MOMT_AL_SCOPE_QLIK.mnc=b.mnc and t_CST_MOMT_AL_SCOPE_QLIK.meas_tech=b.meas_tech and t_CST_MOMT_AL_SCOPE_QLIK.entidad=b.Scope_QLIK and t_CST_MOMT_AL_SCOPE_QLIK.report_qlik= b.report_qlik)
left join 
(
select entidad,mnc,meas_tech,report_qlik,Resultado_Percentil as 'Percentil95_CST_MO_CO_SCOPE_QLIK'
from TablaPercentilVoz
where Test_type = 'CST_MO_CO' and percentil=0.95 AND entidad in ('BIG CITIES','SMALLER CITIES QLIK','MAIN HIGHWAYS QLIK')
) t_CST_MO_CO_SCOPE_QLIK
on (t_CST_MO_CO_SCOPE_QLIK.mnc=b.mnc and t_CST_MO_CO_SCOPE_QLIK.meas_tech=b.meas_tech and t_CST_MO_CO_SCOPE_QLIK.entidad=b.Scope_QLIK and t_CST_MO_CO_SCOPE_QLIK.report_qlik= b.report_qlik)
left join 
(
select entidad,mnc,meas_tech,report_qlik,Resultado_Percentil as 'Percentil95_CST_MT_CO_SCOPE_QLIK'
from TablaPercentilVoz
where Test_type = 'CST_MT_CO' and percentil=0.95 AND entidad in ('BIG CITIES','SMALLER CITIES QLIK','MAIN HIGHWAYS QLIK')
) t_CST_MT_CO_SCOPE_QLIK
on (t_CST_MT_CO_SCOPE_QLIK.mnc=b.mnc and t_CST_MT_CO_SCOPE_QLIK.meas_tech=b.meas_tech and t_CST_MT_CO_SCOPE_QLIK.entidad=b.Scope_QLIK and t_CST_MT_CO_SCOPE_QLIK.report_qlik= b.report_qlik)
left join 
(
select entidad,mnc,meas_tech,report_qlik,Resultado_Percentil as 'Percentil95_CST_MOMT_CO_SCOPE_QLIK'
from TablaPercentilVoz
where Test_type = 'CST_MOMT_CO' and percentil=0.95 AND entidad in ('BIG CITIES','SMALLER CITIES QLIK','MAIN HIGHWAYS QLIK')
) t_CST_MOMT_CO_SCOPE_QLIK
on (t_CST_MOMT_CO_SCOPE_QLIK.mnc=b.mnc and t_CST_MOMT_CO_SCOPE_QLIK.meas_tech=b.meas_tech and t_CST_MOMT_CO_SCOPE_QLIK.entidad=b.Scope_QLIK and t_CST_MOMT_CO_SCOPE_QLIK.report_qlik= b.report_qlik)
left join 
(
select entidad,mnc,meas_tech,report_qlik,Resultado_Percentil as 'Percentil5_MOS_OVERALL_SCOPE_QLIK'
from TablaPercentilVoz
where Test_type = 'MOS_OVERALL' and percentil=0.05 AND entidad in ('BIG CITIES','SMALLER CITIES QLIK','MAIN HIGHWAYS QLIK')
) t_MOS_OVERALL_SCOPE_QLIK
on (t_MOS_OVERALL_SCOPE_QLIK.mnc=b.mnc and t_MOS_OVERALL_SCOPE_QLIK.meas_tech=b.meas_tech and t_MOS_OVERALL_SCOPE_QLIK.entidad=b.Scope_QLIK and t_MOS_OVERALL_SCOPE_QLIK.report_qlik= b.report_qlik)
left join 
(
select entidad,mnc,meas_tech,report_qlik,Resultado_Percentil as 'Percentil5_MOS_NB_SCOPE_QLIK'
from TablaPercentilVoz
where Test_type = 'MOS_NB' and percentil=0.05 AND entidad in ('BIG CITIES','SMALLER CITIES QLIK','MAIN HIGHWAYS QLIK')
) t_MOS_NB_SCOPE_QLIK
on (t_MOS_NB_SCOPE_QLIK.mnc=b.mnc and t_MOS_NB_SCOPE_QLIK.meas_tech=b.meas_tech and t_MOS_NB_SCOPE_QLIK.entidad=b.Scope_QLIK and t_MOS_NB_SCOPE_QLIK.report_qlik= b.report_qlik)
left join 
(
select entidad,mnc,meas_tech,report_qlik,Resultado_Percentil as 'Median_MOS_WB_SCOPE_QLIK'
from TablaPercentilVoz
where Test_type = 'MOS_WB' and percentil=0.5 AND entidad in ('BIG CITIES','SMALLER CITIES QLIK','MAIN HIGHWAYS QLIK')
) t_MOS_WB_SCOPE_QLIK
on (t_MOS_WB_SCOPE_QLIK.mnc=b.mnc and t_MOS_WB_SCOPE_QLIK.meas_tech=b.meas_tech and t_MOS_WB_SCOPE_QLIK.entidad=b.Scope_QLIK and t_MOS_WB_SCOPE_QLIK.report_qlik= b.report_qlik)



---------------------------------------------------------------
	-- DESVIACIONES TIPICAS
--------------------------------------------------------------- 

---------------------------------------------------------------
	-- 2. Estructura por Columnas -- DESVIACION TIPICA
--------------------------------------------------------------- 

print '2. Estructura por Columnas Desviaciones' 	


insert into _Desviaciones_Voz
select b.entidad,
	t_MOS_NB.Desviacion_MOS_NB,
	t_MOS_OVER.Desviacion_MOS_OVERALL,
	t_MOS_NB_SCOPE.Desviacion_MOS_NB_SCOPE,
	t_MOS_OVER_SCOPE.Desviacion_MOS_OVERALL_SCOPE,
	t_MOS_NB_SCOPE_QLIK.Desviacion_MOS_NB_SCOPE_QLIK,
	t_MOS_OVER_SCOPE_QLIK.Desviacion_MOS_OVERALL_SCOPE_QLIK,
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
from _Resultados_Desviaciones_Entidades
group by entidad,mnc,meas_tech,report_qlik,scope,Scope_QLIK
)b
left join
(
select entidad,mnc,meas_tech,report_qlik,scope,Scope_QLIK,Resultado_desviacion as 'Desviacion_MOS_NB'
from _Resultados_Desviaciones_Entidades
where Test_type = 'MOS_NB'
) t_MOS_NB
on (t_MOS_NB.mnc=b.mnc and t_MOS_NB.entidad=b.entidad and t_MOS_NB.meas_tech=b.meas_tech
	 and t_MOS_NB.report_qlik= b.report_qlik and t_MOS_NB.scope= b.scope and t_MOS_NB.scope_QLIK= b.scope_QLIK)
left join
(
select entidad,mnc,meas_tech,report_qlik,scope,Scope_QLIK,Resultado_desviacion as 'Desviacion_MOS_OVERALL'
from _Resultados_Desviaciones_Entidades
where Test_type = 'MOS_OVERALL'
) t_MOS_OVER
on (t_MOS_OVER.mnc=b.mnc and t_MOS_OVER.entidad=b.entidad and t_MOS_OVER.meas_tech=b.meas_tech
	 and t_MOS_OVER.report_qlik= b.report_qlik and t_MOS_NB.scope= b.scope and t_MOS_NB.scope_QLIK= b.scope_QLIK)

-- Añadimos los percentiles por SCOPE --

left join 
(
select entidad,mnc,meas_tech,report_qlik,Resultado_desviacion as 'Desviacion_MOS_NB_SCOPE'
from TablaSTDVVoz
where Test_type = 'MOS_NB' AND entidad in ('MAIN CITIES','SMALLER CITIES','TOURISTIC AREA','ADD-ON CITIES','RAILWAYS','MAIN HIGHWAYS','PLACES OF CONCENTRATION')
) t_MOS_NB_SCOPE
on (t_MOS_NB_SCOPE.mnc=b.mnc and t_MOS_NB_SCOPE.meas_tech=b.meas_tech and t_MOS_NB_SCOPE.entidad=b.scope and t_MOS_NB_SCOPE.report_qlik= b.report_qlik)

left join 
(
select entidad,mnc,meas_tech,report_qlik,Resultado_desviacion as 'Desviacion_MOS_OVERALL_SCOPE'
from TablaSTDVVoz
where Test_type = 'MOS_OVERALL' AND entidad in ('MAIN CITIES','SMALLER CITIES','TOURISTIC AREA','ADD-ON CITIES','RAILWAYS','MAIN HIGHWAYS','PLACES OF CONCENTRATION')
) t_MOS_OVER_SCOPE
on (t_MOS_OVER_SCOPE.mnc=b.mnc and t_MOS_OVER_SCOPE.meas_tech=b.meas_tech and t_MOS_OVER_SCOPE.entidad=b.scope and t_MOS_OVER_SCOPE.report_qlik= b.report_qlik)

-- Añadimos los percentiles por SCOPE QLIK--
left join 
(
select entidad,mnc,meas_tech,report_qlik,Resultado_desviacion as 'Desviacion_MOS_NB_SCOPE_QLIK'
from TablaSTDVVoz
where Test_type = 'MOS_NB' AND entidad in ('BIG CITIES','SMALLER CITIES QLIK','MAIN HIGHWAYS QLIK')
) t_MOS_NB_SCOPE_QLIK
on (t_MOS_NB_SCOPE_QLIK.mnc=b.mnc and t_MOS_NB_SCOPE_QLIK.meas_tech=b.meas_tech and t_MOS_NB_SCOPE_QLIK.entidad=b.Scope_QLIK and t_MOS_NB_SCOPE_QLIK.report_qlik= b.report_qlik)
left join 
(
select entidad,mnc,meas_tech,report_qlik,Resultado_desviacion as 'Desviacion_MOS_OVERALL_SCOPE_QLIK'
from TablaSTDVVoz
where Test_type = 'MOS_OVERALL' AND entidad in ('BIG CITIES','SMALLER CITIES QLIK','MAIN HIGHWAYS QLIK')
) t_MOS_OVER_SCOPE_QLIK
on (t_MOS_OVER_SCOPE_QLIK.mnc=b.mnc and t_MOS_OVER_SCOPE_QLIK.meas_tech=b.meas_tech and t_MOS_OVER_SCOPE_QLIK.entidad=b.Scope_QLIK and t_MOS_OVER_SCOPE_QLIK.report_qlik= b.report_qlik)



--select * from _Percentiles_Voz