USE [master]
GO
/****** Object:  StoredProcedure [dbo].[sp_lcc_create_DashBoard_DATA_STATISTICS_LATENCY_MD]    Script Date: 20/06/2017 13:12:42 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER procedure [dbo].[sp_lcc_create_DashBoard_DATA_STATISTICS_LATENCY_MD] 
	@database as varchar(256)
	,@sheetTech as varchar(256)
	,@nameSheet as varchar(256)
as

-------------------------------------------------------------------------------
-- Declaración de variables
--declare @database as varchar(256) = '[AGGRData4G]'
--declare @sheetTech as varchar(256)	= ' ' -- or '_CE' '_NC' '_NC_LTE'
--declare @nameSheet as varchar(256) = '4G'
--declare @LA as bit=1

DECLARE @SQLString nvarchar(4000)


declare @table_modif as varchar(256)
--declare @LAfilter as varchar(256)

--if @la = 1 set @LAfilter =' not like ''%LA%'' and a.entorno in (''8G'',''32G'')' 
--else set @LAfilter= 'like ''%%'' or a.entorno is null'

set @database= replace(replace(@database,'[',''),']','')

declare @table as varchar(256) = 'UPDATE_'+@database+'_lcc_aggr_sp_MDD_Data_Ping'+@sheetTech
-------------------------------------------------------------------------------
-- Filtrado previo de la tabla
set @SQLString=N'
				exec dashboard.dbo.sp_lcc_dropifexists '''+@table+'_step1''
				select a.* 
				into [DASHBOARD].[dbo].['+@table+'_step1]
				from [DASHBOARD].[dbo].['+@table+'] a'

EXECUTE sp_executesql @SQLString

set @table_modif = @table+'_step1'

-------------------------------------------------------------------------------
-- Llamadas a los procedimientos de cálculos de estadísticos

-- Cálculo de la mediana
exec [dbo].[sp_lcc_create_DashBoard_STATISTICS_MEDIAN] '[DASHBOARD]',@sheetTech,@table_modif,5,41,0,'Ms',1
set @SQLString=N'
				exec dashboard.dbo.sp_lcc_dropifexists ''lcc_Statistics_Data_MEDIAN_'+@nameSheet+'''
				select * 
				into [DASHBOARD].[dbo].[lcc_Statistics_Data_MEDIAN_'+@nameSheet+']
				from [DASHBOARD].[dbo].[lcc_Statistics_MEDIAN_'+@sheetTech+']
				'
EXECUTE sp_executesql @SQLString

-------------------------------------------------------------------------------
-- Limpieza de tablas
set @SQLString=N'
				exec dashboard.dbo.sp_lcc_dropifexists '''+@table+'_step1''
				'
EXECUTE sp_executesql @SQLString
