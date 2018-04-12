USE [master]
GO
/****** Object:  StoredProcedure [dbo].[sp_lcc_create_DashBoard_DATA_STATISTICS_LATENCY_SCOPE]    Script Date: 29/05/2017 14:01:08 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER procedure [dbo].[sp_lcc_create_DashBoard_DATA_STATISTICS_LATENCY_SCOPE] 
	@database as varchar(256)
	,@sheetTech as varchar(256)
	,@scope as varchar(256)
	,@LAfilter as varchar(2000)
as

-------------------------------------------------------------------------------
-- Declaración de variables
--declare @database as varchar(256) = '[AGGRData4G]'
--declare @sheetTech as varchar(256)	= '' -- or '_CE' '_NC' '_NC_LTE'
--declare @scope as varchar(256) ='MAIN CITIES'
--declare @LA as bit=0

DECLARE @SQLString nvarchar(4000)
declare @table1 as varchar(256)
declare @tableScopes as varchar(256)
--declare @LAfilter as varchar(256)

set @database= replace(replace(@database,'[',''),']','')

set @tableScopes ='UPDATE_'+@database+'_lcc_aggr_sp_MDD_Data_Ping'+@sheetTech

set @table1 = @tableScopes+'_step2'

--if @LA = 1 set @LAfilter =' not like ''%LA%'' and a.entorno in (''8G'',''32G'')' 
--else set @LAfilter= 'like ''%%'' or a.entorno is null'

-------------------------------------------------------------------------------
-- Filtrado previo de la tabla
set @SQLString=N'
				exec dashboard.dbo.sp_lcc_dropifexists '''+@tableScopes+'_tempStats''
				select a.* 
				into [DASHBOARD].[dbo].['+@tableScopes+'_tempStats]
				from [DASHBOARD].[dbo].['+@tableScopes+'] a
				where ' + @LAfilter
EXECUTE sp_executesql @SQLString

-------------------------------------------------------------------------------
-- Modificación de las tablas para seleccionar correctamente la/s entidad/es sobre la/s que agrupar (scope)

-- Modificación de la tabla para considerar como entidad el scope
set @SQLString=N'
				exec dashboard.dbo.sp_lcc_dropifexists '''+@tableScopes+'_step1''
				select a.* 
				into [DASHBOARD].[dbo].'+@tableScopes+'_step1
				from [DASHBOARD].[dbo].['+@tableScopes+'_tempStats] a
					,[DASHBOARD].[dbo].lcc_entities_dashboard_temp b
				where a.entidad=b.entidad and a.Meas_date=b.Meas_date and a.mnc=b.mnc
				alter table [DASHBOARD].[dbo].'+@tableScopes+'_step1 drop column entidad, Meas_date

				exec dashboard.dbo.sp_lcc_dropifexists '''+@tableScopes+'_step2''
				select *, '''+@scope+''' as entidad, ''RW'' as Meas_date 
				into [DASHBOARD].[dbo].'+@tableScopes+'_step2
				from [DASHBOARD].[dbo].'+@tableScopes+'_step1'

EXECUTE sp_executesql @SQLString

-------------------------------------------------------------------------------
-- Llamadas a los procedimientos de cálculos de estadísticos

-------------------------------------------------------------------------------
-- Cálculo de la mediana por scope

exec [dbo].[sp_lcc_create_DashBoard_STATISTICS_MEDIAN] '[DASHBOARD]','',@table1,5,41,0,'Ms',1

-- Almacenamiento de los resultados en una tabla temporal
set @SQLString=N'
				exec dashboard.dbo.sp_lcc_dropifexists ''lcc_Statistics_Data_MEDIAN_1''
				select * 
				into [DASHBOARD].[dbo].[lcc_Statistics_Data_MEDIAN_1]
				from [DASHBOARD].[dbo].[lcc_Statistics_MEDIAN_]'
EXECUTE sp_executesql @SQLString

-- Limpieza de tablas temporales
set @SQLString=N'
				exec dashboard.dbo.sp_lcc_dropifexists '''+@tableScopes+'_step1''' + 
				' exec dashboard.dbo.sp_lcc_dropifexists '''+@tableScopes+'_step2'''
EXECUTE sp_executesql @SQLString

-------------------------------------------------------------------------------
-- Cálculo de la mediana para el caso de MAIN y SMALLER CITIES (agrupación de ambos scopes para obtener la mediana de las 32G) 
if @scope like 'MAIN CITIES' or @scope like 'SMALLER CITIES'
begin 
	print @scope
	-- Selección de las entidades Main y Smaller
	exec [dbo].[sp_lcc_create_Dashboard_Entities] @scope,'[DASHBOARD]',@tableScopes,1

	-- Modificación de la tabla para considerar como entidad los scopes Main&Smaller (32G)
	set @SQLString=N'
					exec dashboard.dbo.sp_lcc_dropifexists '''+@tableScopes+'_step1''
					select a.* 
					into [DASHBOARD].[dbo].'+@tableScopes+'_step1
					from [DASHBOARD].[dbo].['+@tableScopes+'_tempStats] a
						,[DASHBOARD].[dbo].lcc_entities_dashboard b
					where a.entidad=b.entidad and a.Meas_date=b.Meas_date and a.mnc=b.mnc
					alter table [DASHBOARD].[dbo].'+@tableScopes+'_step1 drop column entidad, Meas_date

					exec dashboard.dbo.sp_lcc_dropifexists '''+@tableScopes+'_step2''
					select *, ''MainSmaller'' as entidad, ''RW'' as Meas_date 
					into [DASHBOARD].[dbo].'+@tableScopes+'_step2
					from [DASHBOARD].[dbo].'+@tableScopes+'_step1'

	EXECUTE sp_executesql @SQLString
	
	--Cálculo de la mediana por scope (Main&Smaller)
	exec [dbo].[sp_lcc_create_DashBoard_STATISTICS_MEDIAN] '[DASHBOARD]','',@table1,5,41,0,'Ms',1
	
	-- Almacenamiento de los resultados en una tabla temporal
	set @SQLString=N'
					exec dashboard.dbo.sp_lcc_dropifexists ''lcc_Statistics_Data_MEDIAN_2''
					select * 
					into [DASHBOARD].[dbo].[lcc_Statistics_Data_MEDIAN_2]
					from [DASHBOARD].[dbo].[lcc_Statistics_MEDIAN_]'
	EXECUTE sp_executesql @SQLString

	-- Almacenamiento de todos los resultados en la tabla final
	set @SQLString=N'
					exec dashboard.dbo.sp_lcc_dropifexists ''lcc_Statistics_Data_MEDIAN_Scope''
					select a.mnc,a.Median as Median_Scope, b.Median as Median_MS 
					into [DASHBOARD].[dbo].[lcc_Statistics_Data_MEDIAN_Scope]
					from [DASHBOARD].[dbo].[lcc_Statistics_Data_MEDIAN_1] a,
							[DASHBOARD].[dbo].[lcc_Statistics_Data_MEDIAN_2] b
					where a.mnc=b.mnc'

	EXECUTE sp_executesql @SQLString
	
	--Limpieza de tablas temporales
	set @SQLString=N'
					exec dashboard.dbo.sp_lcc_dropifexists '''+@tableScopes+'_step2''' +
					' exec dashboard.dbo.sp_lcc_dropifexists '''+@tableScopes+'_step1'''
	EXECUTE sp_executesql @SQLString
					
end
else 
begin 
	-- Almacenamiento de todos los resultados en la tabla final
	set @SQLString=N'
					exec dashboard.dbo.sp_lcc_dropifexists ''lcc_Statistics_Data_MEDIAN_Scope''
					select a.mnc,a.Median as Median_Scope,'''' as Median_MS
					into [DASHBOARD].[dbo].[lcc_Statistics_Data_MEDIAN_Scope]
					from [DASHBOARD].[dbo].[lcc_Statistics_Data_MEDIAN_1] a'
	EXECUTE sp_executesql @SQLString
end

-- Limpieza de tablas
set @SQLString=N' exec dashboard.dbo.sp_lcc_dropifexists '''+@tableScopes+'_tempStats'''
EXECUTE sp_executesql @SQLString