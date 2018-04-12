USE [master]
GO
/****** Object:  StoredProcedure [dbo].[sp_lcc_create_DashBoard_TABLES_PRE_AGGR]    Script Date: 29/05/2017 15:16:29 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  StoredProcedure [dbo].[sp_lcc_create_DashBoard_TABLES_PRE_AGGR]    Script Date: 02/02/2016 9:25:19 ******/

ALTER procedure [dbo].[sp_lcc_create_DashBoard_TABLES_PRE_AGGR] 
	@database as varchar(256)
	,@nameSheet as varchar(256)
as
-------------------------------------------------------------------------------
-- Pretatado de las tablas para obtener el campo entidad
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
--Inicialización de variables
--declare @database as varchar(256) = '[AGGRData4G]'
--declare @nameSheet as varchar(256)= '4G_CA'

declare @typeTable as varchar(256)
declare @sheetTech as varchar(256)
declare @table varchar(256)
declare @tech as varchar(256)
declare @it as int = 1

DECLARE @SQLString nvarchar(max)

if @database= '[AGGRData4G]' or @database= '[AGGRData4G_ROAD]'
	set @tech='_LTE'
else 
	set @tech=''

if @nameSheet in ('4G_ONLY','4G_ONLY_road') set @sheetTech='_4G'
		--else if @nameSheet like '4G_CA' and @nameSheet not like '4G_CAONLY' set @sheetTech='_CA'
			else if @nameSheet like '4G_CAONLY' set @sheetTech='_CA_ONLY'
				else if @nameSheet in ('4G','4G_road') set @sheetTech=''
					else if @nameSheet like '2G3G' set @sheetTech=''

if @database like '%Data%' set @typeTable='DATA'
else if @database like '%Voice%' set @typeTable='VOICE'

-------------------------------------------------------------------------------
-- Tablas a modificar en el pretratado
exec dashboard.dbo.sp_lcc_dropifexists 'lcc_dashboard_TablesPre'
create table [Dashboard].[dbo].[lcc_dashboard_TablesPre](
	Tablename varchar(4000)
	,id int
	,typeTable varchar(256)
)

