USE [AddedValue]
GO
/****** Object:  StoredProcedure [dbo].[plcc_data_statistics_new_Williams]    Script Date: 21/03/2018 13:01:35 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



ALTER PROCEDURE [dbo].[plcc_data_statistics_new_Williams](
	@last_measurement as varchar(256)
)
AS

-----------------------------
----- Testing Variables -----
-----------------------------
--declare @last_measurement as varchar(256)='last_measurement_osp' --= 'last_measurement_osp'
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

--Borramos la tabla que tendra la información de todos los percentiles sacados
truncate table _Resultados_Percentiles
truncate table _Resultados_STDV


--Rangos
declare @step_old_3G_DL as float=1
declare @N_ranges_old_3G_DL as int=33  --Rango máximo: 32
declare @step_new_3G_DL as float=0.75
declare @N_ranges_new_3G_DL as int=45  --Rango máximo: 33
declare @step_old_3G_UL as float=0.5
declare @N_ranges_old_3G_UL as int=11  --Rango máximo: 5
declare @step_new_3G_UL as float=0.25
declare @N_ranges_new_3G_UL as int=21  --Rango máximo: 5

declare @step_old_4G_DL as float=5
declare @N_ranges_old_4G_DL as int=31  --Rango máximo: 150
declare @step_new_4G_DL_CE as float=2
declare @N_ranges_new_4G_DL_CE as int=51  --Rango máximo: 100
declare @step_new_4G_DL_NC as float=3.5
declare @N_ranges_new_4G_DL_NC as int=57  --Rango máximo: 196

declare @step_old_4G_UL as float=5
declare @N_ranges_old_4G_UL as int=11  --Rango máximo: 50
declare @step_new_4G_UL_CE as float=0.5
declare @N_ranges_new_4G_UL_CE as int=51  --Rango máximo: 25
declare @step_new_4G_UL_NC as float=0.8
declare @N_ranges_new_4G_UL_NC as int=66  --Rango máximo: 52



declare @step_3G_DL as float
declare @N_ranges_3G_DL as int
declare @step_3G_UL as float
declare @N_ranges_3G_UL as int
declare @step_4G_DL_CE as float
declare @N_ranges_4G_DL_CE as int
declare @step_4G_DL_NC as float
declare @N_ranges_4G_DL_NC as int
declare @step_4G_UL_CE as float
declare @N_ranges_4G_UL_CE as int
declare @step_4G_UL_NC as float
declare @N_ranges_4G_UL_NC as int


exec sp_lcc_dropifexists 'lcc_data_qlik_percentiles_Entidades_step1_Williams'
exec sp_lcc_dropifexists 'lcc_data_qlik_percentiles_Scope_step1_Williams'


print '-----------------------------------------------------------------------------'
print 'PASO 1: Calculo información con o sin rangos nuevos' 
print '-----------------------------------------------------------------------------'
-- Calcula entidades con o sin nuevos rangos
exec ('
select [entity],[mnc],Test_type,meas_Tech
	,sum(case when [1_N] is null then 1 else 0 end) as ''Cuenta_nulos''
into lcc_data_qlik_percentiles_Entidades_step1_Williams
from [QLIK].dbo._RI_Data_Completed_Qlik
where ' +@last_measurement+ ' in (1,2,3,4)
group by [entity],[mnc],Test_type,meas_Tech')

-- Calcula scopes con o sin nuevos rangos
exec ('
select Case when t2.scope like ''%EXTRA%'' then LEFT(t2.scope,len(t2.scope)-5) else t2.scope end as scope,[mnc],Test_type,meas_Tech
	,sum(case when [1_N] is null then 1 else 0 end) as ''Cuenta_nulos''
into lcc_data_qlik_percentiles_Scope_step1_Williams
from [QLIK].dbo._RI_Data_Completed_Qlik t1
	inner join [AGRIDS].[dbo].[vlcc_dashboard_info_scopes_NEW] t2
		on entity=entities_bbdd and t2.report='''+@filtroReport+'''
where ' +@last_measurement+ ' in (1,2,3,4) and Num_tests is not null
group by Case when t2.scope like ''%EXTRA%'' then LEFT(t2.scope,len(t2.scope)-5) else t2.scope end,[mnc],Test_type,meas_Tech

union all

--le añadimos el ping posteriormente ya que se van con la condición de ''Num_test is not null''
select Case when t2.scope like ''%EXTRA%'' then LEFT(t2.scope,len(t2.scope)-5) else t2.scope end as scope,[mnc],Test_type,meas_Tech
	,sum(case when [1_N] is null then 1 else 0 end) as ''Cuenta_nulos''
from [QLIK].dbo._RI_Data_Completed_Qlik t1
	inner join [AGRIDS].[dbo].[vlcc_dashboard_info_scopes_NEW] t2
		on entity=entities_bbdd and t2.report='''+@filtroReport+'''
where ' +@last_measurement+ ' in (1,2,3,4) and test_type = ''Ping''
group by Case when t2.scope like ''%EXTRA%'' then LEFT(t2.scope,len(t2.scope)-5) else t2.scope end,[mnc],Test_type,meas_Tech')



declare @it as int=1
declare @selectRangos as varchar(4000)=''
declare @cruceRangos as varchar(256)=''
declare @insertRangos as varchar(256)=''


while @it <= 2
begin 

	if @it=1 --Rangos antiguos
		begin
			print 'Calculo percentiles con RANGOS ANTIGUOS'
			print '---------------------------------------'
			--set @selectRangos= 'sum([1]),sum([2]),sum([3]),sum([4]),sum([5]),sum([6]),sum([7]),sum([8]),sum([9]),sum([10]),sum([11]),sum([12]),sum([13]),sum([14]),sum([15]),sum([16]),sum([17]),sum([18]),sum([19]),sum([20]),sum([21]),sum([22]),sum([23]),sum([24]),sum([25]),sum([26]),sum([27]),sum([28]),sum([29]),sum([30]),sum([31]),sum([32]),sum([33]),sum([34]),sum([35]),sum([36]),sum([37]),sum([38]),sum([39]),sum([40]),sum([41])'
			set @selectRangos='sum([1]) as [1],sum([2]) as [2],sum([3]) as [3],sum([4]) as [4],sum([5]) as [5],sum([6]) as [6],sum([7]) as [7],sum([8]) as [8],sum([9]) as [9],sum([10]) as [10],sum([11]) as [11],sum([12]) as [12],sum([13]) as [13],sum([14]) as [14],sum([15]) as [15],sum([16]) as [16],sum([17]) as [17],sum([18]) as [18],sum([19]) as [19],sum([20]) as [20],sum([21]) as [21],sum([22]) as [22],sum([23]) as [23],sum([24]) as [24],sum([25]) as [25],sum([26]) as [26],sum([27]) as [27],sum([28]) as [28],sum([29]) as [29],sum([30]) as [30],sum([31]) as [31],sum([32]) as [32],sum([33]) as [33],sum([34]) as [34],sum([35]) as [35],sum([36]) as [36],sum([37]) as [37],sum([38]) as [38],sum([39]) as [39],sum([40]) as [40],sum([41]) as [41],null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null'
			set @cruceRangos='Cuenta_nulos>0'
			set @insertRangos='[_Percentiles_O_Williams]'

			--Rangos 3G (son iguales en CE y NC tanto en rangos nuevos como antiguos)
			set @step_3G_DL =@step_old_3G_DL
			set @N_ranges_3G_DL =@N_ranges_old_3G_DL
			set @step_3G_UL =@step_old_3G_UL
			set @N_ranges_3G_UL =@N_ranges_old_3G_UL
			--Rangos 4G (son distintos en CE y NC para rangos nuevos por lo que hay que separarlos)
			set @step_4G_DL_CE =@step_old_4G_DL
			set @N_ranges_4G_DL_CE =@N_ranges_old_4G_DL
			set @step_4G_DL_NC =@step_old_4G_DL
			set @N_ranges_4G_DL_NC =@N_ranges_old_4G_DL
			set @step_4G_UL_CE =@step_old_4G_UL
			set @N_ranges_4G_UL_CE =@N_ranges_old_4G_UL
			set @step_4G_UL_NC =@step_old_4G_UL
			set @N_ranges_4G_UL_NC =@N_ranges_old_4G_UL

		end
	else if @it=2 --Rangos nuevos
		begin
			print 'Calculo percentiles con RANGOS NUEVOS'
			print '-------------------------------------'
			--set @selectRangos= 'sum([1_N]),sum([2_N]),sum([3_N]),sum([4_N]),sum([5_N]),sum([6_N]),sum([7_N]),sum([8_N]),sum([9_N]),sum([10_N]),sum([11_N]),sum([12_N]),sum([13_N]),sum([14_N]),sum([15_N]),sum([16_N]),sum([17_N]),sum([18_N]),sum([19_N]),sum([20_N]),sum([21_N]),sum([22_N]),sum([23_N]),sum([24_N]),sum([25_N]),sum([26_N]),sum([27_N]),sum([28_N]),sum([29_N]),sum([30_N]),sum([31_N]),sum([32_N]),sum([33_N]),sum([34_N]),sum([35_N]),sum([36_N]),sum([37_N]),sum([38_N]),sum([39_N]),sum([40_N]),sum([41_N]),sum([42_N]),sum([43_N]),sum([44_N]),sum([45_N]),sum([46_N]),sum([47_N]),sum([48_N]),sum([49_N]),sum([50_N]),sum([51_N]),sum([52_N]),sum([53_N]),sum([54_N]),sum([55_N]),sum([56_N]),sum([57_N]),sum([58_N]),sum([59_N]),sum([60_N]),sum([61_N]),sum([62_N]),sum([63_N]),sum([64_N]),sum([65_N]),sum([66_N])'
			set @selectRangos= 'sum([1_N]) as [1_N],sum([2_N]) as [2_N],sum([3_N]) as [3_N],sum([4_N]) as [4_N],sum([5_N]) as [5_N],sum([6_N]) as [6_N],sum([7_N]) as [7_N],sum([8_N]) as [8_N],sum([9_N]) as [9_N],sum([10_N]) as [10_N],sum([11_N]) as [11_N],sum([12_N]) as [12_N],sum([13_N]) as [13_N],sum([14_N]) as [14_N],sum([15_N]) as [15_N],sum([16_N]) as [16_N],sum([17_N]) as [17_N],sum([18_N]) as [18_N],sum([19_N]) as [19_N],sum([20_N]) as [20_N],sum([21_N]) as [21_N],sum([22_N]) as [22_N],sum([23_N]) as [23_N],sum([24_N]) as [24_N],sum([25_N]) as [25_N],sum([26_N]) as [26_N],sum([27_N]) as [27_N],sum([28_N]) as [28_N],sum([29_N]) as [29_N],sum([30_N]) as [30_N],sum([31_N]) as [31_N],sum([32_N]) as [32_N],sum([33_N]) as [33_N],sum([34_N]) as [34_N],sum([35_N]) as [35_N],sum([36_N]) as [36_N],sum([37_N]) as [37_N],sum([38_N]) as [38_N],sum([39_N]) as [39_N],sum([40_N]) as [40_N],sum([41_N]) as [41_N],sum([42_N]) as [42_N],sum([43_N]) as [43_N],sum([44_N]) as [44_N],sum([45_N]) as [45_N],sum([46_N]) as [46_N],sum([47_N]) as [47_N],sum([48_N]) as [48_N],sum([49_N]) as [49_N],sum([50_N]) as [50_N],sum([51_N]) as [51_N],sum([52_N]) as [52_N],sum([53_N]) as [53_N],sum([54_N]) as [54_N],sum([55_N]) as [55_N],sum([56_N]) as [56_N],sum([57_N]) as [57_N],sum([58_N]) as [58_N],sum([59_N]) as [59_N],sum([60_N]) as [60_N],sum([61_N]) as [61_N],sum([62_N]) as [62_N],sum([63_N]) as [63_N],sum([64_N]) as [64_N],sum([65_N]) as [65_N],sum([66_N]) as [66_N]'
			set @cruceRangos='Cuenta_nulos=0'
			set @insertRangos='[_Percentiles_N_Williams]'

			--Rangos 3G (son iguales en CE y NC tanto en rangos nuevos como antiguos)
			set @step_3G_DL =@step_new_3G_DL
			set @N_ranges_3G_DL =@N_ranges_new_3G_DL
			set @step_3G_UL =@step_new_3G_UL
			set @N_ranges_3G_UL =@N_ranges_new_3G_UL
			--Rangos 4G (son distintos en CE y NC para rangos nuevos por lo que hay que separarlos)
			set @step_4G_DL_CE =@step_new_4G_DL_CE
			set @N_ranges_4G_DL_CE =@N_ranges_new_4G_DL_CE
			set @step_4G_DL_NC =@step_new_4G_DL_NC
			set @N_ranges_4G_DL_NC =@N_ranges_new_4G_DL_NC
			set @step_4G_UL_CE =@step_new_4G_UL_CE
			set @N_ranges_4G_UL_CE =@N_ranges_new_4G_UL_CE
			set @step_4G_UL_NC =@step_new_4G_UL_NC
			set @N_ranges_4G_UL_NC =@N_ranges_new_4G_UL_NC
		end	

	exec sp_lcc_dropifexists 'lcc_data_qlik_percentiles_Entidades_step2_Williams'
	exec sp_lcc_dropifexists 'lcc_data_qlik_percentiles_Scope_step2_Williams'


	-- Info entidades con o sin nuevos rangos
	exec ('select *
	into lcc_data_qlik_percentiles_Entidades_step2_Williams
	from lcc_data_qlik_percentiles_Entidades_step1_Williams
	where ' +@cruceRangos)

	-- Info scopes con o sin nuevos rangos
	exec ('select *
	into lcc_data_qlik_percentiles_Scope_step2_Williams
	from lcc_data_qlik_percentiles_Scope_step1_Williams
	where ' +@cruceRangos)


	---------------------------------------------------------------------------------------
	-----------------------------------Percentiles DL CE 4G--------------------------------
	---------------------------------------------------------------------------------------
	print 'Percentiles DL CE 4G'
	exec ('truncate table '+@insertRangos)
	exec ('insert into '+@insertRangos+'
	--Entidades
	select t1.[entity],t1.[mnc],max(t1.[Meas_date]),'''+@filtroReport+''',t1.Test_type,t1.meas_Tech,
		'+@selectRangos+'
	from [QLIK].dbo._RI_Data_Completed_Qlik t1
		inner join lcc_data_qlik_percentiles_Entidades_step2_Williams t2
			on t1.[entity]=t2.[entity] and t1.[mnc]=t2.[mnc] and t1.Test_type=t2.Test_type and t1.meas_Tech=t2.meas_Tech
	where t1.' +@last_measurement+ ' >0
		and t1.Test_type = ''CE_DL'' and t1.scope=''ADD-ON CITIES WILLIAMS'' and t1.meas_Tech in (''4G'',''4GOnly'')
	group by t1.[entity],t1.[mnc],t1.Test_type,t1.meas_Tech')
	
	exec ('insert into '+@insertRangos+' 
	--Acumulado scope
	select Case when t2.scope like ''%EXTRA%'' then LEFT(t2.scope,len(t2.scope)-5) else t2.scope end as entity,t1.[mnc],'''','''+@filtroReport+''',t1.Test_type,t1.meas_Tech,
		'+@selectRangos+'
	from [QLIK].dbo._RI_Data_Completed_Qlik t1
		inner join [AGRIDS].[dbo].[vlcc_dashboard_info_scopes_NEW] t2
			on entity=entities_bbdd and t2.report='''+@filtroReport+'''
		inner join lcc_data_qlik_percentiles_Scope_step2_Williams t3
			on t3.[scope]=t2.[scope] and t1.[mnc]=t3.[mnc] and t1.Test_type=t3.Test_type and t1.meas_Tech=t3.meas_Tech
	where t1.' +@last_measurement+ ' >0
		and t1.Test_type = ''CE_DL'' and t1.scope=''ADD-ON CITIES WILLIAMS'' and t1.meas_Tech in (''4G'',''4GOnly'')
	group by Case when t2.scope like ''%EXTRA%'' then LEFT(t2.scope,len(t2.scope)-5) else t2.scope end,t1.[mnc],t1.Test_type,t1.meas_Tech')	
	


	if @it=1 --Rangos antiguos
	begin
		exec sp_lcc_create_STATISTICS_PERCENTIL_QLIK_DASH '_Percentiles_O_Williams',@step_4G_DL_CE,@N_ranges_4G_DL_CE,0,0.9
		exec sp_lcc_create_STATISTICS_PERCENTIL_QLIK_DASH '_Percentiles_O_Williams',@step_4G_DL_CE,@N_ranges_4G_DL_CE,0,0.1

		exec sp_lcc_create_STATISTICS_STDV_QLIK_DASH '_Percentiles_O_Williams',@step_4G_DL_CE,@N_ranges_4G_DL_CE,0
	end
	else
	begin
		exec sp_lcc_create_STATISTICS_PERCENTIL_NEW_QLIK_DASH '_Percentiles_N_Williams',@step_4G_DL_CE,@N_ranges_4G_DL_CE,0,0.9
		exec sp_lcc_create_STATISTICS_PERCENTIL_NEW_QLIK_DASH '_Percentiles_N_Williams',@step_4G_DL_CE,@N_ranges_4G_DL_CE,0,0.1

		exec sp_lcc_create_STATISTICS_STDV_NEW_QLIK_DASH '_Percentiles_N_Williams',@step_4G_DL_CE,@N_ranges_4G_DL_CE,0
	end
	
	
	---------------------------------------------------------------------------------------
	-----------------------------------Percentiles DL NC 4G--------------------------------
	---------------------------------------------------------------------------------------
	print 'Percentiles DL NC 4G'
	exec ('truncate table '+@insertRangos)
	exec ('insert into '+@insertRangos+'
	--Entidades 
	select t1.[entity],t1.[mnc],max(t1.[Meas_date]),'''+@filtroReport+''',t1.Test_type,t1.meas_Tech,
		'+@selectRangos+'
	from [QLIK].dbo._RI_Data_Completed_Qlik t1
		inner join lcc_data_qlik_percentiles_Entidades_step2_Williams t2
			on t1.[entity]=t2.[entity] and t1.[mnc]=t2.[mnc] and t1.Test_type=t2.Test_type and t1.meas_Tech=t2.meas_Tech
	where t1.' +@last_measurement+ ' >0
		and t1.Test_type = ''NC_DL'' and t1.scope=''ADD-ON CITIES WILLIAMS'' and t1.meas_Tech in (''4G'',''4GOnly'')
	group by t1.[entity],t1.[mnc],t1.Test_type,t1.meas_Tech')
	
	exec ('insert into '+@insertRangos+' 
	--Acumulado scope
	select Case when t2.scope like ''%EXTRA%'' then LEFT(t2.scope,len(t2.scope)-5) else t2.scope end as entity,t1.[mnc],'''','''+@filtroReport+''',t1.Test_type,t1.meas_Tech,
		'+@selectRangos+'
	from [QLIK].dbo._RI_Data_Completed_Qlik t1
		inner join [AGRIDS].[dbo].[vlcc_dashboard_info_scopes_NEW] t2
			on entity=entities_bbdd and t2.report='''+@filtroReport+'''
		inner join lcc_data_qlik_percentiles_Scope_step2_Williams t3
			on t3.[scope]=t2.[scope] and t1.[mnc]=t3.[mnc] and t1.Test_type=t3.Test_type and t1.meas_Tech=t3.meas_Tech
	where t1.' +@last_measurement+ ' >0
		and t1.Test_type = ''NC_DL'' and t1.scope=''ADD-ON CITIES WILLIAMS'' and t1.meas_Tech in (''4G'',''4GOnly'')
	group by Case when t2.scope like ''%EXTRA%'' then LEFT(t2.scope,len(t2.scope)-5) else t2.scope end,t1.[mnc],t1.Test_type,t1.meas_Tech')
	

	if @it=1 --Rangos antiguos
	begin
		exec sp_lcc_create_STATISTICS_PERCENTIL_QLIK_DASH '_Percentiles_O_Williams',@step_4G_DL_NC,@N_ranges_4G_DL_NC,0,0.9
		exec sp_lcc_create_STATISTICS_PERCENTIL_QLIK_DASH '_Percentiles_O_Williams',@step_4G_DL_NC,@N_ranges_4G_DL_NC,0,0.1

		exec sp_lcc_create_STATISTICS_STDV_QLIK_DASH '_Percentiles_O_Williams',@step_4G_DL_NC,@N_ranges_4G_DL_NC,0
	end
	else
	begin
		exec sp_lcc_create_STATISTICS_PERCENTIL_NEW_QLIK_DASH '_Percentiles_N_Williams',@step_4G_DL_NC,@N_ranges_4G_DL_NC,0,0.9
		exec sp_lcc_create_STATISTICS_PERCENTIL_NEW_QLIK_DASH '_Percentiles_N_Williams',@step_4G_DL_NC,@N_ranges_4G_DL_NC,0,0.1

		exec sp_lcc_create_STATISTICS_STDV_NEW_QLIK_DASH '_Percentiles_N_Williams',@step_4G_DL_NC,@N_ranges_4G_DL_NC,0
	end


	-------------------------------------------------------------------------------------
	---------------------------------Percentiles UL CE 4G--------------------------------
	-------------------------------------------------------------------------------------
	print 'Percentiles UL CE 4G'
	exec ('truncate table '+@insertRangos)
	exec ('insert into '+@insertRangos+'
	--Entidades 
	select t1.[entity],t1.[mnc],max(t1.[Meas_date]),'''+@filtroReport+''',t1.Test_type,t1.meas_Tech,
		'+@selectRangos+'
	from [QLIK].dbo._RI_Data_Completed_Qlik t1
		inner join lcc_data_qlik_percentiles_Entidades_step2_Williams t2
			on t1.[entity]=t2.[entity] and t1.[mnc]=t2.[mnc] and t1.Test_type=t2.Test_type and t1.meas_Tech=t2.meas_Tech
	where t1.' +@last_measurement+ ' >0
		and t1.Test_type = ''CE_UL'' and t1.scope=''ADD-ON CITIES WILLIAMS'' and t1.meas_Tech in (''4G'',''4GOnly'')
	group by t1.[entity],t1.[mnc],t1.Test_type,t1.meas_Tech')


	exec ('insert into '+@insertRangos+' 
	--Acumulado scope
	select Case when t2.scope like ''%EXTRA%'' then LEFT(t2.scope,len(t2.scope)-5) else t2.scope end as entity,t1.[mnc],'''','''+@filtroReport+''',t1.Test_type,t1.meas_Tech,
		'+@selectRangos+'
	from [QLIK].dbo._RI_Data_Completed_Qlik t1
		inner join [AGRIDS].[dbo].[vlcc_dashboard_info_scopes_NEW] t2
			on entity=entities_bbdd and t2.report='''+@filtroReport+'''
		inner join lcc_data_qlik_percentiles_Scope_step2_Williams t3
			on t3.[scope]=t2.[scope] and t1.[mnc]=t3.[mnc] and t1.Test_type=t3.Test_type and t1.meas_Tech=t3.meas_Tech
	where t1.' +@last_measurement+ ' >0
		and t1.Test_type = ''CE_UL'' and t1.scope=''ADD-ON CITIES WILLIAMS'' and t1.meas_Tech in (''4G'',''4GOnly'')
	group by Case when t2.scope like ''%EXTRA%'' then LEFT(t2.scope,len(t2.scope)-5) else t2.scope end,t1.[mnc],t1.Test_type,t1.meas_Tech')
	

	if @it=1 --Rangos antiguos
	begin
		exec sp_lcc_create_STATISTICS_PERCENTIL_QLIK_DASH '_Percentiles_O_Williams',@step_4G_UL_CE,@N_ranges_4G_UL_CE,0,0.9
		exec sp_lcc_create_STATISTICS_PERCENTIL_QLIK_DASH '_Percentiles_O_Williams',@step_4G_UL_CE,@N_ranges_4G_UL_CE,0,0.1

		exec sp_lcc_create_STATISTICS_STDV_QLIK_DASH '_Percentiles_O_Williams',@step_4G_UL_CE,@N_ranges_4G_UL_CE,0
	end
	else
	begin
		exec sp_lcc_create_STATISTICS_PERCENTIL_NEW_QLIK_DASH '_Percentiles_N_Williams',@step_4G_UL_CE,@N_ranges_4G_UL_CE,0,0.9
		exec sp_lcc_create_STATISTICS_PERCENTIL_NEW_QLIK_DASH '_Percentiles_N_Williams',@step_4G_UL_CE,@N_ranges_4G_UL_CE,0,0.1

		exec sp_lcc_create_STATISTICS_STDV_NEW_QLIK_DASH '_Percentiles_N_Williams',@step_4G_UL_CE,@N_ranges_4G_UL_CE,0
	end

	-------------------------------------------------------------------------------------
	---------------------------------Percentiles UL NC 4G--------------------------------
	-------------------------------------------------------------------------------------
	print 'Percentiles UL NC 4G'
	exec ('truncate table '+@insertRangos)
	exec ('insert into '+@insertRangos+'
	--Entidades 
	select t1.[entity],t1.[mnc],max(t1.[Meas_date]),'''+@filtroReport+''',t1.Test_type,t1.meas_Tech,
		'+@selectRangos+'
	from [QLIK].dbo._RI_Data_Completed_Qlik t1
		inner join lcc_data_qlik_percentiles_Entidades_step2_Williams t2
			on t1.[entity]=t2.[entity] and t1.[mnc]=t2.[mnc] and t1.Test_type=t2.Test_type and t1.meas_Tech=t2.meas_Tech
	where t1.' +@last_measurement+ '> 0
		and t1.Test_type = ''NC_UL'' and t1.scope=''ADD-ON CITIES WILLIAMS'' and t1.meas_Tech in (''4G'',''4GOnly'')
	group by t1.[entity],t1.[mnc],t1.Test_type,t1.meas_Tech')
	
	exec ('insert into '+@insertRangos+' 
	--Acumulado scope
	select Case when t2.scope like ''%EXTRA%'' then LEFT(t2.scope,len(t2.scope)-5) else t2.scope end as entity,t1.[mnc],'''','''+@filtroReport+''',t1.Test_type,t1.meas_Tech,
		'+@selectRangos+'
	from [QLIK].dbo._RI_Data_Completed_Qlik t1
		inner join [AGRIDS].[dbo].[vlcc_dashboard_info_scopes_NEW] t2
			on entity=entities_bbdd and t2.report='''+@filtroReport+'''
		inner join lcc_data_qlik_percentiles_Scope_step2_Williams t3
			on t3.[scope]=t2.[scope] and t1.[mnc]=t3.[mnc] and t1.Test_type=t3.Test_type and t1.meas_Tech=t3.meas_Tech
	where t1.' +@last_measurement+ ' > 0
		and t1.Test_type = ''NC_UL'' and t1.scope=''ADD-ON CITIES WILLIAMS'' and t1.meas_Tech in (''4G'',''4GOnly'')
	group by Case when t2.scope like ''%EXTRA%'' then LEFT(t2.scope,len(t2.scope)-5) else t2.scope end,t1.[mnc],t1.Test_type,t1.meas_Tech')
	
	if @it=1 --Rangos antiguos
	begin
		exec sp_lcc_create_STATISTICS_PERCENTIL_QLIK_DASH '_Percentiles_O_Williams',@step_4G_UL_NC,@N_ranges_4G_UL_NC,0,0.9
		exec sp_lcc_create_STATISTICS_PERCENTIL_QLIK_DASH '_Percentiles_O_Williams',@step_4G_UL_NC,@N_ranges_4G_UL_NC,0,0.1

		exec sp_lcc_create_STATISTICS_STDV_QLIK_DASH '_Percentiles_O_Williams',@step_4G_UL_NC,@N_ranges_4G_UL_NC,0
	end
	else
	begin
		exec sp_lcc_create_STATISTICS_PERCENTIL_NEW_QLIK_DASH '_Percentiles_N_Williams',@step_4G_UL_NC,@N_ranges_4G_UL_NC,0,0.9
		exec sp_lcc_create_STATISTICS_PERCENTIL_NEW_QLIK_DASH '_Percentiles_N_Williams',@step_4G_UL_NC,@N_ranges_4G_UL_NC,0,0.1

		exec sp_lcc_create_STATISTICS_STDV_NEW_QLIK_DASH '_Percentiles_N_Williams',@step_4G_UL_NC,@N_ranges_4G_UL_NC,0
	end

	if @it=2 --Rangos nuevos
	begin
		-------------------------------------------------------------------------------------
		----------------------------------Percentiles Ping-----------------------------------
		-------------------------------------------------------------------------------------
		print 'Percentiles Ping'
		-- (Tiene únicamente un rango almacenado en _N)
		exec ('truncate table '+@insertRangos)
		exec ('insert into '+@insertRangos+'
		--Entidades
		select t1.[entity],t1.[mnc],max(t1.[Meas_date]),'''+@filtroReport+''',t1.Test_type,t1.meas_Tech,
			'+@selectRangos+'
		from [QLIK].dbo._RI_Data_Completed_Qlik t1
			inner join lcc_data_qlik_percentiles_Entidades_step2_Williams t2
				on t1.[entity]=t2.[entity] and t1.[mnc]=t2.[mnc] and t1.Test_type=t2.Test_type and t1.meas_Tech=t2.meas_Tech
		where t1.' +@last_measurement+ ' >0
			and t1.Test_type = ''Ping'' and t1.meas_Tech in (''4G'',''4GOnly'')  and t1.scope=''ADD-ON CITIES WILLIAMS''
		group by t1.[entity],t1.[mnc],t1.Test_type,t1.meas_Tech')
		
		exec ('insert into '+@insertRangos+' 
		--Acumulado scope
		select Case when t2.scope like ''%EXTRA%'' then LEFT(t2.scope,len(t2.scope)-5) else t2.scope end as entity,t1.[mnc],'''','''+@filtroReport+''',t1.Test_type,t1.meas_Tech,
			'+@selectRangos+'
		from [QLIK].dbo._RI_Data_Completed_Qlik t1
			inner join [AGRIDS].[dbo].[vlcc_dashboard_info_scopes_NEW] t2
				on entity=entities_bbdd and t2.report='''+@filtroReport+'''
			inner join lcc_data_qlik_percentiles_Scope_step2_Williams t3
				on t3.[scope]=t2.[scope] and t1.[mnc]=t3.[mnc] and t1.Test_type=t3.Test_type and t1.meas_Tech=t3.meas_Tech
		where t1.' +@last_measurement+ ' >0
			and t1.Test_type = ''Ping'' and t1.meas_Tech in (''4G'',''4GOnly'')  and t1.scope=''ADD-ON CITIES WILLIAMS''
		group by Case when t2.scope like ''%EXTRA%'' then LEFT(t2.scope,len(t2.scope)-5) else t2.scope end,t1.[mnc],t1.Test_type,t1.meas_Tech')

		exec sp_lcc_create_STATISTICS_PERCENTIL_NEW_QLIK_DASH '_Percentiles_N_Williams',5,41,0,0.5
	end
	set @it=@it+1
end


--exec sp_lcc_dropifexists 'lcc_data_qlik_percentiles_Entidades_step1'
--exec sp_lcc_dropifexists 'lcc_data_qlik_percentiles_Roads_Last_step1'
--exec sp_lcc_dropifexists 'lcc_data_qlik_percentiles_Scope_step1'
--exec sp_lcc_dropifexists 'lcc_data_qlik_percentiles_BigCities_step1'
--exec sp_lcc_dropifexists 'lcc_data_qlik_percentiles_MainHighwaysQlik_step1'
--exec sp_lcc_dropifexists 'lcc_data_qlik_percentiles_SmallerCitiesQlik_step1'
--exec sp_lcc_dropifexists 'lcc_data_qlik_percentiles_Entidades_step2'
--exec sp_lcc_dropifexists 'lcc_data_qlik_percentiles_Roads_Last_step2'
--exec sp_lcc_dropifexists 'lcc_data_qlik_percentiles_Scope_step2'
--exec sp_lcc_dropifexists 'lcc_data_qlik_percentiles_BigCities_step2'
--exec sp_lcc_dropifexists 'lcc_data_qlik_percentiles_MainHighwaysQlik_step2'
--exec sp_lcc_dropifexists 'lcc_data_qlik_percentiles_SmallerCitiesQlik_step2'




--select SUM(num_tests) from [QLIK].dbo._RI_Data_Completed_Qlik 
--where entity LIKE '%A6%' and meas_tech = 'Road 4G' and mnc = 07
--and test_type = 'CE_DL' and last_measurement_vdf IN (1,2,3,4)