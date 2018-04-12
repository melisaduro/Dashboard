USE [AddedValue]
GO
/****** Object:  StoredProcedure [dbo].[plcc_voice_statistics_Williams]    Script Date: 21/03/2018 12:01:25 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



ALTER PROCEDURE [dbo].[plcc_voice_statistics_Williams](
	@last_measurement as varchar(256)
)
AS

-----------------------------
----- Testing Variables -----
-----------------------------
--declare @last_measurement as varchar(256)='last_measurement_vdf' --= 'last_measurement_osp'
-----------------------------

declare @filtroReport as varchar(256) 


if charindex('osp',@last_measurement)>0
begin
	set @filtroReport='MUN'
end
else
begin
	set @filtroReport='VDF'
end



truncate table _Resultados_Percentiles
truncate table _Resultados_STDV


--Definir los rangos de Voz

declare @step_CST_MO_AL as float=0.5
declare @range_CST_MO_AL as int=41
declare @step_CST_MT_AL as float=0.5 
declare @range_CST_MT_AL as int=41
declare @step_CST_MOMT_AL as float=0.5
declare @range_CST_MOMT_AL int=41
declare @step_CST_MO_CO as float=0.5
declare @range_CST_MO_CO as int=41
declare @step_CST_MT_CO as float=0.5
declare @range_CST_MT_CO as int=41
declare @step_CST_MOMT_CO as float=0.5
declare @range_CST_MOMT_CO as int=41
declare @step_MOS_OVERALL as float=0.5
declare @range_MOS_OVERALL as int=8
declare @step_MOS_NB as float=0.5
declare @range_MOS_NB as int=8
declare @step_MOS_WB as float=0.5
declare @range_MOS_WB as int=8



--declare @step_CST_MO_AL as float
--declare @range_CST_MO_AL as int
--declare @step_CST_MT_AL as float
--declare @range_CST_MT_AL as int
--declare @step_CST_MOMT_AL as float
--declare @range_CST_MOMT_AL as int
--declare @step_CST_MO_CO as float
--declare @range_CST_MO_CO as int
--declare @step_CST_MT_CO as float
--declare @range_CST_MT_CO as int
--declare @step_CST_MOMT_CO as float
--declare @range_CST_MOMT_CO as int
--declare @range_MOS_OVERALL as float
--declare @step_MOS_OVERALL as int
--declare @range_MOS_WB as float
--declare @step_MOS_WB as int
--declare @range_MOS_NB as float
--declare @step_MOS_NB as int

if (select name from sys.tables where name='_Percentiles_Voice_Williams') is null
begin
  CREATE TABLE [dbo].[_Percentiles_Voice_Williams](
	[Entidad] [varchar](8000) NULL,
	[mnc] [varchar](2) NULL,
	[Date_Reporting] [varchar](255) NULL,
	[Report_Type] [varchar](255) NULL,
	[Test_type] [varchar](255) NULL,
	[Meas_Tech] [varchar](255) NULL,
	[1_N] [int] NULL,
	[2_N] [int] NULL,
	[3_N] [int] NULL,
	[4_N] [int] NULL,
	[5_N] [int] NULL,
	[6_N] [int] NULL,
	[7_N] [int] NULL,
	[8_N] [int] NULL,
	[9_N] [int] NULL,
	[10_N] [int] NULL,
	[11_N] [int] NULL,
	[12_N] [int] NULL,
	[13_N] [int] NULL,
	[14_N] [int] NULL,
	[15_N] [int] NULL,
	[16_N] [int] NULL,
	[17_N] [int] NULL,
	[18_N] [int] NULL,
	[19_N] [int] NULL,
	[20_N] [int] NULL,
	[21_N] [int] NULL,
	[22_N] [int] NULL,
	[23_N] [int] NULL,
	[24_N] [int] NULL,
	[25_N] [int] NULL,
	[26_N] [int] NULL,
	[27_N] [int] NULL,
	[28_N] [int] NULL,
	[29_N] [int] NULL,
	[30_N] [int] NULL,
	[31_N] [int] NULL,
	[32_N] [int] NULL,
	[33_N] [int] NULL,
	[34_N] [int] NULL,
	[35_N] [int] NULL,
	[36_N] [int] NULL,
	[37_N] [int] NULL,
	[38_N] [int] NULL,
	[39_N] [int] NULL,
	[40_N] [int] NULL,
	[41_N] [int] NULL,
	[42_N] [int] NULL,
	[43_N] [int] NULL,
	[44_N] [int] NULL,
	[45_N] [int] NULL,
	[46_N] [int] NULL,
	[47_N] [int] NULL,
	[48_N] [int] NULL,
	[49_N] [int] NULL,
	[50_N] [int] NULL,
	[51_N] [int] NULL,
	[52_N] [int] NULL,
	[53_N] [int] NULL,
	[54_N] [int] NULL,
	[55_N] [int] NULL,
	[56_N] [int] NULL,
	[57_N] [int] NULL,
	[58_N] [int] NULL,
	[59_N] [int] NULL,
	[60_N] [int] NULL,
	[61_N] [int] NULL,
	[62_N] [int] NULL,
	[63_N] [int] NULL,
	[64_N] [int] NULL,
	[65_N] [int] NULL,
	[66_N] [int] NULL
) ON [PRIMARY]
END

if (select name from sys.tables where name='_Desviaciones_Voice_Williams') is null
begin
  CREATE TABLE [dbo].[_Desviaciones_Voice_Williams](
	[Entidad] [varchar](8000) NULL,
	[mnc] [varchar](2) NULL,
	[Date_Reporting] [varchar](255) NULL,
	[Report_Type] [varchar](255) NULL,
	[Test_type] [varchar](255) NULL,
	[Meas_Tech] [varchar](255) NULL,
	[1_N] [int] NULL,
	[2_N] [int] NULL,
	[3_N] [int] NULL,
	[4_N] [int] NULL,
	[5_N] [int] NULL,
	[6_N] [int] NULL,
	[7_N] [int] NULL,
	[8_N] [int] NULL
) ON [PRIMARY]
END

print '-----------------------------------------------------------------------------'
print 'PASO 1: Calculo información'
print '-----------------------------------------------------------------------------'



-------------------------------------------------------------------------------------
---------------------------------- Percentiles CST VOLTE -------------------------------
-------------------------------------------------------------------------------------

------------------------------- PERCENTIL 95 CST ALERTING ---------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------


print 'Percentil 95 Alerting MOMT 4G'

truncate table [_Percentiles_Voice_Williams]

-- Hacemos el cálculo por entidad y agregado de Ave/Roads

exec ('insert into _Percentiles_Voice_Williams
	select t1.[entity],t1.[mnc],max(t1.[Meas_date]) as MaxDate,'''+@filtroReport+''',''CST_MOMT_AL'',t1.meas_Tech,
		  sum([1_MOMT_A]) as [1_N],sum([2_MOMT_A]) as [2_N],sum([3_MOMT_A]) as [3_N],sum([4_MOMT_A]) as [4_N],sum([5_MOMT_A]) as [5_N],sum([6_MOMT_A]) as [6_N],sum([7_MOMT_A]) as [7_N],sum([8_MOMT_A]) as [8_N],sum([9_MOMT_A]) as [9_N],
		  sum([10_MOMT_A]) as [10_N],sum([11_MOMT_A]) as [11_N],sum([12_MOMT_A]) as [12_N],sum([13_MOMT_A]) as [13_N],sum([14_MOMT_A]) as [14_N],sum([15_MOMT_A]) as [15_N],sum([16_MOMT_A]) as [16_N],sum([17_MOMT_A]) as [17_N],
		  sum([18_MOMT_A]) as [18_N],sum([19_MOMT_A]) as [19_N],sum([20_MOMT_A]) as [20_N],sum([21_MOMT_A]) as [21_N],sum([22_MOMT_A]) as [22_N],sum([23_MOMT_A]) as [23_N],sum([24_MOMT_A]) as [24_N],sum([25_MOMT_A]) as [25_N],
		  sum([26_MOMT_A]) as [26_N],sum([27_MOMT_A]) as [27_N],sum([28_MOMT_A]) as [28_N],sum([29_MOMT_A]) as [29_N],sum([30_MOMT_A]) as [30_N],sum([31_MOMT_A]) as [31_N],sum([32_MOMT_A]) as [32_N],sum([33_MOMT_A]) as [33_N],sum([34_MOMT_A]) as [34_N],
		  sum([35_MOMT_A]) as [35_N],sum([36_MOMT_A]) as [36_N],sum([37_MOMT_A]) as [37_N],sum([38_MOMT_A]) as [38_N],sum([39_MOMT_A]) as [39_N],sum([40_MOMT_A]) as [40_N],sum([41_MOMT_A]) as [41_N],NULL as [42_N],NULL as [43_N],NULL as [44_N],NULL as [45_N],NULL as [46_N],NULL as [47_N],NULL as [48_N],
		  NULL as [49_N],NULL as [50_N],NULL as [51_N],NULL as [52_N],NULL as [53_N],NULL as [54_N],NULL as [55_N],NULL as [56_N],NULL as [57_N],NULL as [58_N],NULL as [59_N],NULL as [60_N],NULL as [61_N],NULL as [62_N],
		  NULL as [63_N],NULL as [64_N],NULL as [65_N],NULL as [66_N]
	from [QLIK].dbo._RI_Voice_Completed_Qlik t1
	where t1.' +@last_measurement+ ' > 0 and t1.meas_Tech in (''VOLTE ALL'',''VOLTE REALVOLTE'')
	and t1.Scope = ''ADD-ON CITIES WILLIAMS''
	group by t1.[entity],t1.[mnc],t1.meas_Tech')


-- HaceMOMTs el cálculo por Scope

exec ('insert into _Percentiles_Voice_Williams

	select Case when t2.scope like ''%EXTRA%'' then LEFT(t2.scope,len(t2.scope)-5) else t2.scope end,t1.[mnc],'''','''+@filtroReport+''',''CST_MOMT_AL'',t1.meas_Tech,
		  sum([1_MOMT_A]) as [1_N],sum([2_MOMT_A]) as [2_N],sum([3_MOMT_A]) as [3_N],sum([4_MOMT_A]) as [4_N],sum([5_MOMT_A]) as [5_N],sum([6_MOMT_A]) as [6_N],sum([7_MOMT_A]) as [7_N],sum([8_MOMT_A]) as [8_N],sum([9_MOMT_A]) as [9_N],
		  sum([10_MOMT_A]) as [10_N],sum([11_MOMT_A]) as [11_N],sum([12_MOMT_A]) as [12_N],sum([13_MOMT_A]) as [13_N],sum([14_MOMT_A]) as [14_N],sum([15_MOMT_A]) as [15_N],sum([16_MOMT_A]) as [16_N],sum([17_MOMT_A]) as [17_N],
		  sum([18_MOMT_A]) as [18_N],sum([19_MOMT_A]) as [19_N],sum([20_MOMT_A]) as [20_N],sum([21_MOMT_A]) as [21_N],sum([22_MOMT_A]) as [22_N],sum([23_MOMT_A]) as [23_N],sum([24_MOMT_A]) as [24_N],sum([25_MOMT_A]) as [25_N],
		  sum([26_MOMT_A]) as [26_N],sum([27_MOMT_A]) as [27_N],sum([28_MOMT_A]) as [28_N],sum([29_MOMT_A]) as [29_N],sum([30_MOMT_A]) as [30_N],sum([31_MOMT_A]) as [31_N],sum([32_MOMT_A]) as [32_N],sum([33_MOMT_A]) as [33_N],sum([34_MOMT_A]) as [34_N],
		  sum([35_MOMT_A]) as [35_N],sum([36_MOMT_A]) as [36_N],sum([37_MOMT_A]) as [37_N],sum([38_MOMT_A]) as [38_N],sum([39_MOMT_A]) as [39_N],sum([40_MOMT_A]) as [40_N],sum([41_MOMT_A]) as [41_N],NULL as [42_N],NULL as [43_N],NULL as [44_N],NULL as [45_N],NULL as [46_N],NULL as [47_N],NULL as [48_N],
		  NULL as [49_N],NULL as [50_N],NULL as [51_N],NULL as [52_N],NULL as [53_N],NULL as [54_N],NULL as [55_N],NULL as [56_N],NULL as [57_N],NULL as [58_N],NULL as [59_N],NULL as [60_N],NULL as [61_N],NULL as [62_N],
		  NULL as [63_N],NULL as [64_N],NULL as [65_N],NULL as [66_N]
	from [QLIK].dbo._RI_Voice_Completed_Qlik t1
			inner join [AGRIDS].[dbo].[vlcc_dashboard_info_scopes_NEW] t2 on entity=entities_bbdd and t2.report='''+@filtroReport+'''
	where t1.' +@last_measurement+ ' > 0 and t1.meas_Tech in (''VOLTE ALL'',''VOLTE REALVOLTE'')
	and t1.Scope = ''ADD-ON CITIES WILLIAMS''
	group by t2.scope,t1.[mnc],t1.meas_Tech')

--Calculamos el percentil 95 con los siguientes parametros de entrada:

		exec sp_lcc_create_STATISTICS_PERCENTIL_NEW_QLIK_DASH '_Percentiles_Voice_Williams',@step_CST_MOMT_AL,@range_CST_MOMT_AL,0,0.95


------------------------------- PERCENTIL 95 CST CONNECT ---------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------


print 'Percentil 95 Connect MOMT 4G'

truncate table [_Percentiles_Voice_Williams]

-- Hacemos el cálculo por entidad y agregado de Ave/Roads

exec ('insert into _Percentiles_Voice_Williams
	select t1.[entity],t1.[mnc],max(t1.[Meas_date]) as MaxDate,'''+@filtroReport+''',''CST_MOMT_CO'',t1.meas_Tech,
		  sum([1_MOMT_C]) as [1_N],sum([2_MOMT_C]) as [2_N],sum([3_MOMT_C]) as [3_N],sum([4_MOMT_C]) as [4_N],sum([5_MOMT_C]) as [5_N],sum([6_MOMT_C]) as [6_N],sum([7_MOMT_C]) as [7_N],sum([8_MOMT_C]) as [8_N],sum([9_MOMT_C]) as [9_N],
		  sum([10_MOMT_C]) as [10_N],sum([11_MOMT_C]) as [11_N],sum([12_MOMT_C]) as [12_N],sum([13_MOMT_C]) as [13_N],sum([14_MOMT_C]) as [14_N],sum([15_MOMT_C]) as [15_N],sum([16_MOMT_C]) as [16_N],sum([17_MOMT_C]) as [17_N],
		  sum([18_MOMT_C]) as [18_N],sum([19_MOMT_C]) as [19_N],sum([20_MOMT_C]) as [20_N],sum([21_MOMT_C]) as [21_N],sum([22_MOMT_C]) as [22_N],sum([23_MOMT_C]) as [23_N],sum([24_MOMT_C]) as [24_N],sum([25_MOMT_C]) as [25_N],
		  sum([26_MOMT_C]) as [26_N],sum([27_MOMT_C]) as [27_N],sum([28_MOMT_C]) as [28_N],sum([29_MOMT_C]) as [29_N],sum([30_MOMT_C]) as [30_N],sum([31_MOMT_C]) as [31_N],sum([32_MOMT_C]) as [32_N],sum([33_MOMT_C]) as [33_N],sum([34_MOMT_C]) as [34_N],
		  sum([35_MOMT_C]) as [35_N],sum([36_MOMT_C]) as [36_N],sum([37_MOMT_C]) as [37_N],sum([38_MOMT_C]) as [38_N],sum([39_MOMT_C]) as [39_N],sum([40_MOMT_C]) as [40_N],sum([41_MOMT_C]) as [41_N],NULL as [42_N],NULL as [43_N],NULL as [44_N],NULL as [45_N],NULL as [46_N],NULL as [47_N],NULL as [48_N],
		  NULL as [49_N],NULL as [50_N],NULL as [51_N],NULL as [52_N],NULL as [53_N],NULL as [54_N],NULL as [55_N],NULL as [56_N],NULL as [57_N],NULL as [58_N],NULL as [59_N],NULL as [60_N],NULL as [61_N],NULL as [62_N],
		  NULL as [63_N],NULL as [64_N],NULL as [65_N],NULL as [66_N]
	from [QLIK].dbo._RI_Voice_Completed_Qlik t1
	where t1.' +@last_measurement+ ' > 0 and t1.meas_Tech in (''VOLTE ALL'',''VOLTE REALVOLTE'')
	and t1.Scope = ''ADD-ON CITIES WILLIAMS''
	group by t1.[entity],t1.[mnc],t1.meas_Tech')


-- Hacemos el cálculo por Scope

exec ('insert into _Percentiles_Voice_Williams

	select Case when t2.scope like ''%EXTRA%'' then LEFT(t2.scope,len(t2.scope)-5) else t2.scope end,t1.[mnc],'''','''+@filtroReport+''',''CST_MOMT_CO'',t1.meas_Tech,
		  sum([1_MOMT_C]) as [1_N],sum([2_MOMT_C]) as [2_N],sum([3_MOMT_C]) as [3_N],sum([4_MOMT_C]) as [4_N],sum([5_MOMT_C]) as [5_N],sum([6_MOMT_C]) as [6_N],sum([7_MOMT_C]) as [7_N],sum([8_MOMT_C]) as [8_N],sum([9_MOMT_C]) as [9_N],
		  sum([10_MOMT_C]) as [10_N],sum([11_MOMT_C]) as [11_N],sum([12_MOMT_C]) as [12_N],sum([13_MOMT_C]) as [13_N],sum([14_MOMT_C]) as [14_N],sum([15_MOMT_C]) as [15_N],sum([16_MOMT_C]) as [16_N],sum([17_MOMT_C]) as [17_N],
		  sum([18_MOMT_C]) as [18_N],sum([19_MOMT_C]) as [19_N],sum([20_MOMT_C]) as [20_N],sum([21_MOMT_C]) as [21_N],sum([22_MOMT_C]) as [22_N],sum([23_MOMT_C]) as [23_N],sum([24_MOMT_C]) as [24_N],sum([25_MOMT_C]) as [25_N],
		  sum([26_MOMT_C]) as [26_N],sum([27_MOMT_C]) as [27_N],sum([28_MOMT_C]) as [28_N],sum([29_MOMT_C]) as [29_N],sum([30_MOMT_C]) as [30_N],sum([31_MOMT_C]) as [31_N],sum([32_MOMT_C]) as [32_N],sum([33_MOMT_C]) as [33_N],sum([34_MOMT_C]) as [34_N],
		  sum([35_MOMT_C]) as [35_N],sum([36_MOMT_C]) as [36_N],sum([37_MOMT_C]) as [37_N],sum([38_MOMT_C]) as [38_N],sum([39_MOMT_C]) as [39_N],sum([40_MOMT_C]) as [40_N],sum([41_MOMT_C]) as [41_N],NULL as [42_N],NULL as [43_N],NULL as [44_N],NULL as [45_N],NULL as [46_N],NULL as [47_N],NULL as [48_N],
		  NULL as [49_N],NULL as [50_N],NULL as [51_N],NULL as [52_N],NULL as [53_N],NULL as [54_N],NULL as [55_N],NULL as [56_N],NULL as [57_N],NULL as [58_N],NULL as [59_N],NULL as [60_N],NULL as [61_N],NULL as [62_N],
		  NULL as [63_N],NULL as [64_N],NULL as [65_N],NULL as [66_N]
	from [QLIK].dbo._RI_Voice_Completed_Qlik t1
			inner join [AGRIDS].[dbo].[vlcc_dashboard_info_scopes_NEW] t2 on entity=entities_bbdd and t2.report='''+@filtroReport+'''
	where t1.' +@last_measurement+ ' > 0 and t1.meas_Tech in (''VOLTE ALL'',''VOLTE REALVOLTE'')
	and t1.Scope = ''ADD-ON CITIES WILLIAMS''
	group by t2.scope,t1.[mnc],t1.meas_Tech')


--Calculamos el percentil 95 con los siguientes parametros de entrada:

		exec sp_lcc_create_STATISTICS_PERCENTIL_NEW_QLIK_DASH '_Percentiles_Voice_Williams',@step_CST_MOMT_CO,@range_CST_MOMT_CO,0,0.95


-------------------------------------------------------------------------------------
---------------------------------- Percentiles MOS 4G ----------------------------------
-------------------------------------------------------------------------------------

------------------------------- PERCENTIL 5 MOS OVERALL ---------------------------------------------------------
------------------------------------------------------------------------------------------------------------

print 'Percentil 5 MOS OVERALL 4G'

truncate table [_Percentiles_Voice_Williams]

-- Hacemos el cálculo por entidad y agregado de Ave/Roads

exec ('insert into _Percentiles_Voice_Williams
	select t1.[entity],t1.[mnc],max(t1.[Meas_date]) as MaxDate,'''+@filtroReport+''',''MOS_OVERALL'',t1.meas_Tech,
		  sum(ISNULL([1_WB],0)+ISNULL([1_NB],0)) as [1_N],sum(ISNULL([2_WB],0)+ISNULL([2_NB],0)) as [2_N],sum(ISNULL([3_WB],0)+ISNULL([3_NB],0)) as [3_N],sum(ISNULL([4_WB],0)+ISNULL([4_NB],0)) as [4_N],sum(ISNULL([5_WB],0)+ISNULL([5_NB],0)) as [5_N],
		  sum(ISNULL([6_WB],0)+ISNULL([6_NB],0)) as [6_N],sum(ISNULL([7_WB],0)+ISNULL([7_NB],0)) as [7_N],sum(ISNULL([8_WB],0)+ISNULL([8_NB],0)) as [8_N],
		  NULL as [9_N],NULL as [10_N],NULL as [11_N],NULL as [12_N],NULL as [13_N],NULL as [14_N],NULL as [15_N],NULL as [16_N],NULL as [17_N],NULL as [18_N],NULL as [19_N],NULL as [20_N],
		  NULL as [21_N],NULL as [22_N],NULL as [23_N],NULL as [24_N],NULL as [25_N],NULL as [26_N],NULL as [27_N],NULL as [28_N],NULL as [29_N],NULL as [30_N],NULL as [31_N],NULL as [32_N],
		  NULL as [33_N],NULL as [34_N],NULL as [35_N],NULL as [36_N],NULL as [37_N],NULL as [38_N],NULL as [39_N],NULL as [40_N],NULL as [41_N],NULL as [42_N],NULL as [43_N],NULL as [44_N],
		  NULL as [45_N],NULL as [46_N],NULL as [47_N],NULL as [48_N],NULL as [49_N],NULL as [50_N],NULL as [51_N],NULL as [52_N],NULL as [53_N],NULL as [54_N],NULL as [55_N],NULL as [56_N],
		  NULL as [57_N],NULL as [58_N],NULL as [59_N],NULL as [60_N],NULL as [61_N],NULL as [62_N],NULL as [63_N],NULL as [64_N],NULL as [65_N],NULL as [66_N]
	from [QLIK].dbo._RI_Voice_Completed_Qlik t1
	where t1.' +@last_measurement+ ' > 0 and t1.meas_Tech in (''VOLTE ALL'',''VOLTE REALVOLTE'')
	and t1.Scope = ''ADD-ON CITIES WILLIAMS''
	group by t1.[entity],t1.[mnc],t1.meas_Tech')


-- Hacemos el cálculo por Scope

exec ('insert into _Percentiles_Voice_Williams

	select Case when t2.scope like ''%EXTRA%'' then LEFT(t2.scope,len(t2.scope)-5) else t2.scope end,t1.[mnc],'''','''+@filtroReport+''',''MOS_OVERALL'',t1.meas_Tech,
		  sum(ISNULL([1_WB],0)+ISNULL([1_NB],0)) as [1_N],sum(ISNULL([2_WB],0)+ISNULL([2_NB],0)) as [2_N],sum(ISNULL([3_WB],0)+ISNULL([3_NB],0)) as [3_N],sum(ISNULL([4_WB],0)+ISNULL([4_NB],0)) as [4_N],sum(ISNULL([5_WB],0)+ISNULL([5_NB],0)) as [5_N],
		  sum(ISNULL([6_WB],0)+ISNULL([6_NB],0)) as [6_N],sum(ISNULL([7_WB],0)+ISNULL([7_NB],0)) as [7_N],sum(ISNULL([8_WB],0)+ISNULL([8_NB],0)) as [8_N],
		  NULL as [9_N],NULL as [10_N],NULL as [11_N],NULL as [12_N],NULL as [13_N],NULL as [14_N],NULL as [15_N],NULL as [16_N],NULL as [17_N],NULL as [18_N],NULL as [19_N],NULL as [20_N],
		  NULL as [21_N],NULL as [22_N],NULL as [23_N],NULL as [24_N],NULL as [25_N],NULL as [26_N],NULL as [27_N],NULL as [28_N],NULL as [29_N],NULL as [30_N],NULL as [31_N],NULL as [32_N],
		  NULL as [33_N],NULL as [34_N],NULL as [35_N],NULL as [36_N],NULL as [37_N],NULL as [38_N],NULL as [39_N],NULL as [40_N],NULL as [41_N],NULL as [42_N],NULL as [43_N],NULL as [44_N],
		  NULL as [45_N],NULL as [46_N],NULL as [47_N],NULL as [48_N],NULL as [49_N],NULL as [50_N],NULL as [51_N],NULL as [52_N],NULL as [53_N],NULL as [54_N],NULL as [55_N],NULL as [56_N],
		  NULL as [57_N],NULL as [58_N],NULL as [59_N],NULL as [60_N],NULL as [61_N],NULL as [62_N],NULL as [63_N],NULL as [64_N],NULL as [65_N],NULL as [66_N]
	from [QLIK].dbo._RI_Voice_Completed_Qlik t1
			inner join [AGRIDS].[dbo].[vlcc_dashboard_info_scopes_NEW] t2 on entity=entities_bbdd and t2.report='''+@filtroReport+'''
	where t1.' +@last_measurement+ ' > 0 and t1.meas_Tech in (''VOLTE ALL'',''VOLTE REALVOLTE'')
	and t1.Scope = ''ADD-ON CITIES WILLIAMS''
	group by t2.scope,t1.[mnc],t1.meas_Tech')


--Calculamos el percentil 5 con los siguientes parametros de entrada:

		exec sp_lcc_create_STATISTICS_PERCENTIL_NEW_QLIK_DASH '_Percentiles_Voice_Williams',@step_MOS_OVERALL,@range_MOS_OVERALL,1,0.05


------------------------------- PERCENTIL 5 MOS NB ---------------------------------------------------------
------------------------------------------------------------------------------------------------------------

print 'Percentil 5 MOS NB 4G'

truncate table [_Percentiles_Voice_Williams]

-- Hacemos el cálculo por entidad y agregado de Ave/Roads

exec ('insert into _Percentiles_Voice_Williams
	select t1.[entity],t1.[mnc],max(t1.[Meas_date]) as MaxDate,'''+@filtroReport+''',''MOS_NB'',t1.meas_Tech,
		  sum([1_NB]) as [1_N],sum([2_NB]) as [2_N],sum([3_NB]) as [3_N],sum([4_NB]) as [4_N],sum([5_NB]) as [5_N],sum([6_NB]) as [6_N],sum([7_NB]) as [7_N],sum([8_NB]) as [8_N],
		  NULL as [9_N],NULL as [10_N],NULL as [11_N],NULL as [12_N],NULL as [13_N],NULL as [14_N],NULL as [15_N],NULL as [16_N],NULL as [17_N],NULL as [18_N],NULL as [19_N],NULL as [20_N],
		  NULL as [21_N],NULL as [22_N],NULL as [23_N],NULL as [24_N],NULL as [25_N],NULL as [26_N],NULL as [27_N],NULL as [28_N],NULL as [29_N],NULL as [30_N],NULL as [31_N],NULL as [32_N],
		  NULL as [33_N],NULL as [34_N],NULL as [35_N],NULL as [36_N],NULL as [37_N],NULL as [38_N],NULL as [39_N],NULL as [40_N],NULL as [41_N],NULL as [42_N],NULL as [43_N],NULL as [44_N],
		  NULL as [45_N],NULL as [46_N],NULL as [47_N],NULL as [48_N],NULL as [49_N],NULL as [50_N],NULL as [51_N],NULL as [52_N],NULL as [53_N],NULL as [54_N],NULL as [55_N],NULL as [56_N],
		  NULL as [57_N],NULL as [58_N],NULL as [59_N],NULL as [60_N],NULL as [61_N],NULL as [62_N],NULL as [63_N],NULL as [64_N],NULL as [65_N],NULL as [66_N]
	from [QLIK].dbo._RI_Voice_Completed_Qlik t1
	where t1.' +@last_measurement+ ' > 0 and t1.meas_Tech in (''VOLTE ALL'',''VOLTE REALVOLTE'')
	and t1.Scope = ''ADD-ON CITIES WILLIAMS''
	group by t1.[entity],t1.[mnc],t1.meas_Tech')

-- Hacemos el cálculo por Scope

exec ('insert into _Percentiles_Voice_Williams

	select Case when t2.scope like ''%EXTRA%'' then LEFT(t2.scope,len(t2.scope)-5) else t2.scope end,t1.[mnc],'''','''+@filtroReport+''',''MOS_NB'',t1.meas_Tech,
			sum([1_NB]) as [1_N],sum([2_NB]) as [2_N],sum([3_NB]) as [3_N],sum([4_NB]) as [4_N],sum([5_NB]) as [5_N],sum([6_NB]) as [6_N],sum([7_NB]) as [7_N],sum([8_NB]) as [8_N],
			NULL as [9_N],NULL as [10_N],NULL as [11_N],NULL as [12_N],NULL as [13_N],NULL as [14_N],NULL as [15_N],NULL as [16_N],NULL as [17_N],NULL as [18_N],NULL as [19_N],NULL as [20_N],
		    NULL as [21_N],NULL as [22_N],NULL as [23_N],NULL as [24_N],NULL as [25_N],NULL as [26_N],NULL as [27_N],NULL as [28_N],NULL as [29_N],NULL as [30_N],NULL as [31_N],NULL as [32_N],
		    NULL as [33_N],NULL as [34_N],NULL as [35_N],NULL as [36_N],NULL as [37_N],NULL as [38_N],NULL as [39_N],NULL as [40_N],NULL as [41_N],NULL as [42_N],NULL as [43_N],NULL as [44_N],
		    NULL as [45_N],NULL as [46_N],NULL as [47_N],NULL as [48_N],NULL as [49_N],NULL as [50_N],NULL as [51_N],NULL as [52_N],NULL as [53_N],NULL as [54_N],NULL as [55_N],NULL as [56_N],
		    NULL as [57_N],NULL as [58_N],NULL as [59_N],NULL as [60_N],NULL as [61_N],NULL as [62_N],NULL as [63_N],NULL as [64_N],NULL as [65_N],NULL as [66_N]
	from [QLIK].dbo._RI_Voice_Completed_Qlik t1
			inner join [AGRIDS].[dbo].[vlcc_dashboard_info_scopes_NEW] t2 on entity=entities_bbdd and t2.report='''+@filtroReport+'''
	where t1.' +@last_measurement+ ' > 0 and t1.meas_Tech in (''VOLTE ALL'',''VOLTE REALVOLTE'')
	and t1.Scope = ''ADD-ON CITIES WILLIAMS''
	group by t2.scope,t1.[mnc],t1.meas_Tech')


--Calculamos el percentil 5 con los siguientes parametros de entrada:

		exec sp_lcc_create_STATISTICS_PERCENTIL_NEW_QLIK_DASH '_Percentiles_Voice_Williams',@step_MOS_NB,@range_MOS_NB,1,0.05


------------------------------- PERCENTIL 50 MOS WB ONLY - MEDIANA------------------------------------------
------------------------------------------------------------------------------------------------------------

print 'Mediana MOS WB 4G'

truncate table [_Percentiles_Voice_Williams]

-- Hacemos el cálculo por entidad y agregado de Ave/Roads

exec ('insert into _Percentiles_Voice_Williams
	select t1.[entity],t1.[mnc],max(t1.[Meas_date]) as MaxDate,'''+@filtroReport+''',''MOS_WB'',t1.meas_Tech,
		  sum([1_WB]) as [1_N],sum([2_WB]) as [2_N],sum([3_WB]) as [3_N],sum([4_WB]) as [4_N],sum([5_WB]) as [5_N],sum([6_WB]) as [6_N],sum([7_WB]) as [7_N],sum([8_WB]) as [8_N],
		  NULL as [9_N],NULL as [10_N],NULL as [11_N],NULL as [12_N],NULL as [13_N],NULL as [14_N],NULL as [15_N],NULL as [16_N],NULL as [17_N],NULL as [18_N],NULL as [19_N],NULL as [20_N],
		  NULL as [21_N],NULL as [22_N],NULL as [23_N],NULL as [24_N],NULL as [25_N],NULL as [26_N],NULL as [27_N],NULL as [28_N],NULL as [29_N],NULL as [30_N],NULL as [31_N],NULL as [32_N],
		  NULL as [33_N],NULL as [34_N],NULL as [35_N],NULL as [36_N],NULL as [37_N],NULL as [38_N],NULL as [39_N],NULL as [40_N],NULL as [41_N],NULL as [42_N],NULL as [43_N],NULL as [44_N],
		  NULL as [45_N],NULL as [46_N],NULL as [47_N],NULL as [48_N],NULL as [49_N],NULL as [50_N],NULL as [51_N],NULL as [52_N],NULL as [53_N],NULL as [54_N],NULL as [55_N],NULL as [56_N],
		  NULL as [57_N],NULL as [58_N],NULL as [59_N],NULL as [60_N],NULL as [61_N],NULL as [62_N],NULL as [63_N],NULL as [64_N],NULL as [65_N],NULL as [66_N]
	from [QLIK].dbo._RI_Voice_Completed_Qlik t1
	where t1.' +@last_measurement+ ' > 0 and t1.meas_Tech in (''VOLTE ALL'',''VOLTE REALVOLTE'')
	and t1.Scope = ''ADD-ON CITIES WILLIAMS''
	group by t1.[entity],t1.[mnc],t1.meas_Tech')

-- Hacemos el cálculo por Scope

exec ('insert into _Percentiles_Voice_Williams

	select Case when t2.scope like ''%EXTRA%'' then LEFT(t2.scope,len(t2.scope)-5) else t2.scope end,t1.[mnc],'''','''+@filtroReport+''',''MOS_WB'',t1.meas_Tech,
			sum([1_WB]) as [1_N],sum([2_WB]) as [2_N],sum([3_WB]) as [3_N],sum([4_WB]) as [4_N],sum([5_WB]) as [5_N],sum([6_WB]) as [6_N],sum([7_WB]) as [7_N],sum([8_WB]) as [8_N],
			NULL as [9_N],NULL as [10_N],NULL as [11_N],NULL as [12_N],NULL as [13_N],NULL as [14_N],NULL as [15_N],NULL as [16_N],NULL as [17_N],NULL as [18_N],NULL as [19_N],NULL as [20_N],
		    NULL as [21_N],NULL as [22_N],NULL as [23_N],NULL as [24_N],NULL as [25_N],NULL as [26_N],NULL as [27_N],NULL as [28_N],NULL as [29_N],NULL as [30_N],NULL as [31_N],NULL as [32_N],
		    NULL as [33_N],NULL as [34_N],NULL as [35_N],NULL as [36_N],NULL as [37_N],NULL as [38_N],NULL as [39_N],NULL as [40_N],NULL as [41_N],NULL as [42_N],NULL as [43_N],NULL as [44_N],
		    NULL as [45_N],NULL as [46_N],NULL as [47_N],NULL as [48_N],NULL as [49_N],NULL as [50_N],NULL as [51_N],NULL as [52_N],NULL as [53_N],NULL as [54_N],NULL as [55_N],NULL as [56_N],
		    NULL as [57_N],NULL as [58_N],NULL as [59_N],NULL as [60_N],NULL as [61_N],NULL as [62_N],NULL as [63_N],NULL as [64_N],NULL as [65_N],NULL as [66_N]
	from [QLIK].dbo._RI_Voice_Completed_Qlik t1
			inner join [AGRIDS].[dbo].[vlcc_dashboard_info_scopes_NEW] t2 on entity=entities_bbdd and t2.report='''+@filtroReport+'''
	where t1.' +@last_measurement+ ' > 0 and t1.meas_Tech in (''VOLTE ALL'',''VOLTE REALVOLTE'')
	and t1.Scope = ''ADD-ON CITIES WILLIAMS''
	group by t2.scope,t1.[mnc],t1.meas_Tech')


--Calculamos el percentil 5 con los siguientes parametros de entrada:

		exec sp_lcc_create_STATISTICS_PERCENTIL_NEW_QLIK_DASH '_Percentiles_Voice_Williams',@step_MOS_WB,@range_MOS_WB,1,0.5


-------------------------------------------------------------------------------------
---------------------------------- Desviaciones estándar MOS 4G ----------------------------------
-------------------------------------------------------------------------------------

------------------------------- DESVIACIÓN ESTÁNDAR MOS OVERALL ---------------------------------------------------------
------------------------------------------------------------------------------------------------------------

print 'Desviación estándar MOS OVERALL 4G'

truncate table [_Desviaciones_Voice_Williams]

-- Hacemos el cálculo por entidad y agregado de Ave/Roads

exec ('insert into _Desviaciones_Voice_Williams
	select t1.[entity],t1.[mnc],max(t1.[Meas_date]) as MaxDate,'''+@filtroReport+''',''MOS_OVERALL'',t1.meas_Tech,
		  sum(ISNULL([1_WB],0)+ISNULL([1_NB],0)) as [1_N],sum(ISNULL([2_WB],0)+ISNULL([2_NB],0)) as [2_N],sum(ISNULL([3_WB],0)+ISNULL([3_NB],0)) as [3_N],sum(ISNULL([4_WB],0)+ISNULL([4_NB],0)) as [4_N],sum(ISNULL([5_WB],0)+ISNULL([5_NB],0)) as [5_N],
		  sum(ISNULL([6_WB],0)+ISNULL([6_NB],0)) as [6_N],sum(ISNULL([7_WB],0)+ISNULL([7_NB],0)) as [7_N],sum(ISNULL([8_WB],0)+ISNULL([8_NB],0)) as [8_N]
	from [QLIK].dbo._RI_Voice_Completed_Qlik t1
	where t1.' +@last_measurement+ ' > 0 and t1.meas_Tech in (''VOLTE ALL'',''VOLTE REALVOLTE'')
	and t1.Scope = ''ADD-ON CITIES WILLIAMS''
	group by t1.[entity],t1.[mnc],t1.meas_Tech')


-- Hacemos el cálculo por Scope

exec ('insert into _Desviaciones_Voice_Williams

	select Case when t2.scope like ''%EXTRA%'' then LEFT(t2.scope,len(t2.scope)-5) else t2.scope end,t1.[mnc],'''','''+@filtroReport+''',''MOS_OVERALL'',t1.meas_Tech,
		  sum(ISNULL([1_WB],0)+ISNULL([1_NB],0)) as [1_N],sum(ISNULL([2_WB],0)+ISNULL([2_NB],0)) as [2_N],sum(ISNULL([3_WB],0)+ISNULL([3_NB],0)) as [3_N],sum(ISNULL([4_WB],0)+ISNULL([4_NB],0)) as [4_N],sum(ISNULL([5_WB],0)+ISNULL([5_NB],0)) as [5_N],
		  sum(ISNULL([6_WB],0)+ISNULL([6_NB],0)) as [6_N],sum(ISNULL([7_WB],0)+ISNULL([7_NB],0)) as [7_N],sum(ISNULL([8_WB],0)+ISNULL([8_NB],0)) as [8_N]
	from [QLIK].dbo._RI_Voice_Completed_Qlik t1
			inner join [AGRIDS].[dbo].[vlcc_dashboard_info_scopes_NEW] t2 on entity=entities_bbdd and t2.report='''+@filtroReport+'''
	where t1.' +@last_measurement+ ' > 0 and t1.meas_Tech in (''VOLTE ALL'',''VOLTE REALVOLTE'')
	and t1.Scope = ''ADD-ON CITIES WILLIAMS''
	group by t2.scope,t1.[mnc],t1.meas_Tech')


--Calculamos el percentil 5 con los siguientes parametros de entrada:
		exec sp_lcc_create_STATISTICS_STDV_NEW_QLIK_DASH '_Desviaciones_Voice_Williams',@step_MOS_OVERALL,@range_MOS_OVERALL,1


------------------------------- DESVIACIÓN ESTÁNDAR MOS NB ---------------------------------------------------------
------------------------------------------------------------------------------------------------------------

print 'Desviación estándar MOS NB 4G'

truncate table [_Desviaciones_Voice_Williams]

-- Hacemos el cálculo por entidad y agregado de Ave/Roads

exec ('insert into _Desviaciones_Voice_Williams
	select t1.[entity],t1.[mnc],max(t1.[Meas_date]) as MaxDate,'''+@filtroReport+''',''MOS_NB'',t1.meas_Tech,
		  sum([1_NB]) as [1_N],sum([2_NB]) as [2_N],sum([3_NB]) as [3_N],sum([4_NB]) as [4_N],sum([5_NB]) as [5_N],sum([6_NB]) as [6_N],sum([7_NB]) as [7_N],sum([8_NB]) as [8_N]
	from [QLIK].dbo._RI_Voice_Completed_Qlik t1
	where t1.' +@last_measurement+ ' > 0 and t1.meas_Tech in (''VOLTE ALL'',''VOLTE REALVOLTE'')
	and t1.Scope = ''ADD-ON CITIES WILLIAMS''
	group by t1.[entity],t1.[mnc],t1.meas_Tech')

-- Hacemos el cálculo por Scope

exec ('insert into _Desviaciones_Voice_Williams

	select Case when t2.scope like ''%EXTRA%'' then LEFT(t2.scope,len(t2.scope)-5) else t2.scope end,t1.[mnc],'''','''+@filtroReport+''',''MOS_NB'',t1.meas_Tech,
			sum([1_NB]) as [1_N],sum([2_NB]) as [2_N],sum([3_NB]) as [3_N],sum([4_NB]) as [4_N],sum([5_NB]) as [5_N],sum([6_NB]) as [6_N],sum([7_NB]) as [7_N],sum([8_NB]) as [8_N]
	from [QLIK].dbo._RI_Voice_Completed_Qlik t1
			inner join [AGRIDS].[dbo].[vlcc_dashboard_info_scopes_NEW] t2 on entity=entities_bbdd and t2.report='''+@filtroReport+'''
	where t1.' +@last_measurement+ ' > 0 and t1.meas_Tech in (''VOLTE ALL'',''VOLTE REALVOLTE'')
	and t1.Scope = ''ADD-ON CITIES WILLIAMS''
	group by t2.scope,t1.[mnc],t1.meas_Tech')


--Calculamos el percentil 5 con los siguientes parametros de entrada:

		exec sp_lcc_create_STATISTICS_STDV_NEW_QLIK_DASH '_Desviaciones_Voice_Williams',@step_MOS_NB,@range_MOS_NB,1