if @tech='_LTE'
begin
-- Si estamos en 4G datos, hay que tomar las tablas de estadísticos diferentes a las convencionales
	if @nameSheet <> '4G_CAONLY'
	begin
		SET @SQLString =N'
			insert into Dashboard.dbo.lcc_dashboard_TablesPre
			values (''lcc_aggr_sp_MDD_Data_DL_Thput_CE'+@sheetTech+''',1,''DATA'')		-- Data_DL_Thput_CE
				,(''lcc_aggr_sp_MDD_Data_DL_Thput_CE'+@tech+@sheetTech+''',2,''DATA'')	-- Data_DL_Thput_CE para estadísticos
				,(''lcc_aggr_sp_MDD_Data_UL_Thput_CE'+@sheetTech+''',3,''DATA'')		-- Data_UL_Thput_CE
				,(''lcc_aggr_sp_MDD_Data_UL_Thput_CE'+@tech+@sheetTech+''',4,''DATA'')	-- Data_UL_Thput_CE para estadísticos
				,(''lcc_aggr_sp_MDD_Data_DL_Thput_NC'+@sheetTech+''',5,''DATA'')		-- Data_DL_Thput_NC
				,(''lcc_aggr_sp_MDD_Data_DL_Thput_NC'+@tech+@sheetTech+''',6,''DATA'')	-- Data_DL_Thput_NC para estadísticos
				,(''lcc_aggr_sp_MDD_Data_UL_Thput_NC'+@sheetTech+''',7,''DATA'')		-- Data_UL_Thput_NC
				,(''lcc_aggr_sp_MDD_Data_UL_Thput_NC'+@tech+@sheetTech+''',8,''DATA'')	-- Data_UL_Thput_NC para estadísticos
				,(''lcc_aggr_sp_MDD_Data_Ping'+@sheetTech+''',9,''DATA'')				-- Data_Latency
				,(''lcc_aggr_sp_MDD_Data_Web'+@sheetTech+''',10,''DATA'')				-- Data_Web_Browsing
				,(''lcc_aggr_sp_MDD_Data_Youtube'+@sheetTech+''',11,''DATA'')			-- Data_Youtube SD
				,(''lcc_aggr_sp_MDD_Data_Youtube_HD'+@sheetTech+''',12,''DATA'')		-- Data_Youtube HD
				,(''lcc_aggr_sp_MDD_Voice_Llamadas'+@sheetTech+''',1,''VOICE'')						-- Voice_calls
				,(''lcc_aggr_sp_MDD_Voice_CallSetupTime_CompletedCalls'+@sheetTech+''',2,''VOICE'')	-- Voice_CST
				,(''lcc_aggr_sp_MDD_Voice_PESQ'+@sheetTech+''',3,''VOICE'')							-- Voice_MOS
				,(''lcc_aggr_sp_MDD_Voice_mallado'+@sheetTech+''',4,''VOICE'')						-- Voice_mallado'
	end
	if @nameSheet = '4G_CAONLY'
	begin
		SET @SQLString =N'
			insert into Dashboard.dbo.lcc_dashboard_TablesPre
			values (''lcc_aggr_sp_MDD_Data_DL_Thput_CE'+@sheetTech+''',1,''DATA'')		-- Data_DL_Thput_CE
				,(''lcc_aggr_sp_MDD_Data_DL_Thput_CE'+@tech+@sheetTech+''',2,''DATA'')	-- Data_DL_Thput_CE para estadísticos
				,(''lcc_aggr_sp_MDD_Data_UL_Thput_CE'+@sheetTech+''',3,''DATA'')		-- Data_UL_Thput_CE
				,(''lcc_aggr_sp_MDD_Data_UL_Thput_CE'+@tech+@sheetTech+''',4,''DATA'')	-- Data_UL_Thput_CE para estadísticos
				,(''lcc_aggr_sp_MDD_Data_DL_Thput_NC'+@sheetTech+''',5,''DATA'')		-- Data_DL_Thput_NC
				,(''lcc_aggr_sp_MDD_Data_DL_Thput_NC'+@tech+@sheetTech+''',6,''DATA'')	-- Data_DL_Thput_NC para estadísticos
				,(''lcc_aggr_sp_MDD_Data_UL_Thput_NC'+@sheetTech+''',7,''DATA'')		-- Data_UL_Thput_NC
				,(''lcc_aggr_sp_MDD_Data_UL_Thput_NC'+@tech+@sheetTech+''',8,''DATA'')	-- Data_UL_Thput_NC para estadísticos
				,(''lcc_aggr_sp_MDD_Data_Ping'+@sheetTech+''',9,''DATA'')				-- Data_Latency
				,(''lcc_aggr_sp_MDD_Data_Web'+@sheetTech+''',10,''DATA'')				-- Data_Web_Browsing
				,(''lcc_aggr_sp_MDD_Data_Youtube_HD'+@sheetTech+''',11,''DATA'')		-- Data_Youtube HD
				,(''lcc_aggr_sp_MDD_Voice_Llamadas'+@sheetTech+''',1,''VOICE'')						-- Voice_calls
				,(''lcc_aggr_sp_MDD_Voice_CallSetupTime_CompletedCalls'+@sheetTech+''',2,''VOICE'')	-- Voice_CST
				,(''lcc_aggr_sp_MDD_Voice_PESQ'+@sheetTech+''',3,''VOICE'')							-- Voice_MOS
				,(''lcc_aggr_sp_MDD_Voice_mallado'+@sheetTech+''',4,''VOICE'')						-- Voice_mallado'
	end

	print @SQLString
	EXECUTE sp_executesql @SQLString
end
else if @tech=''
begin
-- Si es voz o datos 3G, hay que tomar las tablas convencionales para los estadísticos
	SET @SQLString =N'
			insert into Dashboard.dbo.lcc_dashboard_TablesPre
			values (''lcc_aggr_sp_MDD_Data_DL_Thput_CE'+@sheetTech+''',1,''DATA'')		-- Data_DL_Thput_CE
				,(''lcc_aggr_sp_MDD_Data_UL_Thput_CE'+@sheetTech+''',2,''DATA'')		-- Data_UL_Thput_CE
				,(''lcc_aggr_sp_MDD_Data_DL_Thput_NC'+@sheetTech+''',3,''DATA'')		-- Data_DL_Thput_NC
				,(''lcc_aggr_sp_MDD_Data_UL_Thput_NC'+@sheetTech+''',4,''DATA'')		-- Data_UL_Thput_NC
				,(''lcc_aggr_sp_MDD_Data_Ping'+@sheetTech+''',5,''DATA'')				-- Data_Latency
				,(''lcc_aggr_sp_MDD_Data_Web'+@sheetTech+''',6,''DATA'')				-- Data_Web_Browsing
				,(''lcc_aggr_sp_MDD_Data_Youtube'+@sheetTech+''',7,''DATA'')			-- Data_Youtube SD
				,(''lcc_aggr_sp_MDD_Data_Youtube_HD'+@sheetTech+''',8,''DATA'')		-- Data_Youtube HD
				,(''lcc_aggr_sp_MDD_Voice_Llamadas'+@sheetTech+''',1,''VOICE'')						-- Voice_calls
				,(''lcc_aggr_sp_MDD_Voice_CallSetupTime_CompletedCalls'+@sheetTech+''',2,''VOICE'')	-- Voice_CST
				,(''lcc_aggr_sp_MDD_Voice_PESQ'+@sheetTech+''',3,''VOICE'')							-- Voice_MOS
				,(''lcc_aggr_sp_MDD_Voice_mallado'+@sheetTech+''',4,''VOICE'')						-- Voice_mallado'
	print @SQLString
	EXECUTE sp_executesql @SQLString	
