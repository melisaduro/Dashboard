USE [master]
GO
/****** Object:  StoredProcedure [dbo].[sp_lcc_create_DashBoard_DATA_STATISTICS_PERCENTILES_SCOPE_NEW_Report]    Script Date: 13/11/2017 10:13:19 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER procedure [dbo].[sp_lcc_create_DashBoard_DATA_STATISTICS_PERCENTILES_SCOPE_NEW_Report] 
	@database as varchar(256)
	,@sheetTech as varchar(256)
	,@scope as varchar(256)
	,@LAfilter as varchar(2000)
	,@report as varchar(256)
as


--PDTE!!!!!!!!!!!!!!!!
--Modificar:
-- [sp_lcc_create_DashBoard_STATISTICS_PERCENTIL]   por   [sp_lcc_create_DashBoard_STATISTICS_PERCENTIL_Antiguo]
-- [sp_lcc_create_DashBoard_STATISTICS_PERCENTIL_NEW]   por   [sp_lcc_create_DashBoard_STATISTICS_PERCENTIL]

-------------------------------------------------------------------------------
-- Declaración de variables
--declare @database as varchar(256) = '[AGGRData4G]'
--declare @sheetTech as varchar(256)	= ''--'_RAILWAY' -- or '_CE' '_NC' '_NC_LTE'
--declare @scope as varchar(256) = 'PLACES OF CONCENTRATION'--'RAILWAYS'--'MAIN CITIES'
--declare @LAfilter as varchar(2000)='(a.entorno like ''%%'' or a.entorno is null) and (a.entidad not like ''alicante'' and a.entidad not like ''sevilla'' and a.entidad not like ''barcelona'')'--'a.entorno  not like ''%LA%'' and a.entorno in (''8G'',''32G'')'
--declare @report as varchar(256) = 'VDF'

DECLARE @SQLString nvarchar(4000)
declare @table as varchar(256)
declare @tableScope as varchar(256)
declare @Tech as varchar(256)
declare @typedata as varchar(256)
declare @nameSheet as varchar(256)
declare @start_range float
declare @Last_range float
declare @step_old float
declare @N_ranges_old float
declare @step_new float
declare @N_ranges_new float
declare @it int
--declare @LAfilter as varchar(256)

if @database= '[AGGRData4G]' or @database= '[AGGRData4G_ROAD]'
	begin
		set @tech='_LTE'
		set @typedata='4G'
	end
else 
	begin
		set @tech=''
		set @typedata='3G'
	end

--if @LA = 1 set @LAfilter =' not like ''%LA%'' and a.entorno in (''8G'',''32G'')' 
--else set @LAfilter= 'like ''%%'' or a.entorno is null'

set @database= replace(replace(@database,'[',''),']','')

-------------------------------------------------------------------------------
-- Tablas sobre las que hay que calcular los percentiles
exec dashboard.dbo.sp_lcc_dropifexists 'lcc_dashboard_TablesPercentiles'
create table [Dashboard].[dbo].[lcc_dashboard_TablesPercentiles](
	Tablename varchar(4000)
	,id int
	,typeTable varchar(256)
	,typedata varchar(256)	
	,start_range float	
	,Last_range bit
	,step_old float
	,N_ranges_old float
	,step_new float
	,N_ranges_new float
)

SET @SQLString =N'
		insert into Dashboard.dbo.lcc_dashboard_TablesPercentiles
		values 
			(''UPDATE_'+@database+'_lcc_aggr_sp_MDD_Data_DL_Thput_CE'+@tech+@sheetTech+''',1,''DL_CE'',''4G'',0,1,5,31,2,51)		-- Data_DL_Thput_CE para estadísticos
			,(''UPDATE_'+@database+'_lcc_aggr_sp_MDD_Data_UL_Thput_CE'+@tech+@sheetTech+''',2,''UL_CE'',''4G'',0,1,5,11,0.5,51)	-- Data_UL_Thput_CE para estadísticos
			,(''UPDATE_'+@database+'_lcc_aggr_sp_MDD_Data_DL_Thput_NC'+@tech+@sheetTech+''',3,''DL_NC'',''4G'',0,1,5,31,3.5,57)	-- Data_DL_Thput_NC para estadísticos
			,(''UPDATE_'+@database+'_lcc_aggr_sp_MDD_Data_UL_Thput_NC'+@tech+@sheetTech+''',4,''UL_NC'',''4G'',0,1,5,11,0.8,66)	-- Data_UL_Thput_NC para estadísticos
			
			,(''UPDATE_'+@database+'_lcc_aggr_sp_MDD_Data_DL_Thput_CE'+@tech+@sheetTech+''',1,''DL_CE'',''3G'',0,1,1,33,0.75,45)	-- Data_DL_Thput_CE para estadísticos
			,(''UPDATE_'+@database+'_lcc_aggr_sp_MDD_Data_UL_Thput_CE'+@tech+@sheetTech+''',2,''UL_CE'',''3G'',0,1,0.5,11,0.25,21)	-- Data_UL_Thput_CE para estadísticos
			,(''UPDATE_'+@database+'_lcc_aggr_sp_MDD_Data_DL_Thput_NC'+@tech+@sheetTech+''',3,''DL_NC'',''3G'',0,1,1,33,0.75,45)	-- Data_DL_Thput_NC para estadísticos
			,(''UPDATE_'+@database+'_lcc_aggr_sp_MDD_Data_UL_Thput_NC'+@tech+@sheetTech+''',4,''UL_NC'',''3G'',0,1,0.5,11,0.25,21)	-- Data_UL_Thput_NC para estadísticos'
EXECUTE sp_executesql @SQLString

--select * from Dashboard.dbo.lcc_dashboard_TablesPercentiles

-------------------------------------------------------------------------------
print '-------------------------------------------------------------------------------'
print 'Bucle de percentiles por SCOPE'
print '-------------------------------------------------------------------------------'
set @it = 1
while (@it <= (SELECT max(id) FROM [Dashboard].[dbo].[lcc_dashboard_TablesPercentiles] where typedata=@typedata))
begin 
	set @table =(select tableName from [Dashboard].[dbo].[lcc_dashboard_TablesPercentiles] where id = @it and typedata=@typedata)
	print 'Calculos de: '+@table
	set @start_range =(select start_range from [Dashboard].[dbo].[lcc_dashboard_TablesPercentiles] where id = @it and typedata=@typedata)
	set @Last_range =(select Last_range from [Dashboard].[dbo].[lcc_dashboard_TablesPercentiles] where id = @it and typedata=@typedata)
	set @nameSheet =(select typeTable from [Dashboard].[dbo].[lcc_dashboard_TablesPercentiles] where id = @it and typedata=@typedata)
	set @N_ranges_old =(select N_ranges_old from [Dashboard].[dbo].[lcc_dashboard_TablesPercentiles] where id = @it and typedata=@typedata)
	set @step_old =(select step_old from [Dashboard].[dbo].[lcc_dashboard_TablesPercentiles] where id = @it and typedata=@typedata)
	set @N_ranges_new =(select N_ranges_new from [Dashboard].[dbo].[lcc_dashboard_TablesPercentiles] where id = @it and typedata=@typedata)
	set @step_new =(select step_new from [Dashboard].[dbo].[lcc_dashboard_TablesPercentiles] where id = @it and typedata=@typedata)
	
	-------------------------------------------------------------------------------
	-- Filtrado previo de la tabla (sólo filtra por LA)
	set @SQLString=N'
					exec dashboard.dbo.sp_lcc_dropifexists '''+@table+'_tempStats''
					select a.* 
					into [DASHBOARD].[dbo].['+@table+'_tempStats]
					from [DASHBOARD].[dbo].['+@table+'] a
					where  ' + @LAfilter
	EXECUTE sp_executesql @SQLString

	-- Modificación de las tablas para seleccionar correctamente la/s entidad/es sobre la/s que agrupar (scope)
	set @SQLString=N'
					exec dashboard.dbo.sp_lcc_dropifexists '''+@table+'_step1''
					select a.* 
					into [DASHBOARD].[dbo].'+@table+'_step1
					from [DASHBOARD].[dbo].['+@table+'_tempStats] a
						,[DASHBOARD].[dbo].lcc_entities_dashboard_temp b
					where a.entidad=b.entidad and a.mnc=b.mnc and a.meas_date=b.meas_date
					alter table [DASHBOARD].[dbo].'+@table+'_step1 drop column entidad, Meas_date

					exec dashboard.dbo.sp_lcc_dropifexists '''+@table+'_step2''
					select *, '''+@scope+''' as entidad, ''RW'' as Meas_date 
					into [DASHBOARD].[dbo].'+@table+'_step2
					from [DASHBOARD].[dbo].'+@table+'_step1
					exec dashboard.dbo.sp_lcc_dropifexists '''+@table+'_tempStats'''
	EXECUTE sp_executesql @SQLString

	-- Cálculo previo de la tabla, para discernir si todas las entidades del scope tienen rangos nuevos agregados o no
	set @SQLString=N'
					exec dashboard.dbo.sp_lcc_dropifexists '''+@table+'_step3''
					select mnc,Meas_Date,entidad
						,sum(case when [ 0-'+convert(varchar,@step_new)+'Mbps_N] is null then 1 else 0 end) as ''Cuenta_nulos''
					into [DASHBOARD].[dbo].'+@table+'_step3
					from [DASHBOARD].[dbo].'+@table+'_step2 a
					group by mnc,Meas_Date,entidad'
	EXECUTE sp_executesql @SQLString

	-------------------------------------------------------------------------------------------
	------ Llamadas a los procedimientos de cálculos de estadísticos con RANGOS ANTIGUOS ------
	-------------------------------------------------------------------------------------------

	-- Filtrado previo de la tabla
	set @SQLString=N'
					exec dashboard.dbo.sp_lcc_dropifexists '''+@table+'_step4''
					select a.* 
					into [DASHBOARD].[dbo].['+@table+'_step4]
					from [DASHBOARD].[dbo].'+@table+'_step2 a
						inner join [DASHBOARD].[dbo].['+@table+'_step3] b
						on a.mnc=b.mnc and a.Meas_Date=b.Meas_Date and a.entidad=b.entidad and Cuenta_nulos>0'
	EXECUTE sp_executesql @SQLString

	-- Llamadas a los procedimientos de cálculos de estadísticos
	set @tableScope=@table+'_step4'

	-- Percentil P90
	exec [dbo].[sp_lcc_create_DashBoard_STATISTICS_PERCENTIL] '[DASHBOARD]','',@tableScope,@step_old,@N_ranges_old,@start_range,'Mbps',0.90,@Last_range
	set @SQLString=N'
					exec dashboard.dbo.sp_lcc_dropifexists ''lcc_PERCENTILP90_Mbps''
					select entidad,mnc,meas_date,Percentil as P_90
					into [DASHBOARD].[dbo].[lcc_PERCENTILP90_Mbps]
					from [DASHBOARD].[dbo].[lcc_PERCENTIL]'
	EXECUTE sp_executesql @SQLString

	-- Percentil P10
	exec [dbo].[sp_lcc_create_DashBoard_STATISTICS_PERCENTIL] '[DASHBOARD]','',@tableScope,@step_old,@N_ranges_old,@start_range,'Mbps',0.10,@Last_range
	set @SQLString=N'
					exec dashboard.dbo.sp_lcc_dropifexists ''lcc_PERCENTILP10_Mbps''
					select entidad,mnc,meas_date,Percentil as P_10
					into [DASHBOARD].[dbo].[lcc_PERCENTILP10_Mbps]
					from [DASHBOARD].[dbo].[lcc_PERCENTIL]'
	EXECUTE sp_executesql @SQLString

	--------- Creación de la tabla para almacenar todos los percentiles calculados 
	set @SQLString=N'
					exec dashboard.dbo.sp_lcc_dropifexists ''lcc_Statistics_Data_'+@nameSheet+'_step1''
					select distinct a.entidad,a.mnc,a.meas_date
					into [DASHBOARD].[dbo].[lcc_Statistics_Data_'+@nameSheet+'_step1]
					from [DASHBOARD].[dbo].['+@tableScope+'] a
						
					exec dashboard.dbo.sp_lcc_dropifexists ''lcc_Statistics_Data_'+@nameSheet+'''
					select a.entidad,a.mnc,a.meas_date
							,b.P_90*1000 as P90,c.P_10*1000 as P10
					into [DASHBOARD].[dbo].[lcc_Statistics_Data_'+@nameSheet+']
					from [DASHBOARD].[dbo].[lcc_Statistics_Data_'+@nameSheet+'_step1] a
						left outer join [DASHBOARD].[dbo].[lcc_PERCENTILP90_Mbps] b
							on a.entidad=b.entidad and a.mnc=b.mnc and a.meas_date=b.meas_date
						left outer join [DASHBOARD].[dbo].[lcc_PERCENTILP10_Mbps] c
							on a.entidad=c.entidad and a.mnc=c.mnc and a.meas_date=c.meas_date'
	EXECUTE sp_executesql @SQLString 
		
	-------------------------------------------------------------------------------------------
	------ Llamadas a los procedimientos de cálculos de estadísticos con RANGOS NUEVOS ------
	-------------------------------------------------------------------------------------------

	-- Filtrado previo de la tabla
	set @SQLString=N'
					exec dashboard.dbo.sp_lcc_dropifexists '''+@table+'_step4''
					select a.* 
					into [DASHBOARD].[dbo].['+@table+'_step4]
					from [DASHBOARD].[dbo].'+@table+'_step2 a
						inner join [DASHBOARD].[dbo].['+@table+'_step3] b
						on a.mnc=b.mnc and a.Meas_Date=b.Meas_Date and a.entidad=b.entidad and Cuenta_nulos<=0'
	EXECUTE sp_executesql @SQLString

	-- Llamadas a los procedimientos de cálculos de estadísticos
	set @tableScope=@table+'_step4'

	-- Percentil P90
	exec [dbo].[sp_lcc_create_DashBoard_STATISTICS_PERCENTIL_NEW] '[DASHBOARD]','',@tableScope,@step_new,@N_ranges_new,@start_range,'Mbps_N',0.90,@Last_range
	set @SQLString=N'
					IF  EXISTS (	SELECT * FROM [DASHBOARD].sys.objects 
								WHERE object_id = OBJECT_ID(N''[DASHBOARD].[dbo].[lcc_PERCENTILP90_Mbps]'') 
								AND type in (N''U'')
							)
							insert into [DASHBOARD].[dbo].lcc_PERCENTILP90_Mbps
							select entidad,mnc,meas_date,Percentil as P_90
							from [DASHBOARD].[dbo].[lcc_PERCENTIL]
						else 
							select entidad,mnc,meas_date,Percentil as P_90
							into [DASHBOARD].[dbo].[lcc_PERCENTILP90_Mbps]
							from [DASHBOARD].[dbo].[lcc_PERCENTIL]
					'
	EXECUTE sp_executesql @SQLString

	-- Percentil P10
	exec [dbo].[sp_lcc_create_DashBoard_STATISTICS_PERCENTIL_NEW] '[DASHBOARD]','',@tableScope,@step_new,@N_ranges_new,@start_range,'Mbps_N',0.10,@Last_range
	set @SQLString=N'
					IF  EXISTS (	SELECT * FROM [DASHBOARD].sys.objects 
								WHERE object_id = OBJECT_ID(N''[DASHBOARD].[dbo].[lcc_PERCENTILP10_Mbps]'') 
								AND type in (N''U'')
							)
							insert into [DASHBOARD].[dbo].lcc_PERCENTILP10_Mbps
							select entidad,mnc,meas_date,Percentil as P_10
							from [DASHBOARD].[dbo].[lcc_PERCENTIL]
						else 
							select entidad,mnc,meas_date,Percentil as P_10
							into [DASHBOARD].[dbo].[lcc_PERCENTILP10_Mbps]
							from [DASHBOARD].[dbo].[lcc_PERCENTIL]
						'
	EXECUTE sp_executesql @SQLString
	
	---------- Creación de la tabla para almacenar todos los percentiles calculados 
	set @SQLString=N'
					exec dashboard.dbo.sp_lcc_dropifexists ''lcc_Statistics_Data_'+@nameSheet+'_step1''
					select distinct a.entidad,a.mnc,a.meas_date
					into [DASHBOARD].[dbo].[lcc_Statistics_Data_'+@nameSheet+'_step1]
					from [DASHBOARD].[dbo].['+@tableScope+'] a
					
					IF  EXISTS (	SELECT * FROM [DASHBOARD].sys.objects 
								WHERE object_id = OBJECT_ID(N''[DASHBOARD].[dbo].[lcc_Statistics_Data_'+@nameSheet+']'') 
								AND type in (N''U'')
							)
							insert into [DASHBOARD].[dbo].[lcc_Statistics_Data_'+@nameSheet+']
							select a.entidad,a.mnc,a.meas_date
								,b.P_90*1000 as P90,c.P_10*1000 as P10							
							from [DASHBOARD].[dbo].[lcc_Statistics_Data_'+@nameSheet+'_step1] a
								left outer join [DASHBOARD].[dbo].[lcc_PERCENTILP90_Mbps] b
									on a.entidad=b.entidad and a.mnc=b.mnc and a.meas_date=b.meas_date
								left outer join [DASHBOARD].[dbo].[lcc_PERCENTILP10_Mbps] c
									on a.entidad=c.entidad and a.mnc=c.mnc and a.meas_date=c.meas_date
					else
						select a.entidad,a.mnc,a.meas_date
							,b.P_90*1000 as P90,c.P_10*1000 as P10
						into [DASHBOARD].[dbo].[lcc_Statistics_Data_'+@nameSheet+']
						from [DASHBOARD].[dbo].[lcc_Statistics_Data_'+@nameSheet+'_step1] a
							left outer join [DASHBOARD].[dbo].[lcc_PERCENTILP90_Mbps] b
								on a.entidad=b.entidad and a.mnc=b.mnc and a.meas_date=b.meas_date
							left outer join [DASHBOARD].[dbo].[lcc_PERCENTILP10_Mbps] c
								on a.entidad=c.entidad and a.mnc=c.mnc and a.meas_date=c.meas_date
					'
	EXECUTE sp_executesql @SQLString 

	-------------------------------------------------------------------------------
	-- Limpieza de tablas temporales del bucle
	-------------------------------------------------------------------------------
	set @SQLString=N'
					exec dashboard.dbo.sp_lcc_dropifexists ''lcc_Statistics_Data_'+@nameSheet+'_step1''' +
					' exec dashboard.dbo.sp_lcc_dropifexists ''lcc_PERCENTILP90_Mbps'''+
					' exec dashboard.dbo.sp_lcc_dropifexists ''lcc_PERCENTILP10_Mbps'''+
					' exec dashboard.dbo.sp_lcc_dropifexists '''+@table+'_step1'''+
					' exec dashboard.dbo.sp_lcc_dropifexists '''+@table+'_step2'''+
					' exec dashboard.dbo.sp_lcc_dropifexists '''+@table+'_step3'''+
					' exec dashboard.dbo.sp_lcc_dropifexists '''+@table+'_step4''
						'
	EXECUTE sp_executesql @SQLString

	set @it=@it+1
end

-------------------------------------------------------------------------------
-- Unión de las tablas temporales
set @SQLString=N'
				exec dashboard.dbo.sp_lcc_dropifexists ''lcc_Statistics_Data_Percentiles_Scope_1''
				select a.entidad,a.mnc,a.Meas_date
					,a.P90 as P90_DL_CE,a.P10 as P10_DL_CE
					,c.P90 as P90_UL_CE,c.P10 as P10_UL_CE
					,d.P90 as P90_DL_NC,d.P10 as P10_DL_NC
					,e.P90 as P90_UL_NC,e.P10 as P10_UL_NC
				into [DASHBOARD].[dbo].[lcc_Statistics_Data_Percentiles_Scope_1]
				from [DASHBOARD].[dbo].[lcc_Statistics_Data_DL_CE] a
					left outer join [DASHBOARD].[dbo].[lcc_Statistics_Data_UL_CE] c
					on a.entidad=c.entidad and a.mnc=c.mnc and a.Meas_date=c.Meas_date
					left outer join [DASHBOARD].[dbo].[lcc_Statistics_Data_DL_NC] d
					on a.entidad=d.entidad and a.mnc=d.mnc and a.Meas_date=d.Meas_date
					left outer join [DASHBOARD].[dbo].[lcc_Statistics_Data_UL_NC] e
					on a.entidad=e.entidad and a.mnc=e.mnc and a.Meas_date=e.Meas_date'
EXECUTE sp_executesql @SQLString

-------------------------------------------------------------------------------
-- Limpieza de tablas temporales
exec dashboard.dbo.sp_lcc_dropifexists 'lcc_Statistics_Data_DL_CE'
exec dashboard.dbo.sp_lcc_dropifexists 'lcc_Statistics_Data_UL_CE' 
exec dashboard.dbo.sp_lcc_dropifexists 'lcc_Statistics_Data_DL_NC'
exec dashboard.dbo.sp_lcc_dropifexists 'lcc_Statistics_Data_UL_NC'

-------------------------------------------------------------------------------
-- Cálculo de la mediana para el caso de MAIN y SMALLER CITIES (agrupación de ambos scopes para obtener la mediana de las 32G) 
if @scope like 'MAIN CITIES' or @scope like 'SMALLER CITIES'
begin 
	print '-------------------------------------------------------------------------------'
	print 'Bucle de percentiles por MC+SC'
	print '-------------------------------------------------------------------------------'
	set @it = 1
	while (@it <= (SELECT max(id) FROM [Dashboard].[dbo].[lcc_dashboard_TablesPercentiles] where typedata=@typedata))
	begin 
		set @table =(select tableName from [Dashboard].[dbo].[lcc_dashboard_TablesPercentiles] where id = @it and typedata=@typedata)
		print 'Calculos de: '+@table
		set @start_range =(select start_range from [Dashboard].[dbo].[lcc_dashboard_TablesPercentiles] where id = @it and typedata=@typedata)
		set @Last_range =(select Last_range from [Dashboard].[dbo].[lcc_dashboard_TablesPercentiles] where id = @it and typedata=@typedata)
		set @nameSheet =(select typeTable from [Dashboard].[dbo].[lcc_dashboard_TablesPercentiles] where id = @it and typedata=@typedata)
		set @N_ranges_old =(select N_ranges_old from [Dashboard].[dbo].[lcc_dashboard_TablesPercentiles] where id = @it and typedata=@typedata)
		set @step_old =(select step_old from [Dashboard].[dbo].[lcc_dashboard_TablesPercentiles] where id = @it and typedata=@typedata)
		set @N_ranges_new =(select N_ranges_new from [Dashboard].[dbo].[lcc_dashboard_TablesPercentiles] where id = @it and typedata=@typedata)
		set @step_new =(select step_new from [Dashboard].[dbo].[lcc_dashboard_TablesPercentiles] where id = @it and typedata=@typedata)
	
		-------------------------------------------------------------------------------
		-- Filtrado previo de la tabla (sólo filtra por LA)
		set @SQLString=N'
					exec dashboard.dbo.sp_lcc_dropifexists '''+@table+'_tempStats''
					select a.* 
					into [DASHBOARD].[dbo].['+@table+'_tempStats]
					from [DASHBOARD].[dbo].['+@table+'] a
					where ' + @LAfilter
		EXECUTE sp_executesql @SQLString

		-- Selección de las entidades Main y Smaller (para que en lcc_entities_dashboard esten listadas MC+ SC)
		exec [dbo].[sp_lcc_create_Dashboard_Entities_NEW_Report] @scope,'[DASHBOARD]',@table,1,@report

		-- Modificación de las tablas para seleccionar correctamente la/s entidad/es sobre la/s que agrupar (scope)
		set @SQLString=N'
						exec dashboard.dbo.sp_lcc_dropifexists '''+@table+'_step1''
						select a.* 
						into [DASHBOARD].[dbo].'+@table+'_step1
						from [DASHBOARD].[dbo].['+@table+'_tempStats] a
							,[DASHBOARD].[dbo].lcc_entities_dashboard b
						where a.entidad=b.entidad and a.mnc=b.mnc and a.meas_date=b.meas_date
						alter table [DASHBOARD].[dbo].'+@table+'_step1 drop column entidad, Meas_date

						exec dashboard.dbo.sp_lcc_dropifexists '''+@table+'_step2''
						select *, '''+@scope+''' as entidad, ''RW'' as Meas_date 
						into [DASHBOARD].[dbo].'+@table+'_step2
						from [DASHBOARD].[dbo].'+@table+'_step1
						drop table [DASHBOARD].[dbo].['+@table+'_tempStats]'
		EXECUTE sp_executesql @SQLString

		-- Cálculo previo de la tabla, para discernir si todas las entidades del scope tienen rangos nuevos agregados o no
		set @SQLString=N'
						exec dashboard.dbo.sp_lcc_dropifexists '''+@table+'_step3''
						select mnc,Meas_Date,entidad
							,sum(case when [ 0-'+convert(varchar,@step_new)+'Mbps_N] is null then 1 else 0 end) as ''Cuenta_nulos''
						into [DASHBOARD].[dbo].'+@table+'_step3
						from [DASHBOARD].[dbo].'+@table+'_step2 a
						group by mnc,Meas_Date,entidad'
		EXECUTE sp_executesql @SQLString

		-------------------------------------------------------------------------------------------
		------ Llamadas a los procedimientos de cálculos de estadísticos con RANGOS ANTIGUOS ------
		-------------------------------------------------------------------------------------------
		-- Filtrado previo de la tabla
		set @SQLString=N'
						exec dashboard.dbo.sp_lcc_dropifexists '''+@table+'_step4''
						select a.* 
						into [DASHBOARD].[dbo].['+@table+'_step4]
						from [DASHBOARD].[dbo].'+@table+'_step2 a
							inner join [DASHBOARD].[dbo].['+@table+'_step3] b
							on a.mnc=b.mnc and a.Meas_Date=b.Meas_Date and a.entidad=b.entidad and Cuenta_nulos>0'
		EXECUTE sp_executesql @SQLString
		
		-- Llamadas a los procedimientos de cálculos de estadísticos
		set @tableScope=@table+'_step4'

		-- Percentil P90
		exec [dbo].[sp_lcc_create_DashBoard_STATISTICS_PERCENTIL] '[DASHBOARD]','',@tableScope,@step_old,@N_ranges_old,@start_range,'Mbps',0.90,@Last_range
		set @SQLString=N'
						exec dashboard.dbo.sp_lcc_dropifexists ''lcc_PERCENTILP90_Mbps''
						select entidad,mnc,meas_date,Percentil as P_90
						into [DASHBOARD].[dbo].[lcc_PERCENTILP90_Mbps]
						from [DASHBOARD].[dbo].[lcc_PERCENTIL]'
		EXECUTE sp_executesql @SQLString

		-- Percentil P10
		exec [dbo].[sp_lcc_create_DashBoard_STATISTICS_PERCENTIL] '[DASHBOARD]','',@tableScope,@step_old,@N_ranges_old,@start_range,'Mbps',0.10,@Last_range
		set @SQLString=N'
						exec dashboard.dbo.sp_lcc_dropifexists ''lcc_PERCENTILP10_Mbps''
						select entidad,mnc,meas_date,Percentil as P_10
						into [DASHBOARD].[dbo].[lcc_PERCENTILP10_Mbps]
						from [DASHBOARD].[dbo].[lcc_PERCENTIL]'
		EXECUTE sp_executesql @SQLString

		-- Creación de la tabla para almacenar todos los percentiles calculados
		set @SQLString=N'
						exec dashboard.dbo.sp_lcc_dropifexists ''lcc_Statistics_Data_'+@nameSheet+'_step1''
						select distinct a.entidad,a.mnc,a.meas_date
						into [DASHBOARD].[dbo].[lcc_Statistics_Data_'+@nameSheet+'_step1]
						from [DASHBOARD].[dbo].['+@tableScope+'] a
						
						exec dashboard.dbo.sp_lcc_dropifexists ''lcc_Statistics_Data_'+@nameSheet+'''
						select a.entidad,a.mnc,a.meas_date
								,b.P_90*1000 as P90,c.P_10*1000 as P10
						into [DASHBOARD].[dbo].[lcc_Statistics_Data_'+@nameSheet+']
						from [DASHBOARD].[dbo].[lcc_Statistics_Data_'+@nameSheet+'_step1] a
							left outer join [DASHBOARD].[dbo].[lcc_PERCENTILP90_Mbps] b
							on a.entidad=b.entidad and a.mnc=b.mnc and a.meas_date=b.meas_date
							left outer join [DASHBOARD].[dbo].[lcc_PERCENTILP10_Mbps] c
							on a.entidad=c.entidad and a.mnc=c.mnc and a.meas_date=c.meas_date'
		EXECUTE sp_executesql @SQLString 

		-------------------------------------------------------------------------------------------
		------ Llamadas a los procedimientos de cálculos de estadísticos con RANGOS NUEVOS ------
		-------------------------------------------------------------------------------------------

		-- Filtrado previo de la tabla
		set @SQLString=N'
						exec dashboard.dbo.sp_lcc_dropifexists '''+@table+'_step4''
						select a.* 
						into [DASHBOARD].[dbo].['+@table+'_step4]
						from [DASHBOARD].[dbo].'+@table+'_step2 a
							inner join [DASHBOARD].[dbo].['+@table+'_step3] b
							on a.mnc=b.mnc and a.Meas_Date=b.Meas_Date and a.entidad=b.entidad and Cuenta_nulos<=0'
		EXECUTE sp_executesql @SQLString

		-- Llamadas a los procedimientos de cálculos de estadísticos
		set @tableScope=@table+'_step4'

		-- Percentil P90
		exec [dbo].[sp_lcc_create_DashBoard_STATISTICS_PERCENTIL_NEW] '[DASHBOARD]','',@tableScope,@step_new,@N_ranges_new,@start_range,'Mbps_N',0.90,@Last_range
		set @SQLString=N'
						IF  EXISTS (	SELECT * FROM [DASHBOARD].sys.objects 
								WHERE object_id = OBJECT_ID(N''[DASHBOARD].[dbo].[lcc_PERCENTILP90_Mbps]'') 
								AND type in (N''U'')
							)
							insert into [DASHBOARD].[dbo].lcc_PERCENTILP90_Mbps
							select entidad,mnc,meas_date,Percentil as P_90
							from [DASHBOARD].[dbo].[lcc_PERCENTIL]
						else 
							select entidad,mnc,meas_date,Percentil as P_90
							into [DASHBOARD].[dbo].[lcc_PERCENTILP90_Mbps]
							from [DASHBOARD].[dbo].[lcc_PERCENTIL]
						'
		EXECUTE sp_executesql @SQLString

		-- Percentil P10
		exec [dbo].[sp_lcc_create_DashBoard_STATISTICS_PERCENTIL_NEW] '[DASHBOARD]','',@tableScope,@step_new,@N_ranges_new,@start_range,'Mbps_N',0.10,@Last_range
		set @SQLString=N'
						IF  EXISTS (	SELECT * FROM [DASHBOARD].sys.objects 
								WHERE object_id = OBJECT_ID(N''[DASHBOARD].[dbo].[lcc_PERCENTILP10_Mbps]'') 
								AND type in (N''U'')
							)
							insert into [DASHBOARD].[dbo].lcc_PERCENTILP10_Mbps
							select entidad,mnc,meas_date,Percentil as P_10
							from [DASHBOARD].[dbo].[lcc_PERCENTIL]
						else 
							select entidad,mnc,meas_date,Percentil as P_10
							into [DASHBOARD].[dbo].[lcc_PERCENTILP10_Mbps]
							from [DASHBOARD].[dbo].[lcc_PERCENTIL]
						'
		EXECUTE sp_executesql @SQLString

		-- Creación de la tabla para almacenar todos los percentiles calculados
		set @SQLString=N'
						exec dashboard.dbo.sp_lcc_dropifexists ''lcc_Statistics_Data_'+@nameSheet+'_step1''
						select distinct a.entidad,a.mnc,a.meas_date
						into [DASHBOARD].[dbo].[lcc_Statistics_Data_'+@nameSheet+'_step1]
						from [DASHBOARD].[dbo].['+@tableScope+'] a
						
						
						IF  EXISTS (	SELECT * FROM [DASHBOARD].sys.objects 
								WHERE object_id = OBJECT_ID(N''[DASHBOARD].[dbo].[lcc_Statistics_Data_'+@nameSheet+']'') 
								AND type in (N''U'')
							)
							insert into [DASHBOARD].[dbo].[lcc_Statistics_Data_'+@nameSheet+']
							select a.entidad,a.mnc,a.meas_date
									,b.P_90*1000 as P90,c.P_10*1000 as P10							
							from [DASHBOARD].[dbo].[lcc_Statistics_Data_'+@nameSheet+'_step1] a
								left outer join [DASHBOARD].[dbo].[lcc_PERCENTILP90_Mbps] b
								on a.entidad=b.entidad and a.mnc=b.mnc and a.meas_date=b.meas_date
								left outer join [DASHBOARD].[dbo].[lcc_PERCENTILP10_Mbps] c
								on a.entidad=c.entidad and a.mnc=c.mnc and a.meas_date=c.meas_date
						else
							select a.entidad,a.mnc,a.meas_date
									,b.P_90*1000 as P90,c.P_10*1000 as P10
							into [DASHBOARD].[dbo].[lcc_Statistics_Data_'+@nameSheet+']
							from [DASHBOARD].[dbo].[lcc_Statistics_Data_'+@nameSheet+'_step1] a
								left outer join [DASHBOARD].[dbo].[lcc_PERCENTILP90_Mbps] b
								on a.entidad=b.entidad and a.mnc=b.mnc and a.meas_date=b.meas_date
								left outer join [DASHBOARD].[dbo].[lcc_PERCENTILP10_Mbps] c
								on a.entidad=c.entidad and a.mnc=c.mnc and a.meas_date=c.meas_date'
		EXECUTE sp_executesql @SQLString 


		-------------------------------------------------------------------------------
		-- Limpieza de tablas temporales del bucle
		-------------------------------------------------------------------------------
		set @SQLString=N'
						exec dashboard.dbo.sp_lcc_dropifexists ''lcc_Statistics_Data_'+@nameSheet+'_step1''' +
						' exec dashboard.dbo.sp_lcc_dropifexists ''lcc_PERCENTILP90_Mbps''' +
						' exec dashboard.dbo.sp_lcc_dropifexists ''lcc_PERCENTILP10_Mbps''' +
						' exec dashboard.dbo.sp_lcc_dropifexists '''+@table+'_step1'''+
						' exec dashboard.dbo.sp_lcc_dropifexists '''+@table+'_step2'''+
						' exec dashboard.dbo.sp_lcc_dropifexists '''+@table+'_step3'''+
						' exec dashboard.dbo.sp_lcc_dropifexists '''+@table+'_step4''
							'
		EXECUTE sp_executesql @SQLString
		set @it=@it+1
	end
	-------------------------------------------------------------------------------
	-- Unión de las tablas temporales
	set @SQLString=N'
					exec dashboard.dbo.sp_lcc_dropifexists ''lcc_Statistics_Data_Percentiles_Scope_2''
					select a.entidad,a.mnc,a.Meas_date
						,a.P90 as P90_DL_CE_MS,a.P10 as P10_DL_CE_MS
						,c.P90 as P90_UL_CE_MS,c.P10 as P10_UL_CE_MS
						,d.P90 as P90_DL_NC_MS,d.P10 as P10_DL_NC_MS
						,e.P90 as P90_UL_NC_MS,e.P10 as P10_UL_NC_MS
					into [DASHBOARD].[dbo].[lcc_Statistics_Data_Percentiles_Scope_2]
					from [DASHBOARD].[dbo].[lcc_Statistics_Data_DL_CE] a
						left outer join [DASHBOARD].[dbo].[lcc_Statistics_Data_UL_CE] c
						on a.entidad=c.entidad and a.mnc=c.mnc and a.Meas_date=c.Meas_date
						left outer join [DASHBOARD].[dbo].[lcc_Statistics_Data_DL_NC] d
						on a.entidad=d.entidad and a.mnc=d.mnc and a.Meas_date=d.Meas_date
						left outer join [DASHBOARD].[dbo].[lcc_Statistics_Data_UL_NC] e
						on a.entidad=e.entidad and a.mnc=e.mnc and a.Meas_date=e.Meas_date'
	EXECUTE sp_executesql @SQLString

	-- Almacenamiento de todos los resultados en la tabla final
	set @SQLString=N'
					exec dashboard.dbo.sp_lcc_dropifexists ''lcc_Statistics_Data_Percentiles_Scope''
					select a.*,b.P90_DL_CE_MS,b.P10_DL_CE_MS
						,b.P90_UL_CE_MS,b.P10_UL_CE_MS
						,b.P90_DL_NC_MS,b.P10_DL_NC_MS
						,b.P90_UL_NC_MS,b.P10_UL_NC_MS
					into [DASHBOARD].[dbo].[lcc_Statistics_Data_Percentiles_Scope]
					from [DASHBOARD].[dbo].[lcc_Statistics_Data_Percentiles_Scope_1] a
						,[DASHBOARD].[dbo].[lcc_Statistics_Data_Percentiles_Scope_2] b
						where a.entidad=b.entidad and a.mnc=b.mnc and a.Meas_Date=b.Meas_date'
	EXECUTE sp_executesql @SQLString

	-------------------------------------------------------------------------------
	-- Limpieza de tablas temporales
	exec dashboard.dbo.sp_lcc_dropifexists 'lcc_Statistics_Data_DL_CE'
	exec dashboard.dbo.sp_lcc_dropifexists 'lcc_Statistics_Data_UL_CE' 
	exec dashboard.dbo.sp_lcc_dropifexists 'lcc_Statistics_Data_DL_NC'
	exec dashboard.dbo.sp_lcc_dropifexists 'lcc_Statistics_Data_UL_NC' 
	exec dashboard.dbo.sp_lcc_dropifexists 'lcc_Statistics_Data_Percentiles_Scope_2'
end
else 
begin 
	-- Almacenamiento de todos los resultados en la tabla final
	set @SQLString=N'
					exec dashboard.dbo.sp_lcc_dropifexists ''lcc_Statistics_Data_Percentiles_Scope''
					select a.*, '''' as P90_DL_CE_MS, '''' as P10_DL_CE_MS
						, '''' as P90_UL_CE_MS, '''' as P10_UL_CE_MS
						, '''' as P90_DL_NC_MS, '''' as P10_DL_NC_MS
						, '''' as P90_UL_NC_MS, '''' as P10_UL_NC_MS
					into [DASHBOARD].[dbo].[lcc_Statistics_Data_Percentiles_Scope]
					from [DASHBOARD].[dbo].[lcc_Statistics_Data_Percentiles_Scope_1] a'
	EXECUTE sp_executesql @SQLString
end

-------------------------------------------------------------------------------
-- Limpieza de tablas temporales
exec dashboard.dbo.sp_lcc_dropifexists 'lcc_dashboard_TablesPercentiles'
exec dashboard.dbo.sp_lcc_dropifexists 'lcc_Statistics_Data_Percentiles_Scope_1'

