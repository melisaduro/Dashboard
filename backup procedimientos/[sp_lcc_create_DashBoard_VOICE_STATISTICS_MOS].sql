USE [master]
GO
/****** Object:  StoredProcedure [dbo].[sp_lcc_create_DashBoard_VOICE_STATISTICS_MOS]    Script Date: 29/05/2017 15:20:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER procedure [dbo].[sp_lcc_create_DashBoard_VOICE_STATISTICS_MOS] 
	@sheetTech varchar(256)
	,@table varchar(256)
	,@LAfilter varchar(2000)
as

-------------------------------------------------------------------------------
-- Declaración de variables
--declare @sheetTech as varchar(256)	= '' -- or '_4G'
--declare @table as varchar(256) = 'lcc_aggr_sp_MDD_Voice_PESQ'

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
				from [DASHBOARD].[dbo].['+@table+'] a
				where  ' + @LAfilter
EXECUTE sp_executesql @SQLString

set @table_modif = @table+'_step1'

----------------------------------------------------------------------------
-- Llamadas a los procedimientos de cálculos de estadísticos
-- Desviación típica NB
exec [dbo].[sp_lcc_create_DashBoard_STATISTICS_STDV] '[DASHBOARD]',@sheetTech,@table_modif,0.5,8,'NB',1,0

set @SQLString=N'
				exec dashboard.dbo.sp_lcc_dropifexists ''lcc_STDV' + @sheetTech +'_NB''
				select entidad,mnc,meas_date,DESV as DESV_NB
				into [DASHBOARD].[dbo].[lcc_STDV' + @sheetTech +'_NB]
				from [DASHBOARD].[dbo].[lcc_STDV' + @sheetTech +']'
EXECUTE sp_executesql @SQLString

-- Desviación típica OverAll
exec [dbo].[sp_lcc_create_DashBoard_STATISTICS_STDV] '[DASHBOARD]',@sheetTech,@table_modif,0.5,8,'overall',1,0

set @SQLString=N'
				exec dashboard.dbo.sp_lcc_dropifexists ''lcc_STDV' + @sheetTech +'_OverAll''
				select entidad,mnc,meas_date,DESV as DESV_OverAll
				into [DASHBOARD].[dbo].[lcc_STDV' + @sheetTech +'_OverAll]
				from [DASHBOARD].[dbo].[lcc_STDV' + @sheetTech +']'
EXECUTE sp_executesql @SQLString

-- Mediana WB
exec [dbo].[sp_lcc_create_DashBoard_STATISTICS_MEDIAN] '[DASHBOARD]',@sheetTech,@table_modif,0.5,8,1,'WB',0
set @SQLString=N'
		exec dashboard.dbo.sp_lcc_dropifexists ''lcc_MEDIAN'+@sheetTech+'_WB''
		select entidad,mnc,meas_date,Median as Median_WB
		into [DASHBOARD].[dbo].[lcc_MEDIAN'+@sheetTech+'_WB]
		from [DASHBOARD].[dbo].[lcc_Statistics_MEDIAN_'+@sheetTech+']'
EXECUTE sp_executesql @SQLString

-- Percentiles P05 OverAll
exec [dbo].[sp_lcc_create_DashBoard_STATISTICS_PERCENTIL] '[DASHBOARD]',@sheetTech,@table_modif,0.5,8,1,'overall',0.05,0
set @SQLString=N'
				exec dashboard.dbo.sp_lcc_dropifexists ''lcc_PERCENTIL' + @sheetTech +'_OverAll''
				select entidad,mnc,meas_date,Percentil as P_05_OverAll
				into [DASHBOARD].[dbo].[lcc_PERCENTIL' + @sheetTech +'_OverAll]
				from [DASHBOARD].[dbo].[lcc_PERCENTIL' + @sheetTech +']'
EXECUTE sp_executesql @SQLString

-- Percentiles P05 WB
exec [dbo].[sp_lcc_create_DashBoard_STATISTICS_PERCENTIL] '[DASHBOARD]',@sheetTech,@table_modif,0.5,8,1,'WB',0.05,0
set @SQLString=N'
				exec dashboard.dbo.sp_lcc_dropifexists ''lcc_PERCENTIL' + @sheetTech +'_WB''
				select entidad,mnc,meas_date,Percentil as P_05_WB
				into [DASHBOARD].[dbo].[lcc_PERCENTIL' + @sheetTech +'_WB]
				from [DASHBOARD].[dbo].[lcc_PERCENTIL' + @sheetTech +']'
EXECUTE sp_executesql @SQLString

-- Percentiles P05 NB
exec [dbo].[sp_lcc_create_DashBoard_STATISTICS_PERCENTIL] '[DASHBOARD]',@sheetTech,@table_modif,0.5,8,1,'NB',0.05,0
set @SQLString=N'
				exec dashboard.dbo.sp_lcc_dropifexists ''lcc_PERCENTIL' + @sheetTech +'_NB''
				select entidad,mnc,meas_date,Percentil as P_05_NB
				into [DASHBOARD].[dbo].[lcc_PERCENTIL' + @sheetTech +'_NB]
				from [DASHBOARD].[dbo].[lcc_PERCENTIL' + @sheetTech +']'
EXECUTE sp_executesql @SQLString

-------------------------------------------------------------------------------
-- Creación de la tabla para almacenar todos los estadísticos calculados
set @SQLString=N'
				exec dashboard.dbo.sp_lcc_dropifexists ''lcc_Statistics_Voice_MOS' + @sheetTech +'_step1''
				select distinct a.entidad,a.mnc,a.meas_date
				into [DASHBOARD].[dbo].[lcc_Statistics_Voice_MOS' + @sheetTech +'_step1]
				from [DASHBOARD].[dbo].['+@table+'_step1] a	

				exec dashboard.dbo.sp_lcc_dropifexists ''lcc_Statistics_Voice_MOS' + @sheetTech +'''
				select a.entidad,a.mnc,a.Meas_date,b.P_05_WB,c.P_05_NB,d.Median_WB,e.DESV_NB,f.P_05_OverAll,g.DESV_OverAll
				into [DASHBOARD].[dbo].[lcc_Statistics_Voice_MOS' + @sheetTech +']
				from [DASHBOARD].[dbo].[lcc_Statistics_Voice_MOS' + @sheetTech +'_step1] a
					left outer join [DASHBOARD].[dbo].[lcc_PERCENTIL' + @sheetTech +'_WB] b
					on a.entidad=b.entidad and a.mnc=b.mnc and a.Meas_Date=b.Meas_Date
					left outer join [DASHBOARD].[dbo].[lcc_PERCENTIL' + @sheetTech +'_NB] c
					on a.entidad=c.entidad and a.mnc=c.mnc and a.meas_date=c.meas_date
					left outer join [DASHBOARD].[dbo].[lcc_MEDIAN'+@sheetTech+'_WB] d
					on a.entidad=d.entidad and a.mnc=d.mnc and a.meas_date=d.meas_date
					left outer join [DASHBOARD].[dbo].[lcc_STDV' + @sheetTech +'_NB] e
					on a.entidad=e.entidad and a.mnc=e.mnc and a.meas_date=e.meas_date
					left outer join [DASHBOARD].[dbo].[lcc_PERCENTIL' + @sheetTech +'_OverAll] f
					on a.entidad=f.entidad and a.mnc=f.mnc and a.meas_date=f.meas_date
					left outer join [DASHBOARD].[dbo].[lcc_STDV' + @sheetTech +'_OverAll] g
					on a.entidad=g.entidad and a.mnc=g.mnc and a.meas_date=g.meas_date'
EXECUTE sp_executesql @SQLString

-------------------------------------------------------------------------------
-- Limpieza de tablas temporales
set @SQLString=N'
				exec dashboard.dbo.sp_lcc_dropifexists ''lcc_Statistics_Voice_MOS' + @sheetTech +'_step1''' +
				' exec dashboard.dbo.sp_lcc_dropifexists ''lcc_PERCENTIL' + @sheetTech +'_WB'''+
				' exec dashboard.dbo.sp_lcc_dropifexists ''lcc_PERCENTIL' + @sheetTech +'_NB'''+
				' exec dashboard.dbo.sp_lcc_dropifexists ''lcc_STDV' + @sheetTech +'_NB'''+
				' exec dashboard.dbo.sp_lcc_dropifexists ''lcc_MEDIAN'+@sheetTech+'_WB'''+
				' exec dashboard.dbo.sp_lcc_dropifexists '''+@table+'_step1'''+
				' exec dashboard.dbo.sp_lcc_dropifexists ''lcc_PERCENTIL' + @sheetTech +'_OverAll'''+
				' exec dashboard.dbo.sp_lcc_dropifexists ''lcc_STDV' + @sheetTech +'_OverAll'''
EXECUTE sp_executesql @SQLString
