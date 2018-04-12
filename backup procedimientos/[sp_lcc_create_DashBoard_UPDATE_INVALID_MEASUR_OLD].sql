USE [master]
GO
/****** Object:  StoredProcedure [dbo].[sp_lcc_create_DashBoard_UPDATE_INVALID_MEASUR_OLD]    Script Date: 29/05/2017 15:18:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


ALTER procedure [dbo].[sp_lcc_create_DashBoard_UPDATE_INVALID_MEASUR_OLD] 
	@nameSheet as varchar(256)
	,@typeTable as varchar(256)
	,@database as varchar(256)
as
-------------------------------------------------------------------------------
--Inicialización de variables
--exec [dbo].[sp_lcc_create_DashBoard_TABLES_PRE_AGGR] '[AGGRData4G]','4G_CA'
--exec [dbo].[sp_lcc_create_DashBoard_DATA_TABLES] '[AGGRData4G]','4G_CA',1,1

--declare @nameSheet as varchar(256) = '4G_ca'
--declare @typeTable as varchar(256)='data'
--declare @database as varchar(256) = '[AGGRData4G]'

set @database= replace(replace(@database,'[',''),']','')

declare @ColumnName as varchar(256)
declare @table as varchar(256)
declare @sufix as varchar(256)
declare @it int =1
declare @it_tab int =1
declare @j int =1
DECLARE @SQLString nvarchar(4000)
declare @KPIName varchar(2000)
declare @tableOrig varchar(256)
declare @KPIGroup varchar (256)
declare @entidad varchar(256)
declare @mnc varchar(256)
declare @old_measdate varchar(256)
declare @measdate varchar(256)
declare @table4g varchar(256)
declare @sheetTech varchar(256)
declare @TableCheck varchar (256)

if @nameSheet in ('4G_ONLY','4G_ONLY_road') set @sheetTech='_4G'
		else if @nameSheet like '4G_CA' and @nameSheet not like '4G_CAONLY'  set @sheetTech='_CA'
			else if @nameSheet like '4G_CAONLY' set @sheetTech='_CA_ONLY'
				else if @nameSheet in ('4G','4G_road') set @sheetTech=''
					else if @nameSheet like '2G3G' set @sheetTech=''

-- Tabla con los KPIs invalidados
exec dashboard.dbo.sp_lcc_dropifexists 'lcc_KPIs_noValid_step1'
create table dashboard.dbo.lcc_KPIs_noValid_step1 (
	entidad varchar(256)
	,scope varchar(256)
	,mnc varchar(256)
	,meas_date varchar(256)
	,KPIName varchar(256)
	,TableName varchar(256)
)

-- Tabla con todos los KPIs de las tablas
exec dashboard.dbo.sp_lcc_dropifexists 'lcc_KPIs_tables'
create table dashboard.dbo.lcc_KPIs_tables (
	KPIName varchar(256)
	,TableName varchar(256)
	,KPIGroup varchar(256)
	,sufix varchar(256)
	,id int
)

-- Tablas a chequear
exec dashboard.dbo.sp_lcc_dropifexists 'lcc_dashboard_TablesPre_u'
create table [Dashboard].[dbo].[lcc_dashboard_TablesPre_u](
	Tablename varchar(4000)
	,id int
	,typeTable varchar(256)
	,sufix varchar(256)
	,KPIGroup varchar(256)
)

SET @SQLString =N'
		insert into Dashboard.dbo.lcc_dashboard_TablesPre_u
		values (''lcc_Voice_calls_'+@nameSheet+'_temp'',1,''VOICE'',''_c'',''CALLS'')	-- Voice_calls
			,(''lcc_Voice_CST_'+@nameSheet+'_temp'',2,''VOICE'',''_cst'',''CST'')		-- Voice_cst
			,(''lcc_Voice_MOS_'+@nameSheet+'_temp'',3,''VOICE'',''_mos'',''MOS'')		-- Voice_mos
			,(''lcc_DL_Th_CE_'+@nameSheet+'_temp'',1, ''DATA'',''_dl_CE'',''DL_CE'')		-- Data dl_CE
			,(''lcc_UL_Th_CE_'+@nameSheet+'_temp'',2, ''DATA'',''_ul_CE'',''UL_CE'')		-- Data ul_CE
			,(''lcc_DL_Th_NC_'+@nameSheet+'_temp'',3, ''DATA'',''_dl_NC'',''DL_NC'')		-- Data dl_NC
			,(''lcc_UL_Th_NC_'+@nameSheet+'_temp'',4, ''DATA'',''_ul_NC'',''UL_NC'')		-- Data ul_NC
			,(''lcc_Latency_'+@nameSheet+'_temp'',5, ''DATA'',''_lat'',''LAT'')			-- Data lat
			,(''lcc_Browsing_'+@nameSheet+'_temp'',6, ''DATA'',''_web'',''WEB'')			-- Data web
			,(''lcc_YTB_SD_'+@nameSheet+'_temp'',7, ''DATA'',''_ytb_sd'',''YTB_SD'')		-- Data youtube SD
			,(''lcc_YTB_HD_'+@nameSheet+'_temp'',8, ''DATA'',''_ytb_hd'',''YTB_HD'')		-- Data youtube HD
			------- Tablas 4G para comprobar sobre ellas --------------------
			,(''lcc_Voice_calls_4G_temp'',1,''VOICE_4G'','''',''CALLS'')		-- Voice_calls
			,(''lcc_Voice_CST_4G_temp'',2,''VOICE_4G'','''',''CST'')		-- Voice_cst
			,(''lcc_Voice_MOS_4G_temp'',3,''VOICE_4G'','''',''MOS'')		-- Voice_mos
			,(''lcc_DL_Th_CE_4G_temp'',1, ''DATA_4G'','''',''DL_CE'')		-- Data dl_CE
			,(''lcc_UL_Th_CE_4G_temp'',2, ''DATA_4G'','''',''UL_CE'')		-- Data ul_CE
			,(''lcc_DL_Th_NC_4G_temp'',3, ''DATA_4G'','''',''DL_NC'')		-- Data dl_NC
			,(''lcc_UL_Th_NC_4G_temp'',4, ''DATA_4G'','''',''UL_NC'')		-- Data ul_NC
			,(''lcc_Latency_4G_temp'',5, ''DATA_4G'','''',''LAT'')			-- Data lat
			,(''lcc_Browsing_4G_temp'',6, ''DATA_4G'','''',''WEB'')			-- Data web
			,(''lcc_YTB_SD_4G_temp'',7, ''DATA_4G'','''',''YTB_SD'')		-- Data youtube SD
			,(''lcc_YTB_HD_4G_temp'',8, ''DATA_4G'','''',''YTB_HD'')		-- Data youtube HD
			'
EXECUTE sp_executesql @SQLString


-- Hay que actualizar las tablas que se utilizan para obtener los estadísticos para considerar estas medidas en los cálculos del scope
if @nameSheet like '%4G%' and @typeTable like 'DATA'
begin
	SET @SQLString =N' insert into Dashboard.dbo.lcc_dashboard_TablesPre_u
				values 
				(''UPDATE_'+@database+'_lcc_aggr_sp_MDD_DATA_DL_Thput_CE_LTE'+@sheetTech+''',9, ''DATA'','''',''DL_CE_LTE'')		-- Data dl_CE para estadísticos
				,(''UPDATE_'+@database+'_lcc_aggr_sp_MDD_DATA_UL_Thput_CE_LTE'+@sheetTech+''',10, ''DATA'','''',''UL_CE_LTE'')		-- Data ul_CE para estadísticos
				,(''UPDATE_'+@database+'_lcc_aggr_sp_MDD_DATA_DL_Thput_NC_LTE'+@sheetTech+''',11, ''DATA'','''',''DL_NC_LTE'')		-- Data dl_NC para estadísticos
				,(''UPDATE_'+@database+'_lcc_aggr_sp_MDD_DATA_UL_Thput_NC_LTE'+@sheetTech+''',12, ''DATA'','''',''UL_NC_LTE'')		-- Data ul_NC para estadísticos
				,(''UPDATE_'+@database+'_lcc_aggr_sp_MDD_DATA_ping'+@sheetTech+''',13, ''DATA'','''',''LAT_stats'')
				------- Tablas 4G para comprobar sobre ellas --------------------
				,(''UPDATE_'+@database+'_lcc_aggr_sp_MDD_DATA_DL_Thput_CE_LTE'',9, ''DATA_4G'','''',''DL_CE_LTE'')		-- Data dl_CE para estadísticos
				,(''UPDATE_'+@database+'_lcc_aggr_sp_MDD_DATA_UL_Thput_CE_LTE'',10, ''DATA_4G'','''',''UL_CE_LTE'')		-- Data ul_CE para estadísticos
				,(''UPDATE_'+@database+'_lcc_aggr_sp_MDD_DATA_DL_Thput_NC_LTE'',11, ''DATA_4G'','''',''DL_NC_LTE'')		-- Data dl_NC para estadísticos
				,(''UPDATE_'+@database+'_lcc_aggr_sp_MDD_DATA_UL_Thput_NC_LTE'',12, ''DATA_4G'','''',''UL_NC_LTE'')		-- Data ul_NC para estadísticos
				,(''UPDATE_'+@database+'_lcc_aggr_sp_MDD_DATA_ping'',13, ''DATA_4G'','''',''LAT_stats'')
				'
	EXECUTE sp_executesql @SQLString
end

if @nameSheet like '%3G%' and @typeTable like 'DATA'
begin
	SET @SQLString =N' insert into Dashboard.dbo.lcc_dashboard_TablesPre_u
				values 
				(''UPDATE_'+@database+'_lcc_aggr_sp_MDD_DATA_DL_Thput_CE'+@sheetTech+''',9, ''DATA'','''',''DL_CE_stats'')		-- Data dl_CE para estadísticos
				,(''UPDATE_'+@database+'_lcc_aggr_sp_MDD_DATA_UL_Thput_CE'+@sheetTech+''',10, ''DATA'','''',''UL_CE_stats'')		-- Data ul_CE para estadísticos
				,(''UPDATE_'+@database+'_lcc_aggr_sp_MDD_DATA_DL_Thput_NC'+@sheetTech+''',11, ''DATA'','''',''DL_NC_stats'')		-- Data dl_NC para estadísticos
				,(''UPDATE_'+@database+'_lcc_aggr_sp_MDD_DATA_UL_Thput_NC'+@sheetTech+''',12, ''DATA'','''',''UL_NC_stats'')		-- Data ul_NC para estadísticos
				,(''UPDATE_'+@database+'_lcc_aggr_sp_MDD_DATA_ping'+@sheetTech+''',13, ''DATA'','''',''LAT_stats'')
				'
	EXECUTE sp_executesql @SQLString
end

-- Bucle para detectar los KPIs a null
set @it_tab=1
while (@it_tab <= (SELECT max(id) FROM [DASHBOARD].[dbo].lcc_dashboard_TablesPre_u where [TYPETABLE]=@typeTable))
begin	
	set @table = (select Tablename from [DASHBOARD].[dbo].lcc_dashboard_TablesPre_u where id = @it_tab and [TYPETABLE]=@typeTable)
	if @namesheet like '%4G%' and @namesheet not like '%4G%'
		set @table4G= (select Tablename from [DASHBOARD].[dbo].lcc_dashboard_TablesPre_u where id = @it_tab and [TYPETABLE]=@typeTable+'_4G')
		--set @table4G= (select Tablename from [DASHBOARD].[dbo].lcc_dashboard_TablesPre_u where id = @it_tab and [TYPETABLE]=@typeTable)
	else
		set @table4G= (select Tablename from [DASHBOARD].[dbo].lcc_dashboard_TablesPre_u where id = @it_tab and [TYPETABLE]=@typeTable)

	set @sufix= (select sufix from [DASHBOARD].[dbo].lcc_dashboard_TablesPre_u where id = @it_tab and [TYPETABLE]=@typeTable)
	set @KPIGroup= (select KPIGroup from [DASHBOARD].[dbo].lcc_dashboard_TablesPre_u where id = @it_tab and [TYPETABLE]=@typeTable)

	-- Columnas de las tablas a chequear
	exec dashboard.dbo.sp_lcc_dropifexists 'lcc_columns_tmp'
	SELECT  IDENTITY(int,1,1) id,COLUMN_NAME
	into dashboard.dbo.lcc_columns_tmp
	FROM dashboard.INFORMATION_SCHEMA.COLUMNS
	WHERE table_name = @table
	set @it = 1
	while (@it <= (SELECT count(COLUMN_NAME) FROM dashboard.INFORMATION_SCHEMA.COLUMNS WHERE table_name = @table))
	-- Se busca sobre la tabla de 4G, para evitar casos en los que no haya 4GONLY pero no sea por que se haya invalidado sino porque verdaderamente no exista.
	begin
		set @columnName =(SELECT COLUMN_NAME FROM dashboard.dbo.lcc_columns_tmp WHERE id=@it)
		if @columnName like '%entidad%'
		begin
			SET @SQLString =N'
				insert into dashboard.dbo.lcc_KPIs_noValid_step1
				select b.entidad,b.scope,b.mnc,b.meas_date, '''+@columnName+''' as KPIName, '''+@table+''' as TableName
				from [DASHBOARD].[dbo].lcc_entities_dashboard b
				left outer join [DASHBOARD].[dbo].'+@table4G+' a 
				on a.entidad'+@sufix+'=b.entidad and a.mnc'+@sufix+'=b.mnc and a.meas_date'+@sufix+'=b.meas_date
				where a.'+@columnName+' is null'

			EXECUTE sp_executesql @SQLString
		end 
		SET @SQLString =N'
			insert into dashboard.dbo.lcc_KPIs_tables
			values (''['+@columnName+']'','''+@table+''','''+@KPIGroup+''','''+@sufix+''',convert(int,('+convert(varchar,@it)+')))'
		EXECUTE sp_executesql @SQLString
		
		set @it=@it+1
	end
	set @it_tab=@it_tab+1
end

-- Los KPIs detectados se reducen a los KPIs clave para determinar los grupos de KPIs sobre los que realizar el update
exec dashboard.dbo.sp_lcc_dropifexists 'lcc_KPIs_noValid_step2'
select distinct a.*, b.id
into dashboard.dbo.lcc_KPIs_noValid_step2
from 
	(select a.*, c.KPIGroup,ROW_NUMBER() OVER(PARTITION BY entidad,mnc ORDER BY entidad,mnc,KPIGroup asc) AS id_KPIGroup
	from dashboard.dbo.lcc_KPIs_noValid_step1 a
	left outer join Dashboard.dbo.lcc_dashboard_TablesPre_u c
	on c.tableName=a.tableName
	where a.KPIName like 'entidad%' and typeTable not like '%_4G%') a
	,DASHBOARD.dbo.lcc_entities_dashboard_all_dates b
where b.entidad=a.entidad and a.Meas_Date = left((b.Meas_Date-200000),2) +'_' + right((b.Meas_Date-200000),2)

-- Se añade la fecha de medida antigua de la cual se obtendrá el update
exec dashboard.dbo.sp_lcc_dropifexists 'lcc_KPIs_noValid_step3'
select a.entidad,a.scope,a.mnc,a.meas_date,a.TableName,a.KPIGroup,b.KPIName,b.sufix,a.old_meas_Date,a.id_KPIGroup,b.id AS id_KPI
into dashboard.dbo.lcc_KPIs_noValid_step3
from (select a.*,left((b.Meas_Date-200000),2) +'_' + right((b.Meas_Date-200000),2) as OLD_Meas_date
	from dashboard.dbo.lcc_KPIs_noValid_step2 a
	,DASHBOARD.dbo.lcc_entities_dashboard_all_dates b
		where a.entidad=b.entidad and a.id-1=b.id) a
left outer join dashboard.dbo.lcc_KPIs_tables	b
on a.KPIGroup=b.KPIGroup 

-- Se conforma la tabla con los índices necesarios para recorrerla
exec dashboard.dbo.sp_lcc_dropifexists 'lcc_KPIs_noValid'
select b.*, a.id_entidad, '' as old_meas
into dashboard.dbo.lcc_KPIs_noValid
from 
	(select a.*,ROW_NUMBER() OVER(ORDER BY a.entidad asc) AS id_entidad
	from (select distinct entidad, mnc,meas_date
			from dashboard.dbo.lcc_KPIs_noValid_step1) a) a
	,dashboard.dbo.lcc_KPIs_noValid_step3 b
where b.entidad=a.entidad and a.mnc=b.mnc and a.meas_date=b.meas_date

--select * from dashboard.dbo.lcc_KPIs_noValid

-- Se realiza el update
set @it=1
while (@it <= (SELECT max(id_entidad) FROM [DASHBOARD].[dbo].lcc_KPIs_noValid ))
begin
	
	set @it_tab=1
	while (@it_tab <= (SELECT max(id_KPIGroup) FROM [DASHBOARD].[dbo].lcc_KPIs_noValid where @it=id_entidad ))
	begin
		set @j=1
		set @KPIName =''
		set @TableCheck=(SELECT TableName FROM [DASHBOARD].[dbo].lcc_KPIs_noValid where id_KPI=1 and @it_tab=id_KPIGroup and @it=id_entidad )
		
		set @tableOrig= (SELECT TableName FROM [DASHBOARD].[dbo].lcc_KPIs_noValid where @j=id_KPI and @it_tab=id_KPIGroup and @it=id_entidad )
		set @entidad=(SELECT entidad FROM [DASHBOARD].[dbo].lcc_KPIs_noValid where @j=id_KPI and @it_tab=id_KPIGroup and @it=id_entidad )
		set @mnc=(SELECT mnc FROM [DASHBOARD].[dbo].lcc_KPIs_noValid where @j=id_KPI and @it_tab=id_KPIGroup and @it=id_entidad )
		set @old_measdate = (SELECT old_meas_date FROM [DASHBOARD].[dbo].lcc_KPIs_noValid where @j=id_KPI and @it_tab=id_KPIGroup and @it=id_entidad )
		set @sufix = (SELECT sufix FROM [DASHBOARD].[dbo].lcc_KPIs_noValid where @j=id_KPI and @it_tab=id_KPIGroup and @it=id_entidad )
		set @measdate= (SELECT meas_date FROM [DASHBOARD].[dbo].lcc_KPIs_noValid where @j=id_KPI and @it_tab=id_KPIGroup and @it=id_entidad )

		if 	@TableCheck not like '%UPDATE%'
		begin
			-- Actualización de tablas intermedias, las que ya tienen los cálculos realizados.
			while (@j <= (SELECT max(id_KPI) FROM [DASHBOARD].[dbo].lcc_KPIs_noValid where @it=id_entidad and @it_tab=id_KPIGroup))
			begin
				if (SELECT KPIName FROM [DASHBOARD].[dbo].lcc_KPIs_noValid where @j=id_KPI and @it_tab=id_KPIGroup and @it=id_entidad ) not like '%entidad%'
					and (SELECT KPIName FROM [DASHBOARD].[dbo].lcc_KPIs_noValid where @j=id_KPI and @it_tab=id_KPIGroup and @it=id_entidad ) not like '%mnc%'
					and (SELECT KPIName FROM [DASHBOARD].[dbo].lcc_KPIs_noValid where @j=id_KPI and @it_tab=id_KPIGroup and @it=id_entidad ) not like '%meas_date%'
				begin
					if @j=1
						set @KPIName = (SELECT KPIName FROM [DASHBOARD].[dbo].lcc_KPIs_noValid where @j=id_KPI and @it_tab=id_KPIGroup and @it=id_entidad )
					else set @KPIName = @KPIName + ', ' + (SELECT KPIName FROM [DASHBOARD].[dbo].lcc_KPIs_noValid where @j=id_KPI and @it_tab=id_KPIGroup and @it=id_entidad )
				end
				set @j=1+@j
			end
			SET @SQLString =N'	
								insert into dashboard.dbo.'+ @tableOrig +'
								select ''' + @entidad + ''' as entidad' +@sufix + ', ''' + @mnc + ''' as mnc' +@sufix + ', ''' + @measdate + ''' as meas_Date' +@sufix + ' '+ @KPIName +'
								from dashboard.dbo.'+  @tableOrig  +' where entidad' +@sufix + ' like ''' + @entidad + ''' and mnc' +@sufix + ' like ''' + @mnc + ''' and meas_Date' +@sufix + ' like ''' + @old_measdate + ''''
			print @SQLString
			EXECUTE sp_executesql @SQLString
		end
		else
		begin
			-- Actualización de las tablas necesarias para el cálculo de estadísticos
			while (@j <= (SELECT max(id_KPI) FROM [DASHBOARD].[dbo].lcc_KPIs_noValid where @it=id_entidad and @it_tab=id_KPIGroup))
			begin
				if @j=1
					set @KPIName = (SELECT KPIName FROM [DASHBOARD].[dbo].lcc_KPIs_noValid where @j=id_KPI and @it_tab=id_KPIGroup and @it=id_entidad )
				else 
					set @KPIName = @KPIName + ', ' + (SELECT KPIName FROM [DASHBOARD].[dbo].lcc_KPIs_noValid where @j=id_KPI and @it_tab=id_KPIGroup and @it=id_entidad )
				
				set @j=1+@j
			end

			--SET @SQLString =N'	
			--					insert into dashboard.dbo.'+ @tableOrig +'
			--					select '+ @KPIName +'
			--					from dashboard.dbo.'+  @tableOrig  +' where entidad' +@sufix + ' like ''' + @entidad + ''' and mnc' +@sufix + ' like ''' + @mnc + ''' and meas_Date' +@sufix + ' like ''' + @old_measdate + ''''
			--print @SQLString
			--EXECUTE sp_executesql @SQLString

			SET @SQLString =N'	
								select '+ @KPIName +'
								into dashboard.dbo.aux
								from dashboard.dbo.'+  @tableOrig  +' where entidad' +@sufix + ' like ''' + @entidad + ''' and mnc' +@sufix + ' like ''' + @mnc + ''' and meas_Date' +@sufix + ' like ''' + @old_measdate + '''
								
								update dashboard.dbo.aux
								set Meas_date = '''+@measdate+'''

								insert into dashboard.dbo.'+ @tableOrig +'
								select * from dashboard.dbo.aux

								drop table dashboard.dbo.aux'
			print @SQLString
			EXECUTE sp_executesql @SQLString

		end

		set @it_tab=1+@it_tab

	end 
	set @it=1+@it
end

-- Limpieza de tablas temporales
exec dashboard.dbo.sp_lcc_dropifexists 'lcc_KPIs_noValid_step1'
exec dashboard.dbo.sp_lcc_dropifexists 'lcc_dashboard_TablesPre_u'
exec dashboard.dbo.sp_lcc_dropifexists 'lcc_columns_tmp'
exec dashboard.dbo.sp_lcc_dropifexists 'lcc_KPIs_noValid_step2'
exec dashboard.dbo.sp_lcc_dropifexists 'lcc_KPIs_noValid_step3'
exec dashboard.dbo.sp_lcc_dropifexists 'lcc_KPIs_tables'

-- KPIs modificados
--select * from dashboard.dbo.lcc_KPIs_noValid
