USE [AddedValue]
GO
/****** Object:  StoredProcedure [dbo].[plcc_data_statistics_new]    Script Date: 21/03/2018 13:01:19 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


ALTER PROCEDURE [dbo].[plcc_data_statistics_new_Williams]

	@last_measurement as varchar(256)
AS

-----------------------------
----- Testing Variables -----
-----------------------------
--declare @last_measurement as varchar(256)='last_measurement_osp' --= 'last_measurement_osp'
-----------------------------

declare @idm as varchar (10)
declare @idt as varchar (10)
declare @testtype as varchar(40)
declare @tech as varchar(40)
declare @selectRangos as varchar(4000)=''
declare @filtroReport as varchar(256)
declare @it as int=1
declare @cruceRangos as varchar(256)=''
declare @insertRangos as varchar(256)=''
declare @condicion as varchar (4000)
declare @step as varchar(256)
declare @N_ranges varchar(256)


set @condicion = 'meas_tech in (''4G'',''4GOnly'')'


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
truncate table _Percentiles_N
truncate table _Percentiles_O


--Borramos las tablas antes de empezar a trabajar

exec sp_lcc_dropifexists 'lcc_data_qlik_percentiles_Entidades_step1'
exec sp_lcc_dropifexists 'lcc_data_qlik_percentiles_Roads_Last_step1'
exec sp_lcc_dropifexists 'lcc_data_qlik_percentiles_Scope_step1'
exec sp_lcc_dropifexists 'lcc_data_qlik_percentiles_BigCities_step1'
exec sp_lcc_dropifexists 'lcc_data_qlik_percentiles_MainHighwaysQlik_step1'
exec sp_lcc_dropifexists 'lcc_data_qlik_percentiles_SmallerCitiesQlik_step1'


print '-----------------------------------------------------------------------------'
print 'PASO 1: Calculo información con o sin rangos nuevos' 
print '-----------------------------------------------------------------------------'

-- Calcula entidades con o sin nuevos rangos
exec ('
select [entity],[mnc],Test_type,meas_Tech
	,sum(case when [1_N] is null then 1 else 0 end) as ''Cuenta_nulos''
into lcc_data_qlik_percentiles_Entidades_step1
from [QLIK].dbo._RI_Data_Completed_Qlik
	inner join [DASHBOARD].dbo._Entidades_Semanal on entity = entidades 
where ' +@last_measurement+ ' > 0 and '+@condicion+' and report='''+@filtroReport+''' and scope like ''%WILLIAMS%''
group by [entity],[mnc],Test_type,meas_Tech')


-- Calcula scopes con o sin nuevos rangos
exec ('
select p2.entidades as Scope,[mnc],Test_type,meas_Tech
	,sum(case when [1_N] is null then 1 else 0 end) as ''Cuenta_nulos''
into lcc_data_qlik_percentiles_Scope_step1
from [QLIK].dbo._RI_Data_Completed_Qlik t1
	inner join [DASHBOARD].dbo._Entidades_Semanal p2 on scope = entidades 
where ' +@last_measurement+ ' > 0 and Num_tests is not null and '+@condicion+' and report='''+@filtroReport+''' and scope like ''%WILLIAMS%''
group by p2.entidades,[mnc],Test_type,meas_Tech

union all

--le añadimos el ping posteriormente ya que se van con la condición de ''Num_test is not null''
select p2.entidades as scope,[mnc],Test_type,meas_Tech
	,sum(case when [1_N] is null then 1 else 0 end) as ''Cuenta_nulos''
from [QLIK].dbo._RI_Data_Completed_Qlik t1
	inner join [DASHBOARD].dbo._Entidades_Semanal p2 on scope  = entidades
where ' +@last_measurement+ ' > 0 and test_type = ''Ping'' and '+@condicion+' and report='''+@filtroReport+''' and scope like ''%WILLIAMS%''
group by p2.entidades,[mnc],Test_type,meas_Tech')


-----------------------------------------------------------------------------
-----------------------------------------------------------------------------

--Creamos una tabla con todos los tipos de testtype que tenemos
select distinct(test_type), row_number() over(order by test_type) as id
into #testtype 
from [QLIK].dbo._RI_Data_Completed_Qlik 
where (test_type not like 'Web%' and test_type not like 'Youtube%') 
group by test_type

--Creamos una tabla con todas las tecnologías con las que queremos trabajar
select distinct(meas_tech), row_number() over(order by meas_tech) as id
into #meastech
from [QLIK].dbo._RI_Data_Completed_Qlik where (meas_tech in ('4G','4GOnly'))
group by meas_tech


--Recorremos los tipos de rangos que tenemos (@it=1--OLD/@it=2--NEW)

while @it <= 2
begin 

	 if @it=1 --Rangos antiguos
		begin
			print 'Calculo percentiles con RANGOS ANTIGUOS'
			print '---------------------------------------'
			--set @selectRangos= 'sum([1]),sum([2]),sum([3]),sum([4]),sum([5]),sum([6]),sum([7]),sum([8]),sum([9]),sum([10]),sum([11]),sum([12]),sum([13]),sum([14]),sum([15]),sum([16]),sum([17]),sum([18]),sum([19]),sum([20]),sum([21]),sum([22]),sum([23]),sum([24]),sum([25]),sum([26]),sum([27]),sum([28]),sum([29]),sum([30]),sum([31]),sum([32]),sum([33]),sum([34]),sum([35]),sum([36]),sum([37]),sum([38]),sum([39]),sum([40]),sum([41])'
			set @selectRangos='sum([1]) as [1],sum([2]) as [2],sum([3]) as [3],sum([4]) as [4],sum([5]) as [5],sum([6]) as [6],sum([7]) as [7],sum([8]) as [8],sum([9]) as [9],sum([10]) as [10],sum([11]) as [11],sum([12]) as [12],sum([13]) as [13],sum([14]) as [14],sum([15]) as [15],sum([16]) as [16],sum([17]) as [17],sum([18]) as [18],sum([19]) as [19],sum([20]) as [20],sum([21]) as [21],sum([22]) as [22],sum([23]) as [23],sum([24]) as [24],sum([25]) as [25],sum([26]) as [26],sum([27]) as [27],sum([28]) as [28],sum([29]) as [29],sum([30]) as [30],sum([31]) as [31],sum([32]) as [32],sum([33]) as [33],sum([34]) as [34],sum([35]) as [35],sum([36]) as [36],sum([37]) as [37],sum([38]) as [38],sum([39]) as [39],sum([40]) as [40],sum([41]) as [41],null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null'
			set @cruceRangos='Cuenta_nulos>0'
			set @insertRangos='[_Percentiles_O]'
		 end
	 else if @it=2 --Rangos nuevos
		begin
			print 'Calculo percentiles con RANGOS NUEVOS'
			print '-------------------------------------'
			--set @selectRangos= 'sum([1_N]),sum([2_N]),sum([3_N]),sum([4_N]),sum([5_N]),sum([6_N]),sum([7_N]),sum([8_N]),sum([9_N]),sum([10_N]),sum([11_N]),sum([12_N]),sum([13_N]),sum([14_N]),sum([15_N]),sum([16_N]),sum([17_N]),sum([18_N]),sum([19_N]),sum([20_N]),sum([21_N]),sum([22_N]),sum([23_N]),sum([24_N]),sum([25_N]),sum([26_N]),sum([27_N]),sum([28_N]),sum([29_N]),sum([30_N]),sum([31_N]),sum([32_N]),sum([33_N]),sum([34_N]),sum([35_N]),sum([36_N]),sum([37_N]),sum([38_N]),sum([39_N]),sum([40_N]),sum([41_N]),sum([42_N]),sum([43_N]),sum([44_N]),sum([45_N]),sum([46_N]),sum([47_N]),sum([48_N]),sum([49_N]),sum([50_N]),sum([51_N]),sum([52_N]),sum([53_N]),sum([54_N]),sum([55_N]),sum([56_N]),sum([57_N]),sum([58_N]),sum([59_N]),sum([60_N]),sum([61_N]),sum([62_N]),sum([63_N]),sum([64_N]),sum([65_N]),sum([66_N])'
			set @selectRangos= 'sum([1_N]) as [1_N],sum([2_N]) as [2_N],sum([3_N]) as [3_N],sum([4_N]) as [4_N],sum([5_N]) as [5_N],sum([6_N]) as [6_N],sum([7_N]) as [7_N],sum([8_N]) as [8_N],sum([9_N]) as [9_N],sum([10_N]) as [10_N],sum([11_N]) as [11_N],sum([12_N]) as [12_N],sum([13_N]) as [13_N],sum([14_N]) as [14_N],sum([15_N]) as [15_N],sum([16_N]) as [16_N],sum([17_N]) as [17_N],sum([18_N]) as [18_N],sum([19_N]) as [19_N],sum([20_N]) as [20_N],sum([21_N]) as [21_N],sum([22_N]) as [22_N],sum([23_N]) as [23_N],sum([24_N]) as [24_N],sum([25_N]) as [25_N],sum([26_N]) as [26_N],sum([27_N]) as [27_N],sum([28_N]) as [28_N],sum([29_N]) as [29_N],sum([30_N]) as [30_N],sum([31_N]) as [31_N],sum([32_N]) as [32_N],sum([33_N]) as [33_N],sum([34_N]) as [34_N],sum([35_N]) as [35_N],sum([36_N]) as [36_N],sum([37_N]) as [37_N],sum([38_N]) as [38_N],sum([39_N]) as [39_N],sum([40_N]) as [40_N],sum([41_N]) as [41_N],sum([42_N]) as [42_N],sum([43_N]) as [43_N],sum([44_N]) as [44_N],sum([45_N]) as [45_N],sum([46_N]) as [46_N],sum([47_N]) as [47_N],sum([48_N]) as [48_N],sum([49_N]) as [49_N],sum([50_N]) as [50_N],sum([51_N]) as [51_N],sum([52_N]) as [52_N],sum([53_N]) as [53_N],sum([54_N]) as [54_N],sum([55_N]) as [55_N],sum([56_N]) as [56_N],sum([57_N]) as [57_N],sum([58_N]) as [58_N],sum([59_N]) as [59_N],sum([60_N]) as [60_N],sum([61_N]) as [61_N],sum([62_N]) as [62_N],sum([63_N]) as [63_N],sum([64_N]) as [64_N],sum([65_N]) as [65_N],sum([66_N]) as [66_N]'
			set @cruceRangos='Cuenta_nulos=0'
			set @insertRangos='[_Percentiles_N]'
		 end

		exec sp_lcc_dropifexists 'lcc_data_qlik_percentiles_Entidades_step2'
		exec sp_lcc_dropifexists 'lcc_data_qlik_percentiles_Roads_Last_step2'
		exec sp_lcc_dropifexists 'lcc_data_qlik_percentiles_Scope_step2'
		exec sp_lcc_dropifexists 'lcc_data_qlik_percentiles_BigCities_step2'
		exec sp_lcc_dropifexists 'lcc_data_qlik_percentiles_MainHighwaysQlik_step2'
		exec sp_lcc_dropifexists 'lcc_data_qlik_percentiles_SmallerCitiesQlik_step2'

		-- Info entidades con o sin nuevos rangos
		exec ('select *
		into lcc_data_qlik_percentiles_Entidades_step2
		from lcc_data_qlik_percentiles_Entidades_step1
		where ' +@cruceRangos)


		-- Info scopes con o sin nuevos rangos
		exec ('select *
		into lcc_data_qlik_percentiles_Scope_step2
		from lcc_data_qlik_percentiles_Scope_step1
		where ' +@cruceRangos)


set @tech = (select meas_tech from #meastech where id = 1)  -- Inicializamos la vb
set @idm = 1

		--Recorremos cada una de las tecnologías que tenemos

		

		While @tech <> ''
		begin
  
		  set @testtype = (select test_type from #testtype where id = 1) -- Inicializamos la vb
		  set @idt = 1

				  --Recorremos cada uno de los TestTypes que tenemos

				  While @testtype <> ''
				  begin
	
						--Entidades y acumulado de aves-roads
						exec ('truncate table '+@insertRangos)
						exec ('insert into '+@insertRangos+'
						select t1.[entity],t1.[mnc],max(t1.[Meas_date]),'''+@filtroReport+''',t1.Test_type,t1.meas_Tech,
							'+@selectRangos+'
						from [QLIK].dbo._RI_Data_Completed_Qlik t1
							inner join lcc_data_qlik_percentiles_Entidades_step2 t2
								on t1.[entity]=t2.[entity] and t1.[mnc]=t2.[mnc] and t1.Test_type=t2.Test_type and t1.meas_Tech=t2.meas_Tech
						where t1.' +@last_measurement+ ' > 0
							and t1.Test_type = '''+@testtype+''' and t1.meas_Tech = '''+@tech+'''
						group by t1.[entity],t1.[mnc],t1.Test_type,t1.meas_Tech')

					
						--Acumulado scope

						exec ('insert into '+@insertRangos+'
						select Case when t2.scope like ''%EXTRA%'' then LEFT(t2.scope,len(t2.scope)-5) else t2.scope end as entity,t1.[mnc],'''','''+@filtroReport+''',t1.Test_type,t1.meas_Tech,
							'+@selectRangos+'
						from [QLIK].dbo._RI_Data_Completed_Qlik t1
							inner join [AGRIDS].[dbo].[vlcc_dashboard_info_scopes_NEW] t2
								on entity=entities_bbdd and t2.report='''+@filtroReport+'''
							inner join lcc_data_qlik_percentiles_Scope_step2 t3
								on t3.[scope]=t2.[scope] and t1.[mnc]=t3.[mnc] and t1.Test_type=t3.Test_type and t1.meas_Tech=t3.meas_Tech
						where t1.' +@last_measurement+ ' > 0
							and t1.Test_type = '''+@testtype+''' and t1.meas_Tech = '''+@tech+'''
						group by Case when t2.scope like ''%EXTRA%'' then LEFT(t2.scope,len(t2.scope)-5) else t2.scope end,t1.[mnc],t1.Test_type,t1.meas_Tech')

						
					If @it = 1
						Begin

						set @step = (Select value from Rangos_PercentilesDatos where technology = @tech and testtype = @testtype and type= 'Step_old')
						set @N_ranges = (Select value from Rangos_PercentilesDatos where technology = @tech and testtype = @testtype and type= 'N_ranges_old')
	

								exec sp_lcc_create_STATISTICS_PERCENTIL_QLIK_DASH '_Percentiles_O',@step,@N_ranges,0,0.9
								exec sp_lcc_create_STATISTICS_PERCENTIL_QLIK_DASH '_Percentiles_O',@step,@N_ranges,0,0.1

								exec sp_lcc_create_STATISTICS_STDV_QLIK_DASH '_Percentiles_O',@step,@N_ranges,0
						end
					Else
						Begin

						set @step = (Select value from Rangos_PercentilesDatos where technology = @tech and testtype = @testtype and type= 'step_new')
						set @N_ranges = (Select value from Rangos_PercentilesDatos where technology = @tech and testtype = @testtype and type= 'N_ranges_new')
	

								exec sp_lcc_create_STATISTICS_PERCENTIL_NEW_QLIK_DASH '_Percentiles_N',@step,@N_ranges,0,0.9
								exec sp_lcc_create_STATISTICS_PERCENTIL_NEW_QLIK_DASH '_Percentiles_N',@step,@N_ranges,0,0.1

								exec sp_lcc_create_STATISTICS_STDV_NEW_QLIK_DASH '_Percentiles_N',@step,@N_ranges,0
						End



					set @idt = @idt+1
					set @testtype = (select test_type from #testtype where id = @idt)
					print (@testtype)

    
				  end

		set @idm = @idm+1
		set @tech = (select meas_tech from #meastech where id = @idm)
		PRINT(@tech)
		end

   set @it=@it+1
end


-- Update a las tablas que contienen todas las entidades 

--drop table TablaPercentilDatos
--select * into TablaPercentilDatos_backup from TablaPercentilDatos

-- 1.Percentiles
delete TablaPercentilDatos_Williams
from TablaPercentilDatos_Williams p,
	_Resultados_Percentiles r
where p.entidad=r.entidad
	and p.mnc = r.mnc
	and p.test_type = r.test_type
	and p.meas_tech = r.meas_tech
	and p.Percentil = r.Percentil
	and p.Report_Qlik = r.Report_Qlik

-- Añadimos la ciudad que no tuviésemos en el histórico.
insert into TablaPercentilDatos_Williams
select *
from  _Resultados_Percentiles


-- 2.Desviación Estándar

--drop table TablaSTDDatos_backup
--select * into TablaSTDDatos_backup from TablaSTDDatos

delete TablaSTDDatos_Williams
from TablaSTDDatos_Williams p,
	_Resultados_STDV r
where p.entidad=r.entidad
	and p.mnc = r.mnc
	and p.test_type = r.test_type
	and p.meas_tech = r.meas_tech
	and p.Report_Qlik = r.Report_Qlik
-- Añadimos la ciudad que no tuviésemos en el histórico.
insert into TablaSTDDatos_Williams
select *
from  _Resultados_STDV 


-- Borramos las tablas temporales

drop table #testtype,#meastech





--select * into TablaSTDDatos from _Resultados_STDV
--select * from _Resultados_Percentiles where entidad = 'ADD-ON CITIES' and meas_tech = '3G' AND MNC = 01 AND TEST_TYPE = 'CE_DL'

--select * from [DASHBOARD].dbo._Entidades_Semanal
--select * from [QLIK].dbo._RI_voice_Completed_Qlik where entity like '%AVE-Madrid-Sevilla%' and report_type = 'osp' and operator = 'orange' and Round = 'R6'