end 

-------------------------------------------------------------------------------
-- Se modifican las tablas para incluir el nuevo campo entidad sacado del collectionName
-- Se limpian los nombres de las entidades, que ahora incluyen noLA y LA en los logs.

set @it = 1
while (@it <= (SELECT max(id) FROM [Dashboard].[dbo].[lcc_dashboard_TablesPre] where typeTable=@typeTable))
begin 
	SET @table =(select tableName from [Dashboard].[dbo].[lcc_dashboard_TablesPre] where id = @it and typeTable=@typeTable)
		SET @SQLString =N'
					exec dashboard.dbo.sp_lcc_dropifexists ''UPDATE_'+ replace(replace(@database,'[',''),']','')+'_'+@table+'''
					select a.*,b.ciudad,b.provincia,b.entorno
						,replace(replace(a.entidad,''-noLA'',''''),''-LA'','''') as entidad_new
						,1 as valid
						,case when a.Date_reporting is not null then a.Date_reporting
							when a.Date_reporting is null then a.Meas_date
							end as Meas_date_new
					into [DASHBOARD].[dbo].UPDATE_'+ replace(replace(@database,'[',''),']','')+'_'+@table+'
					from '+ @database + '.[dbo].['+@table+'] a
						left outer join agrids.dbo.lcc_parcelas b
						on a.parcel=b.nombre'	
		print @SQLString			
		EXECUTE sp_executesql @SQLString

	---------------AÑADIR ENTIDADES S4

	--declare @tableAux as varchar(256)

	--IF @table like '%CA%' and @table not like '%Voice%' and @table not like '%Main%' and @table not like '%Smaller%'
	--Begin
	--set @tableAux = SUBSTRING(@table,0,CHARINDEX('_CA',@table)) 
	--	SET @SQLString =N'
	--		insert into [DASHBOARD].[dbo].UPDATE_'+ replace(replace(@database,'[',''),']','')+'_'+@table+'
	--		select a.*,b.ciudad,b.provincia,b.entorno
	--			,replace(replace(a.entidad,''-noLA'',''''),''-LA'','''') as entidad_new
	--			,1 as valid
	--			,case when a.Date_reporting is not null then a.Date_reporting
	--				when a.Date_reporting is null then a.Meas_date
	--				end as Meas_date_new
	--		from '+ @database + '.[dbo].['+@tableAux+'] a
	--		left outer join agrids.dbo.lcc_parcelas b
	--		on a.parcel=b.nombre and a.[database] like ''%rest%'''
	--	print @SQLString						
	--	EXECUTE sp_executesql @SQLString
	--End
	---------------------------------

	SET @SQLString =N'
				alter table [DASHBOARD].[dbo].UPDATE_'+ replace(replace(@database,'[',''),']','')+'_'+@table+' drop column Entidad
				use [DASHBOARD]
				exec sp_rename ''dbo.UPDATE_'+ replace(replace(@database,'[',''),']','')+'_'+@table+'.entidad_new'',''Entidad'',''COLUMN''
				exec sp_rename ''dbo.UPDATE_'+ replace(replace(@database,'[',''),']','')+'_'+@table+'.meas_date'',''Meas_date_parcel'',''COLUMN''
				exec sp_rename ''dbo.UPDATE_'+ replace(replace(@database,'[',''),']','')+'_'+@table+'.meas_date_new'',''Meas_date'',''COLUMN'' 
				use [master]'
	--print @SQLString
	EXECUTE sp_executesql @SQLString
	set @it=@it+1
end 

---------------------------------------------------------------------------------
---- Limpieza de tablas temporales
exec dashboard.dbo.sp_lcc_dropifexists 'lcc_dashboard_TablesPre'
