USE [master]
GO
/****** Object:  StoredProcedure [dbo].[sp_lcc_create_DashBoard_UPDATE_INVALID_MEASUR_ROUNDS]    Script Date: 13/11/2017 10:55:07 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


ALTER procedure [dbo].[sp_lcc_create_DashBoard_UPDATE_INVALID_MEASUR_ROUNDS] 
	@nameSheet as varchar(256)
	,@typeTable as varchar(256)
	,@database as varchar(256)
as
---------------------------------------------------------------------------------
--Inicialización de variables
--exec [dbo].[sp_lcc_create_DashBoard_TABLES_PRE_AGGR] '[AGGRData4G_road]','4G'
----exec [dbo].[sp_lcc_create_DashBoard_TABLES_PRE] '[AGGRData4G_road]',5,'ROAD','4G_road'

--declare @nameSheet as varchar(256) = ''
--declare @typeTable as varchar(256)='DATA'
--declare @database as varchar(256) = 'AGGRdata4G'

set @database= replace(replace(@database,'[',''),']','')

declare @ColumnName as varchar(256)
declare @table as varchar(256)
declare @sufix as varchar(256)
declare @it int =1
declare @it_tab int =1
declare @j int =1
DECLARE @SQLString nvarchar(max)
declare @KPIName varchar(max)
declare @tableOrig varchar(256)
declare @KPIGroup varchar (256)
declare @entidad varchar(256)
declare @mnc varchar(256)
declare @old_measdate varchar(256)
declare @measdate varchar(256)
declare @old_entidad varchar(256)
declare @KPINameCheck varchar(256)
declare @table4G varchar(256)
declare @old_measyear as varchar(256)

declare @sheetTech varchar(256) =@nameSheet
declare @tech varchar(256) = '_LTE'

-- Tabla de operadores
exec dashboard.dbo.sp_lcc_dropifexists 'lcc_Operator_dashboard'
create table [DASHBOARD].[dbo].lcc_Operator_dashboard(
		[mnc][varchar](256) NULL,
		[OPERATOR][varchar](256) NULL,
		[ORDER_OPERATOR][int]
)

insert into [DASHBOARD].[dbo].lcc_Operator_dashboard
values('01','VODAFONE',1)
,('07','MOVISTAR',2)
,('03','ORANGE',3)
,('04','YOIGO',4)

-- Tabla con los KPIs invalidados
exec dashboard.dbo.sp_lcc_dropifexists 'lcc_KPIs_noValid_step1'
create table dashboard.dbo.lcc_KPIs_noValid_step1 (
	entidad varchar(256)
	,scope varchar(256)
	,mnc varchar(256)
	,meas_date varchar(256)
	,meas_year  varchar(256)
	,meas_week  varchar(256)
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
exec dashboard.dbo.sp_lcc_dropifexists 'lcc_dashboard_TablesPre_u_up'
create table [Dashboard].[dbo].[lcc_dashboard_TablesPre_u_up](
	Tablename varchar(4000)
	,id int
	,typeTable varchar(256)
	,sufix varchar(256)
	,KPIGroup varchar(256)
)

SET @SQLString =N'
		insert into Dashboard.dbo.lcc_dashboard_TablesPre_u_up
		values (''UPDATE_'+@database+'_lcc_aggr_sp_MDD_Data_DL_Thput_CE'+@sheetTech+''',1,''DATA'','''',''DL_CE'')			-- Data_DL_Thput_CE
			,(''UPDATE_'+@database+'_lcc_aggr_sp_MDD_Data_DL_Thput_CE'+@tech+@sheetTech+''',2,''DATA'','''',''DL_CE_LTE'')	-- Data_DL_Thput_CE para estadísticos
			,(''UPDATE_'+@database+'_lcc_aggr_sp_MDD_Data_UL_Thput_CE'+@sheetTech+''',3,''DATA'','''',''UL_CE'')				-- Data_UL_Thput_CE
			,(''UPDATE_'+@database+'_lcc_aggr_sp_MDD_Data_UL_Thput_CE'+@tech+@sheetTech+''',4,''DATA'','''',''UL_CE_LTE'')	-- Data_UL_Thput_CE para estadísticos
			,(''UPDATE_'+@database+'_lcc_aggr_sp_MDD_Data_DL_Thput_NC'+@sheetTech+''',5,''DATA'','''',''DL_NC'')				-- Data_DL_Thput_NC
			,(''UPDATE_'+@database+'_lcc_aggr_sp_MDD_Data_DL_Thput_NC'+@tech+@sheetTech+''',6,''DATA'','''',''DL_NC_LTE'')	-- Data_DL_Thput_NC para estadísticos
			,(''UPDATE_'+@database+'_lcc_aggr_sp_MDD_Data_UL_Thput_NC'+@sheetTech+''',7,''DATA'','''',''UL_NC'')				-- Data_UL_Thput_NC
			,(''UPDATE_'+@database+'_lcc_aggr_sp_MDD_Data_UL_Thput_NC'+@tech+@sheetTech+''',8,''DATA'','''',''UL_NC_LTE'')	-- Data_UL_Thput_NC para estadísticos
			,(''UPDATE_'+@database+'_lcc_aggr_sp_MDD_Data_Ping'+@sheetTech+''',9,''DATA'','''',''LAT'')						-- Data_Latency
			,(''UPDATE_'+@database+'_lcc_aggr_sp_MDD_Data_Web'+@sheetTech+''',10,''DATA'','''',''WEB'')						-- Data_Web_Browsing
			,(''UPDATE_'+@database+'_lcc_aggr_sp_MDD_Data_Youtube'+@sheetTech+''',11,''DATA'','''',''YTB_SD'')				-- Data_Youtube SD
			,(''UPDATE_'+@database+'_lcc_aggr_sp_MDD_Data_Youtube_HD'+@sheetTech+''',12,''DATA'','''',''YTB_HD'')			-- Data_Youtube HD
			,(''UPDATE_'+@database+'_lcc_aggr_sp_MDD_Voice_Llamadas'+@sheetTech+''',1,''VOICE'','''',''CALLS'')						-- Voice_calls
			,(''UPDATE_'+@database+'_lcc_aggr_sp_MDD_Voice_CallSetupTime_CompletedCalls'+@sheetTech+''',2,''VOICE'','''',''CST'')	-- Voice_CST
			,(''UPDATE_'+@database+'_lcc_aggr_sp_MDD_Voice_PESQ'+@sheetTech+''',3,''VOICE'','''',''MOS'')							-- Voice_MOS
			------- Tablas 4G para comprobar sobre ellas --------------------
			,(''UPDATE_'+@database+'_lcc_aggr_sp_MDD_Data_DL_Thput_CE'',1,''DATA_4G'','''',''DL_CE'')			-- Data_DL_Thput_CE
			,(''UPDATE_'+@database+'_lcc_aggr_sp_MDD_Data_DL_Thput_CE'+@tech+''',2,''DATA_4G'','''',''DL_CE_LTE'')	-- Data_DL_Thput_CE para estadísticos
			,(''UPDATE_'+@database+'_lcc_aggr_sp_MDD_Data_UL_Thput_CE'',3,''DATA_4G'','''',''UL_CE'')				-- Data_UL_Thput_CE
			,(''UPDATE_'+@database+'_lcc_aggr_sp_MDD_Data_UL_Thput_CE'+@tech+''',4,''DATA_4G'','''',''UL_CE_LTE'')	-- Data_UL_Thput_CE para estadísticos
			,(''UPDATE_'+@database+'_lcc_aggr_sp_MDD_Data_DL_Thput_NC'',5,''DATA_4G'','''',''DL_NC'')				-- Data_DL_Thput_NC
			,(''UPDATE_'+@database+'_lcc_aggr_sp_MDD_Data_DL_Thput_NC'+@tech+''',6,''DATA_4G'','''',''DL_NC_LTE'')	-- Data_DL_Thput_NC para estadísticos
			,(''UPDATE_'+@database+'_lcc_aggr_sp_MDD_Data_UL_Thput_NC'',7,''DATA_4G'','''',''UL_NC'')				-- Data_UL_Thput_NC
			,(''UPDATE_'+@database+'_lcc_aggr_sp_MDD_Data_UL_Thput_NC'+@tech+''',8,''DATA_4G'','''',''UL_NC_LTE'')	-- Data_UL_Thput_NC para estadísticos
			,(''UPDATE_'+@database+'_lcc_aggr_sp_MDD_Data_Ping'',9,''DATA_4G'','''',''LAT'')						-- Data_Latency
			,(''UPDATE_'+@database+'_lcc_aggr_sp_MDD_Data_Web'',10,''DATA_4G'','''',''WEB'')						-- Data_Web_Browsing
			,(''UPDATE_'+@database+'_lcc_aggr_sp_MDD_Data_Youtube'',11,''DATA_4G'','''',''YTB_SD'')				-- Data_Youtube SD
			,(''UPDATE_'+@database+'_lcc_aggr_sp_MDD_Data_Youtube_HD'',12,''DATA_4G'','''',''YTB_HD'')			-- Data_Youtube HD
			,(''UPDATE_'+@database+'_lcc_aggr_sp_MDD_Voice_Llamadas'',1,''VOICE_4G'','''',''CALLS'')						-- Voice_calls
			,(''UPDATE_'+@database+'_lcc_aggr_sp_MDD_Voice_CallSetupTime_CompletedCalls'',2,''VOICE_4G'','''',''CST'')	-- Voice_CST
			,(''UPDATE_'+@database+'_lcc_aggr_sp_MDD_Voice_PESQ'',3,''VOICE_4G'','''',''MOS'')							-- Voice_MOS'
EXECUTE sp_executesql @SQLString

print 'sp_lcc_create_DashBoard_UPDATE_INVALID_MEASUR_ROUNDS Bucle 1: detectar los KPIs a null'
-- Bucle para detectar los KPIs a null
set @it_tab=1
while (@it_tab <= (SELECT max(id) FROM [DASHBOARD].[dbo].lcc_dashboard_TablesPre_u_up where [TYPETABLE]=@typeTable))
begin	
	set @table = (select Tablename from [DASHBOARD].[dbo].lcc_dashboard_TablesPre_u_up where id = @it_tab and [TYPETABLE]=@typeTable)
	set @table4G= (select Tablename from [DASHBOARD].[dbo].lcc_dashboard_TablesPre_u_up where id = @it_tab and [TYPETABLE]=@typeTable+'_4G')
	set @sufix= (select sufix from [DASHBOARD].[dbo].lcc_dashboard_TablesPre_u_up where id = @it_tab and [TYPETABLE]=@typeTable)
	set @KPIGroup= (select KPIGroup from [DASHBOARD].[dbo].lcc_dashboard_TablesPre_u_up where id = @it_tab and [TYPETABLE]=@typeTable)
	-- Columnas de las tablas a chequear
	exec dashboard.dbo.sp_lcc_dropifexists 'lcc_columns_tmp'
	SELECT  IDENTITY(int,1,1) id,COLUMN_NAME
	into dashboard.dbo.lcc_columns_tmp
	FROM dashboard.INFORMATION_SCHEMA.COLUMNS
	WHERE table_name = @table
	ORDER BY ORDINAL_POSITION

	set @it = 1
	while (@it <= (SELECT count(COLUMN_NAME) FROM dashboard.INFORMATION_SCHEMA.COLUMNS WHERE table_name = @table))
	-- Se busca sobre la tabla de 4G, para evitar casos en los que no haya 4GONLY pero no sea por que se haya invalidado sino porque verdaderamente no exista.
	begin
		set @columnName =(SELECT COLUMN_NAME FROM dashboard.dbo.lcc_columns_tmp WHERE id=@it)
		if @columnName like 'entidad'
		begin
			SET @SQLString =N'
				insert into dashboard.dbo.lcc_KPIs_noValid_step1
				select b.entidad_orig,b.scope,b.mnc,b.meas_date,2000 + b.meas_year as Meas_year,replace(b.meas_week,''W'','''') as meas_week,'''+@columnName+''' as KPIName, '''+@table+''' as TableName
				from (select b.*,e.*  from 
						[DASHBOARD].[dbo].lcc_dashboard_rounds b,
						[DASHBOARD].[dbo].lcc_Operator_dashboard e) b
				left outer join [DASHBOARD].[dbo].'+@table4G+' a 
				on a.entidad'+@sufix+'=b.entidad_orig and a.meas_date'+@sufix+'=b.meas_date and a.mnc'+@sufix+'=b.mnc
				where a.['+@columnName+'] is null'
			print @SQLString
			EXECUTE sp_executesql @SQLString
		end
		SET @SQLString =N'
			insert into dashboard.dbo.lcc_KPIs_tables
			values (''['+@columnName+']'','''+@table+''','''+@KPIGroup+''','''+@sufix+''',convert(int,'+convert(varchar,@it)+'))'
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
	left outer join Dashboard.dbo.lcc_dashboard_TablesPre_u_up c
	on c.tableName=a.tableName
	where a.KPIName like 'entidad%' and [TYPETABLE]=@typeTable) a
	,DASHBOARD.dbo.lcc_entities_dashboard_all_dates b
where b.entidad=a.entidad and a.meas_week = b.[week] and a.meas_year =b.[year]

-- Se añade la fecha de medida antigua de la cual se obtendrá el update
exec dashboard.dbo.sp_lcc_dropifexists 'lcc_KPIs_noValid_step3'
select a.entidad,a.scope,a.mnc,a.meas_date,a.meas_year,a.meas_week,a.TableName,a.KPIGroup,b.KPIName,b.sufix,a.old_meas,a.old_meas_date,a.id_KPIGroup,b.id AS id_KPI
into dashboard.dbo.lcc_KPIs_noValid_step3
		from (select a.*, b.entidad as OLD_Meas,left((b.Meas_Date-200000),2) +'_' + right((b.Meas_Date-200000),2) as OLD_Meas_date
		from dashboard.dbo.lcc_KPIs_noValid_step2 a
		,DASHBOARD.dbo.lcc_entities_dashboard_all_dates b
			where substring(a.entidad,1,CHARINDEX('-R',a.entidad)-1)=b.Entidad_SRonda and a.id-1=b.id) a
		left outer join dashboard.dbo.lcc_KPIs_tables	b
		on a.KPIGroup=b.KPIGroup

-- Se conforma la tabla con los índices necesarios para recorrerla
exec dashboard.dbo.sp_lcc_dropifexists 'lcc_KPIs_noValid_temp_u'
select b.*, a.id_entidad
into dashboard.dbo.lcc_KPIs_noValid_temp_u
from 
	(select a.*,ROW_NUMBER() OVER(ORDER BY a.entidad,meas_year,meas_week asc) AS id_entidad
	from (select distinct entidad, mnc,meas_date,meas_year,meas_week
			from dashboard.dbo.lcc_KPIs_noValid_step1) a) a
	,dashboard.dbo.lcc_KPIs_noValid_step3 b
where b.entidad=a.entidad and a.mnc=b.mnc and a.meas_date=b.meas_date

-- Se realiza el update
set @it=1
while (@it <= (SELECT max(id_entidad) FROM [DASHBOARD].[dbo].lcc_KPIs_noValid_temp_u ))
begin
	set @it_tab=1
	while (@it_tab <= (SELECT max(id_KPIGroup) FROM [DASHBOARD].[dbo].lcc_KPIs_noValid_temp_u where @it=id_entidad ))
	begin
		set @j=1
		set @KPIName =''
		while (@j <= (SELECT max(id_KPI) FROM [DASHBOARD].[dbo].lcc_KPIs_noValid_temp_u where @it=id_entidad and @it_tab=id_KPIGroup))
		begin
			
			set @entidad=(SELECT entidad FROM [DASHBOARD].[dbo].lcc_KPIs_noValid_temp_u where @j=id_KPI and @it_tab=id_KPIGroup and @it=id_entidad )
			set @mnc=(SELECT mnc FROM [DASHBOARD].[dbo].lcc_KPIs_noValid_temp_u where @j=id_KPI and @it_tab=id_KPIGroup and @it=id_entidad )
			set @old_measdate = (SELECT old_meas_date FROM [DASHBOARD].[dbo].lcc_KPIs_noValid_temp_u where @j=id_KPI and @it_tab=id_KPIGroup and @it=id_entidad )
			set @tableOrig= (SELECT TableName FROM [DASHBOARD].[dbo].lcc_KPIs_noValid_temp_u where @j=id_KPI and @it_tab=id_KPIGroup and @it=id_entidad )
			set @old_entidad = (SELECT old_meas FROM [DASHBOARD].[dbo].lcc_KPIs_noValid_temp_u where @j=id_KPI and @it_tab=id_KPIGroup and @it=id_entidad )
			set @measdate= (SELECT meas_date FROM [DASHBOARD].[dbo].lcc_KPIs_noValid_temp_u where @j=id_KPI and @it_tab=id_KPIGroup and @it=id_entidad )
			set @old_measyear = (SELECT left(old_meas_date,2) FROM [DASHBOARD].[dbo].lcc_KPIs_noValid_temp_u where @j=id_KPI and @it_tab=id_KPIGroup and @it=id_entidad )
			
			set @KPINameCheck=(SELECT KPIName FROM [DASHBOARD].[dbo].lcc_KPIs_noValid_temp_u where @j=id_KPI and @it_tab=id_KPIGroup and @it=id_entidad ) 

			if @j=1 
			begin
				if replace(replace(@KPINameCheck,'[',''),']','') like 'entidad'  set @KPIName ='' + @entidad +''' as entidad' 
				else if replace(replace(@KPINameCheck,'[',''),']','') like 'mnc' set @KPIName =''+ @mnc +''' as mnc' 
				else if replace(replace(@KPINameCheck,'[',''),']','') like 'meas_date' set @KPIName =''+ @old_measdate +''' as meas_Date'
				else 
					set @KPIName = (SELECT KPIName FROM [DASHBOARD].[dbo].lcc_KPIs_noValid_temp_u where @j=id_KPI and @it_tab=id_KPIGroup and @it=id_entidad )
			end
			else 
			begin
				if replace(replace(@KPINameCheck,'[',''),']','') like 'entidad' 
					set @KPIName = @KPIName + ',''' + @entidad +''' as entidad' 
				else if replace(replace(@KPINameCheck,'[',''),']','') like 'mnc' 
					set @KPIName = @KPIName + ',''' + @mnc +''' as mnc' 
				else if replace(replace(@KPINameCheck,'[',''),']','') like 'meas_date' 
					set @KPIName = @KPIName + ',''' + @old_measdate +''' as Meas_date' 
				else
					set @KPIName = @KPIName + ',' + (SELECT KPIName FROM [DASHBOARD].[dbo].lcc_KPIs_noValid_temp_u where @j=id_KPI and @it_tab=id_KPIGroup and @it=id_entidad )
			end	
			set @j=1+@j
		end

		SET @SQLString =N'	
							insert into dashboard.dbo.'+ @tableOrig +'
							select '+ @KPIName +'
							from dashboard.dbo.'+  @tableOrig  +' where entidad' +@sufix + ' like ''' + @old_entidad + ''' and mnc' +@sufix + ' like ''' + @mnc + ''' and left(meas_date,2) = ' + @old_measyear
		EXECUTE sp_executesql @SQLString
		print @SQLString
		set @it_tab=1+@it_tab
	end 

			if @entidad=(SELECT distinct old_meas FROM [DASHBOARD].[dbo].lcc_KPIs_noValid_temp_u where @it+1=id_entidad )
			begin
				--Actualización de la fecha de medida por si hay dos medidas invalidadas seguidas
				update [DASHBOARD].[dbo].lcc_KPIs_noValid_temp_u
				set old_meas_date = @old_measdate
				where old_meas like @entidad
			end 
	set @it=1+@it

end


if @database like '%4G%road%'
	set @sheetTech =@sheetTech +'_road'
else if @database like '%3G%'
	set @sheetTech =@sheetTech +'_3G'
else if @database like '%4G%'
	set @sheetTech =@sheetTech +'_railway'

-- KPIs modificados
SET @SQLString =N'
			exec dashboard.dbo.sp_lcc_dropifexists ''lcc_KPIs_noValid' + @sheetTech +'''
			select * 
			into dashboard.dbo.lcc_KPIs_noValid' + @sheetTech + '
			from dashboard.dbo.lcc_KPIs_noValid_temp_u'
print @SQLString
EXECUTE sp_executesql @SQLString

--select * from dashboard.dbo.lcc_KPIs_noValid_temp_u


---- Limpieza de tablas temporales
exec dashboard.dbo.sp_lcc_dropifexists 'lcc_KPIs_noValid_step1'
exec dashboard.dbo.sp_lcc_dropifexists 'lcc_dashboard_TablesPre_u_up'
exec dashboard.dbo.sp_lcc_dropifexists 'lcc_columns_tmp'
exec dashboard.dbo.sp_lcc_dropifexists 'lcc_KPIs_noValid_step2'
exec dashboard.dbo.sp_lcc_dropifexists 'lcc_KPIs_noValid_step3'
exec dashboard.dbo.sp_lcc_dropifexists 'lcc_KPIs_tables'
exec dashboard.dbo.sp_lcc_dropifexists 'lcc_KPIs_noValid_temp_u'
--select * from dashboard.dbo.lcc_KPIs_noValid
