USE [master]
GO
/****** Object:  StoredProcedure [dbo].[sp_lcc_create_DashBoard_TABLES_PRE_CHANGE2REGION]    Script Date: 13/11/2017 10:54:08 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER procedure [dbo].[sp_lcc_create_DashBoard_TABLES_PRE_CHANGE2REGION] 
	@database as varchar(256)
	,@group as varchar(256)
	,@nameSheet as varchar(256)
	,@typeTable as varchar(256)
as

-------------------------------------------------------------------------------
-- Pretatado de las tablas para el caso de tener que agregar por rondas (AVE y HIGHWAYS)
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
--Inicialización de variables
--declare @database as varchar(256) = '[AGGRVoice4G_Road]'
--declare @nameSheet as varchar(256)='4G_road'
--declare @group as varchar(256) ='REGION'
--declare @typeTable as varchar(256) = 'VOICE' 

declare @sheetTech as varchar(256)
declare @table varchar(256)
declare @tech as varchar(256)
declare @it as int = 1

DECLARE @SQLString nvarchar(4000)

if @nameSheet like '%4G%' set @tech='_LTE'
else set @tech=''

if @nameSheet like '4G%ONLY%' set @sheetTech='_4G_ROAD'
		else if @nameSheet like '4G_CA' set @sheetTech='_CA_ROAD'
			else if @nameSheet in ('4G','4G_road') set @sheetTech='_ROAD'
				else if @nameSheet like '2G3G' set @sheetTech='_ROAD'


set @database= replace(replace(@database,'[',''),']','')
-------------------------------------------------------------------------------
-- Tablas a modificar en el pretratado
exec dashboard.dbo.sp_lcc_dropifexists 'lcc_dashboard_TablesPre'
create table [Dashboard].[dbo].[lcc_dashboard_TablesPre](
	Tablename varchar(4000)
	,id int
	,typeTable varchar(256)
)

SET @SQLString =N'
		insert into Dashboard.dbo.lcc_dashboard_TablesPre
		values (''UPDATE_'+@database+'_lcc_aggr_sp_MDD_Data_DL_Thput_CE'+@sheetTech+''',1,''DATA'')			-- Data_DL_Thput_CE
			,(''UPDATE_'+@database+'_lcc_aggr_sp_MDD_Data_DL_Thput_CE'+@tech+@sheetTech+''',2,''DATA'')	-- Data_DL_Thput_CE para estadísticos
			,(''UPDATE_'+@database+'_lcc_aggr_sp_MDD_Data_UL_Thput_CE'+@sheetTech+''',3,''DATA'')		-- Data_UL_Thput_CE
			,(''UPDATE_'+@database+'_lcc_aggr_sp_MDD_Data_UL_Thput_CE'+@tech+@sheetTech+''',4,''DATA'')	-- Data_UL_Thput_CE para estadísticos
			,(''UPDATE_'+@database+'_lcc_aggr_sp_MDD_Data_DL_Thput_NC'+@sheetTech+''',5,''DATA'')		-- Data_DL_Thput_NC
			,(''UPDATE_'+@database+'_lcc_aggr_sp_MDD_Data_DL_Thput_NC'+@tech+@sheetTech+''',6,''DATA'')	-- Data_DL_Thput_NC para estadísticos
			,(''UPDATE_'+@database+'_lcc_aggr_sp_MDD_Data_UL_Thput_NC'+@sheetTech+''',7,''DATA'')		-- Data_UL_Thput_NC
			,(''UPDATE_'+@database+'_lcc_aggr_sp_MDD_Data_UL_Thput_NC'+@tech+@sheetTech+''',8,''DATA'')	-- Data_UL_Thput_NC para estadísticos
			,(''UPDATE_'+@database+'_lcc_aggr_sp_MDD_Data_Ping'+@sheetTech+''',9,''DATA'')				-- Data_Latency
			,(''UPDATE_'+@database+'_lcc_aggr_sp_MDD_Data_Web'+@sheetTech+''',10,''DATA'')				-- Data_Web_Browsing
			,(''UPDATE_'+@database+'_lcc_aggr_sp_MDD_Data_Youtube'+@sheetTech+''',11,''DATA'')			-- Data_Youtube SD
			,(''UPDATE_'+@database+'_lcc_aggr_sp_MDD_Data_Youtube_HD'+@sheetTech+''',12,''DATA'')		-- Data_Youtube HD
			,(''UPDATE_'+@database+'_lcc_aggr_sp_MDD_Voice_Llamadas'+@sheetTech+''',1,''VOICE'')						-- Voice_calls
			,(''UPDATE_'+@database+'_lcc_aggr_sp_MDD_Voice_CallSetupTime_CompletedCalls'+@sheetTech+''',2,''VOICE'')	-- Voice_CST
			,(''UPDATE_'+@database+'_lcc_aggr_sp_MDD_Voice_PESQ'+@sheetTech+''',3,''VOICE'')							-- Voice_MOS'
EXECUTE sp_executesql @SQLString

-------------------------------------------------------------------------------
-- Se reutilizan las tablas que habíamos pre-calculado con las medidas correspondientes a la ventana de medidas, 
-- simplemente ahora la entidad pasa a ser la region.

set @it = 1
while (@it <= (SELECT max(id) FROM [Dashboard].[dbo].[lcc_dashboard_TablesPre] where typeTable=@typeTable))
begin 
	set @table =(select tableName from [Dashboard].[dbo].[lcc_dashboard_TablesPre] where id = @it and typeTable=@typeTable)
	SET @SQLString =N'
				exec dashboard.dbo.sp_lcc_dropifexists '''+@table+'_'+@group+'''
				select a.*,a.Region_VF as NewEntidad, ''RW'' as NewMeas_Date
				into [DASHBOARD].[dbo].['+@table+'_'+@group+']
				from [DASHBOARD].[dbo].['+@table+'] a
				'
	EXECUTE sp_executesql @SQLString
	SET @SQLString =N'
				alter table [DASHBOARD].[dbo].['+@table+'_'+@group+'] drop column Entidad, Meas_Date
				use [DASHBOARD]
				exec sp_rename ''dbo.'+@table+'_'+@group+'.NewEntidad'',''Entidad'',''COLUMN''
				exec sp_rename ''dbo.'+@table+'_'+@group+'.NewMeas_Date'',''Meas_Date'',''COLUMN''
				use [master]'
	EXECUTE sp_executesql @SQLString
	set @it=@it+1
end 

-------------------------------------------------------------------------------
-- Limpieza de tablas temporales
drop table [Dashboard].[dbo].[lcc_dashboard_TablesPre]
