USE [master]
GO
/****** Object:  StoredProcedure [dbo].[sp_lcc_create_DashBoard_VOICE_STATISTICS_CST_MD]    Script Date: 20/06/2017 13:10:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER procedure [dbo].[sp_lcc_create_DashBoard_VOICE_STATISTICS_CST_MD] 
	@sheetTech varchar(256)
	,@table varchar(256)
as

-------------------------------------------------------------------------------
-- Declaración de variables
--declare @sheetTech as varchar(256)	= '' -- or '_4G'
--declare @table as varchar(256) = 'lcc_aggr_sp_MDD_Voice_CallSetupTime_CompletedCalls'

DECLARE @SQLString nvarchar(4000)

declare @table_modif as varchar(256)
--declare @LAfilter as varchar(256)

--if @la = 1 set @LAfilter =' not like ''%LA%'' and a.entorno in (''8G'',''32G'')' 
--else set @LAfilter= 'like ''%%'' or a.entorno is null'

-------------------------------------------------------------------------------
-- Filtrado previo de la tabla
set @SQLString=N'
				exec dashboard.dbo.sp_lcc_dropifexists '''+@table+'_step1''
				select a.* 
				into [DASHBOARD].[dbo].['+@table+'_step1]
				from [DASHBOARD].[dbo].['+@table+'] a'

EXECUTE sp_executesql @SQLString

set @table_modif = @table+'_step1'

----------------------------------------------------------------------------
-- Cálculo de los diferentes percentiles para CST
-- CST_95TH_MO_ALERTING
exec [dbo].[sp_lcc_create_DashBoard_STATISTICS_PERCENTIL] '[DASHBOARD]',@sheetTech,@table_modif,0.5,41,0,'MO_Alert',0.95,1
set @SQLString=N'
				exec dashboard.dbo.sp_lcc_dropifexists ''lcc_PERCENTIL' + @sheetTech +'_MO_Alert''
				select entidad,mnc,meas_date,Percentil as P_95_MO_Alert
				into [DASHBOARD].[dbo].[lcc_PERCENTIL' + @sheetTech +'_MO_Alert]
				from [DASHBOARD].[dbo].[lcc_PERCENTIL' + @sheetTech +']'
EXECUTE sp_executesql @SQLString

-- CST_95TH_MT_ALERTING
exec [dbo].[sp_lcc_create_DashBoard_STATISTICS_PERCENTIL] '[DASHBOARD]',@sheetTech,@table_modif,0.5,41,0,'MT_Alert',0.95,1
set @SQLString=N'
				exec dashboard.dbo.sp_lcc_dropifexists ''lcc_PERCENTIL' + @sheetTech +'_MT_Alert''
				select entidad,mnc,meas_date,Percentil as P_95_MT_Alert
				into [DASHBOARD].[dbo].[lcc_PERCENTIL' + @sheetTech +'_MT_Alert]
				from [DASHBOARD].[dbo].[lcc_PERCENTIL' + @sheetTech +']'
EXECUTE sp_executesql @SQLString

-- CST_95TH_ALERTING
exec [dbo].[sp_lcc_create_DashBoard_STATISTICS_PERCENTIL] '[DASHBOARD]',@sheetTech,@table_modif,0.5,41,0,'MOMT_Alert',0.95,1
set @SQLString=N'
				exec dashboard.dbo.sp_lcc_dropifexists ''lcc_PERCENTIL' + @sheetTech +'_MOMT_Alert''
				select entidad,mnc,meas_date,Percentil as P_95_MOMT_Alert
				into [DASHBOARD].[dbo].[lcc_PERCENTIL' + @sheetTech +'_MOMT_Alert]
				from [DASHBOARD].[dbo].[lcc_PERCENTIL' + @sheetTech +']'
EXECUTE sp_executesql @SQLString

-- CST_95TH_MO_CONNECT
exec [dbo].[sp_lcc_create_DashBoard_STATISTICS_PERCENTIL] '[DASHBOARD]',@sheetTech,@table_modif,0.5,41,0,'MO_Conn',0.95,1
set @SQLString=N'
				exec dashboard.dbo.sp_lcc_dropifexists ''lcc_PERCENTIL' + @sheetTech +'_MO_Conn''
				select entidad,mnc,meas_date,Percentil as P_95_MO_Conn
				into [DASHBOARD].[dbo].[lcc_PERCENTIL' + @sheetTech +'_MO_Conn]
				from [DASHBOARD].[dbo].[lcc_PERCENTIL' + @sheetTech +']'
EXECUTE sp_executesql @SQLString

-- CST_95TH_MT_CONNECT
exec [dbo].[sp_lcc_create_DashBoard_STATISTICS_PERCENTIL] '[DASHBOARD]',@sheetTech,@table_modif,0.5,41,0,'MT_Conn',0.95,1
set @SQLString=N'
				exec dashboard.dbo.sp_lcc_dropifexists ''lcc_PERCENTIL' + @sheetTech +'_MT_Conn''
				select entidad,mnc,meas_date,Percentil as P_95_MT_Conn
				into [DASHBOARD].[dbo].[lcc_PERCENTIL' + @sheetTech +'_MT_Conn]
				from [DASHBOARD].[dbo].[lcc_PERCENTIL' + @sheetTech +']'
EXECUTE sp_executesql @SQLString

-- CST_95TH_CONNECT
exec [dbo].[sp_lcc_create_DashBoard_STATISTICS_PERCENTIL] '[DASHBOARD]',@sheetTech,@table_modif,0.5,41,0,'MOMT_Conn',0.95,1
set @SQLString=N'
				exec dashboard.dbo.sp_lcc_dropifexists ''lcc_PERCENTIL' + @sheetTech +'_MOMT_Conn''
				select entidad,mnc,meas_date,Percentil as P_95_MOMT_Conn
				into [DASHBOARD].[dbo].[lcc_PERCENTIL' + @sheetTech +'_MOMT_Conn]
				from [DASHBOARD].[dbo].[lcc_PERCENTIL' + @sheetTech +']'
EXECUTE sp_executesql @SQLString

-------------------------------------------------------------------------------
-- Creación de la tabla para almacenar todos los percentiles calculados
set @SQLString=N'
				exec dashboard.dbo.sp_lcc_dropifexists ''lcc_Statistics_Voice_CST' + @sheetTech +'_step1''
				select distinct a.entidad,a.mnc,a.meas_date
				into [DASHBOARD].[dbo].[lcc_Statistics_Voice_CST' + @sheetTech +'_step1]
				from [DASHBOARD].[dbo].['+@table+'_step1] a

				exec dashboard.dbo.sp_lcc_dropifexists ''lcc_Statistics_Voice_CST' + @sheetTech +'''
				select a.entidad,a.mnc,a.meas_date
						,b.P_95_MO_Alert, c.P_95_MT_Alert, d.P_95_MOMT_Alert
						,e.P_95_MO_Conn, f.P_95_MT_Conn, g.P_95_MOMT_Conn
				into [DASHBOARD].[dbo].[lcc_Statistics_Voice_CST' + @sheetTech +']
				from [DASHBOARD].[dbo].[lcc_Statistics_Voice_CST' + @sheetTech +'_step1] a
					left outer join [DASHBOARD].[dbo].[lcc_PERCENTIL' + @sheetTech +'_MO_Alert] b
					on a.entidad=b.entidad and a.mnc=b.mnc and a.meas_date=b.meas_date
					left outer join [DASHBOARD].[dbo].[lcc_PERCENTIL' + @sheetTech +'_MT_Alert] c
					on a.entidad=c.entidad and a.mnc=c.mnc and a.meas_date=c.meas_date
					left outer join [DASHBOARD].[dbo].[lcc_PERCENTIL' + @sheetTech +'_MOMT_Alert] d
					on a.entidad=d.entidad and a.mnc=d.mnc and a.meas_date=d.meas_date
					left outer join [DASHBOARD].[dbo].[lcc_PERCENTIL' + @sheetTech +'_MO_Conn] e
					on a.entidad=e.entidad and a.mnc=e.mnc and a.meas_date=e.meas_date
					left outer join [DASHBOARD].[dbo].[lcc_PERCENTIL' + @sheetTech +'_MT_Conn] f
					on a.entidad=f.entidad and a.mnc=f.mnc and a.meas_date=f.meas_date
					left outer join [DASHBOARD].[dbo].[lcc_PERCENTIL' + @sheetTech +'_MOMT_Conn] g
					on a.entidad=g.entidad and a.mnc=g.mnc and a.meas_date=g.meas_date'
EXECUTE sp_executesql @SQLString

-------------------------------------------------------------------------------
-- Limpieza de tablas temporales
set @SQLString=N'
				exec dashboard.dbo.sp_lcc_dropifexists ''lcc_Statistics_Voice_CST' + @sheetTech +'_step1''' +
				' exec dashboard.dbo.sp_lcc_dropifexists ''lcc_PERCENTIL' + @sheetTech +'_MO_Alert''' +
				' exec dashboard.dbo.sp_lcc_dropifexists ''lcc_PERCENTIL' + @sheetTech +'_MT_Alert''' +
				' exec dashboard.dbo.sp_lcc_dropifexists ''lcc_PERCENTIL' + @sheetTech +'_MOMT_Alert''' +
				' exec dashboard.dbo.sp_lcc_dropifexists ''lcc_PERCENTIL' + @sheetTech +'_MO_Conn''' +
				' exec dashboard.dbo.sp_lcc_dropifexists ''lcc_PERCENTIL' + @sheetTech +'_MT_Conn''' +
				' exec dashboard.dbo.sp_lcc_dropifexists ''lcc_PERCENTIL' + @sheetTech +'_MOMT_Conn''' +
				' exec dashboard.dbo.sp_lcc_dropifexists '''+@table+'_step1'''
EXECUTE sp_executesql @SQLString
