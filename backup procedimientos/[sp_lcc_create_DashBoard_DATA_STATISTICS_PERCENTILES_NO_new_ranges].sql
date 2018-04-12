USE [master]
GO
/****** Object:  StoredProcedure [dbo].[sp_lcc_create_DashBoard_DATA_STATISTICS_PERCENTILES_NO_new_ranges]    Script Date: 29/05/2017 14:03:28 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER procedure [dbo].[sp_lcc_create_DashBoard_DATA_STATISTICS_PERCENTILES_NO_new_ranges] 
	@sheetTech as varchar(256)
	,@table as varchar(256)
	,@step as float
	,@N_ranges as int
	,@nameSheet as varchar(256)
	,@LAfilter as varchar(2000)
as

-------------------------------------------------------------------------------
-- Declaración de variables
--declare @sheetTech as varchar(256)	= '' -- or '_CE' '_NC' '_NC_LTE'
--declare @table as varchar(256) = 'lcc_aggr_sp_MDD_Data_DL_Thput_CE_LTE'
--declare @step int=5
--declare @N_ranges int=31
--declare @nameSheet as varchar(256) = '4G'
--declare @LA as bit=1

declare @table_modif as varchar(256)
--declare @LAfilter as varchar(256)
DECLARE @SQLString nvarchar(4000)

--if @LA = 1 set @LAfilter =' not like ''%LA%'' and a.entorno in (''8G'',''32G'')' 
--else set @LAfilter= 'like ''%%'' or a.entorno is null'

-------------------------------------------------------------------------------
-- Filtrado previo de la tabla
set @SQLString=N'
				exec dashboard.dbo.sp_lcc_dropifexists '''+@table+'_step1''
				select a.* 
				into [DASHBOARD].[dbo].['+@table+'_step1]
				from [DASHBOARD].[dbo].['+@table+'] a
				where  ' + @LAfilter
EXECUTE sp_executesql @SQLString

set @table_modif = @table+'_step1'

-------------------------------------------------------------------------------
-- Llamadas a los procedimientos de cálculos de estadísticos

-- Desviación típica
exec [dbo].[sp_lcc_create_DashBoard_STATISTICS_STDV] '[DASHBOARD]',@sheetTech,@table_modif,@step,@N_ranges,'Mbps',0,1

-- Percentil P90
exec [dbo].[sp_lcc_create_DashBoard_STATISTICS_PERCENTIL] '[DASHBOARD]',@sheetTech,@table_modif,@step,@N_ranges,0,'Mbps',0.90,1
set @SQLString=N'
				exec dashboard.dbo.sp_lcc_dropifexists ''lcc_PERCENTIL' + @sheetTech +'P90_Mbps''
				select entidad,mnc,meas_date,Percentil as P_90
				into [DASHBOARD].[dbo].[lcc_PERCENTIL' + @sheetTech +'P90_Mbps]
				from [DASHBOARD].[dbo].[lcc_PERCENTIL' + @sheetTech +']'
EXECUTE sp_executesql @SQLString

-- Percentil P10
exec [dbo].[sp_lcc_create_DashBoard_STATISTICS_PERCENTIL] '[DASHBOARD]',@sheetTech,@table_modif,@step,@N_ranges,0,'Mbps',0.10,1
set @SQLString=N'
				exec dashboard.dbo.sp_lcc_dropifexists ''lcc_PERCENTIL' + @sheetTech +'P10_Mbps''
				select entidad,mnc,meas_date,Percentil as P_10
				into [DASHBOARD].[dbo].[lcc_PERCENTIL' + @sheetTech +'P10_Mbps]
				from [DASHBOARD].[dbo].[lcc_PERCENTIL' + @sheetTech +']'
EXECUTE sp_executesql @SQLString


-------------------------------------------------------------------------------
-- Creación de la tabla para almacenar todos los percentiles calculados
set @SQLString=N'
				exec dashboard.dbo.sp_lcc_dropifexists ''lcc_Statistics_Data_'+@nameSheet+'_step1''
				select distinct a.entidad,a.mnc,a.meas_date
				into [DASHBOARD].[dbo].[lcc_Statistics_Data_'+@nameSheet+'_step1]
				from [DASHBOARD].[dbo].['+@table+'_step1] a

				exec dashboard.dbo.sp_lcc_dropifexists ''lcc_Statistics_Data_'+@nameSheet+'''
				select a.entidad,a.mnc,a.meas_date
						,b.P_90*1000 as P90,c.P_10*1000 as P10,1000*d.DESV as DESV_TH
				into [DASHBOARD].[dbo].[lcc_Statistics_Data_'+@nameSheet+']
				from [DASHBOARD].[dbo].[lcc_Statistics_Data_'+@nameSheet+'_step1] a
					left outer join [DASHBOARD].[dbo].[lcc_PERCENTIL' + @sheetTech +'P90_Mbps] b
					on a.entidad=b.entidad and a.mnc=b.mnc and a.meas_date=b.meas_date
					left outer join [DASHBOARD].[dbo].[lcc_PERCENTIL' + @sheetTech +'P10_Mbps] c
					on a.entidad=c.entidad and a.mnc=c.mnc and a.meas_date=c.meas_date
					left outer join [DASHBOARD].[dbo].[lcc_STDV' + @sheetTech +'] d
					on a.entidad=d.entidad and a.mnc=d.mnc and a.meas_date=d.meas_date
					'
EXECUTE sp_executesql @SQLString 

-------------------------------------------------------------------------------
-- Limpieza de tablas temporales
set @SQLString=N'
				exec dashboard.dbo.sp_lcc_dropifexists ''lcc_Statistics_Data_'+@nameSheet+'_step1''' +
				' exec dashboard.dbo.sp_lcc_dropifexists ''lcc_PERCENTIL' + @sheetTech +'P90_Mbps''' +
				' exec dashboard.dbo.sp_lcc_dropifexists ''lcc_PERCENTIL' + @sheetTech +'P10_Mbps''' +
				' exec dashboard.dbo.sp_lcc_dropifexists '''+@table+'_step1'''
EXECUTE sp_executesql @SQLString


