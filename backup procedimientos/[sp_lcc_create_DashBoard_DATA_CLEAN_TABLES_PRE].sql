USE [master]
GO
/****** Object:  StoredProcedure [dbo].[sp_lcc_create_DashBoard_DATA_CLEAN_TABLES_PRE]    Script Date: 29/05/2017 14:00:28 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER procedure [dbo].[sp_lcc_create_DashBoard_DATA_CLEAN_TABLES_PRE] 
	@database as varchar(256)
	,@nameSheet as varchar(256)
	,@group as varchar(256)
as

-------------------------------------------------------------------------------
--Inicialización de variables

--declare @database as varchar(256) = '[DASHBOARD]'
--declare @nameSheet as varchar(256) ='%4G%road%'
--declare @group as varchar(256) = 'ROAD'

declare @sheetTech as varchar(256)
DECLARE @SQLString nvarchar(4000)
declare @tech as varchar(256)

if @nameSheet like '4G%ONLY%' set @sheetTech='_4G'
		else if @nameSheet like '4G_CA' set @sheetTech='_CA'
			else if @nameSheet in ('4G','4G_road','4G_road_region') set @sheetTech=''
				else if @nameSheet like '2G3G' set @sheetTech=''

if @nameSheet like '%4G%' 
	set @tech='_LTE'
else 
	set @tech=''

-------------------------------------------------------------------------------
-- Limpieza de tablas temporales 
SET @SQLString=	N' 
		exec dashboard.dbo.sp_lcc_dropifexists ''lcc_aggr_sp_MDD_Data_DL_Thput_CE'+@sheetTech+'_'+@group+'''' +
		' exec dashboard.dbo.sp_lcc_dropifexists ''lcc_aggr_sp_MDD_Data_DL_Thput_CE'+@tech+@sheetTech+'_'+@group+'''' +
		' exec dashboard.dbo.sp_lcc_dropifexists ''lcc_aggr_sp_MDD_Data_UL_Thput_CE'+@sheetTech+'_'+@group+'''' + 
		' exec dashboard.dbo.sp_lcc_dropifexists ''lcc_aggr_sp_MDD_Data_UL_Thput_CE'+@tech+@sheetTech+'_'+@group+'''' +
		' exec dashboard.dbo.sp_lcc_dropifexists ''lcc_aggr_sp_MDD_Data_DL_Thput_NC'+@sheetTech+'_'+@group+'''' +
		' exec dashboard.dbo.sp_lcc_dropifexists ''lcc_aggr_sp_MDD_Data_DL_Thput_NC'+@tech+@sheetTech+'_'+@group+'''' +
		' exec dashboard.dbo.sp_lcc_dropifexists ''lcc_aggr_sp_MDD_Data_UL_Thput_NC'+@sheetTech+'_'+@group+'''' + 
		' exec dashboard.dbo.sp_lcc_dropifexists ''lcc_aggr_sp_MDD_Data_UL_Thput_NC'+@tech+@sheetTech+'_'+@group+'''' +
		' exec dashboard.dbo.sp_lcc_dropifexists ''lcc_aggr_sp_MDD_Data_Ping'+@sheetTech+'_'+@group+'''' +
		' exec dashboard.dbo.sp_lcc_dropifexists ''lcc_aggr_sp_MDD_Data_Web'+@sheetTech+'_'+@group+'''' +
		' exec dashboard.dbo.sp_lcc_dropifexists ''lcc_aggr_sp_MDD_Data_Youtube'+@sheetTech+'_'+@group+'''' +
		' exec dashboard.dbo.sp_lcc_dropifexists ''lcc_aggr_sp_MDD_Data_Youtube_HD'+@sheetTech+'_'+@group+'''' 

EXECUTE sp_executesql @SQLString

-------------------------------------------------------------------------------