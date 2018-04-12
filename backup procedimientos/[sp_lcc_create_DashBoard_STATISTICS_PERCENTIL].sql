USE [master]
GO
/****** Object:  StoredProcedure [dbo].[sp_lcc_create_DashBoard_STATISTICS_PERCENTIL]    Script Date: 29/05/2017 14:12:35 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER procedure [dbo].[sp_lcc_create_DashBoard_STATISTICS_PERCENTIL] 
	@database as varchar(256)
	,@sheetTech as varchar(256)
	,@table as varchar(256)
	,@step as float
	,@N_ranges as int
	,@ini_range as float
	,@Code as varchar(256)
	,@percentil as float
	,@last_range as bit
as

-------------------------------------------------------------------------------
-- Definición del cálculo del percentil para una distribución

-- Una vez establecida la clase en la que se encuentra el percentil (es decir, 
-- el intervalo cuya frecuencia acumulado es mayor estricto que K*N/100, siendo K=1,2..99 el percentil a calcular):
--            Percentil= L_i + (K*N/100-F_i-1)/f_i *a_i

-- L_i = límite inferior de la clase donde se encuentra el percentil
-- N = suma de las frecuencias absolutas
-- F_i-1 = frecuencia acumulada anterior a la clase donde se encuentra el percentil
-- f_i = frecuencia absoluta de la clase percentil
-- a_i = amplitud de la clase
-- K = percentil a calcular

-------------------------------------------------------------------------------
-- Declaración de variables
--declare @database as varchar(256) = '[AGGRData4G]'
--declare @sheetTech as varchar(256)	= '' -- or '_4G'
--declare @table as varchar(256) = 'lcc_aggr_sp_MDD_Data_DL_Thput_CE_LTE'
--declare @step float= 5
--declare @N_ranges int=31
--declare @Code varchar (256)='Mbps'
--declare @ini_range as float=0
--declare @percentil as float=0.95
--declare @last_range as bit=1

declare @i int =0
declare @field as varchar(256)
DECLARE @SQLString nvarchar(4000)
declare @aggr as varchar(256)

-------------------------------------------------------------------------------
-- Creación de la tabla transpuesta

-- Se crea la estructura de la tabla con los campos base
set @SQLString= N'
				exec dashboard.dbo.sp_lcc_dropifexists '''+@table+'_transpose_step1''
				Create table [DASHBOARD].[dbo].['+@table+'_transpose_step1](
						mnc varchar(256),
						entidad varchar(256),
						Meas_Date varchar(256),
						Aggr float,
						id int,
						range_inf float
						)'
EXECUTE sp_executesql @SQLString

-- Se insertan las filas por rangos (teniendo en cuenta el paso del histograma y el número total de rangos)
while @i< @N_ranges -1
begin
	if @step*@i = 0 
		set @field= convert(varchar,@ini_range)+'-' + convert(varchar,@step+@ini_range)
	else set @field= convert(varchar,@step*@i+@ini_range) + '-' + convert(varchar,@step*(@i+1)+@ini_range)

	if @Code in ('NB','WB')
		set @field=@field+' '
	else if @Code in ('Mbps')
		set @field= ' '+@field
	else if @Code in ('overall')
		set @field= @field+' '
	else set @field= ' '+@field+' '

	-- Para el caso de voz Aggr_overall hay que sumar dos campos
	if @Code <> 'overall'
		set @aggr ='sum(['+@field+@Code+'])'
	else 
		set @aggr ='sum(['+@field+'WB]) + sum(['+@field+'NB])'
	
	set @SQLString= N'
			declare @Code as varchar(256)=''' +@Code + '''
			insert into [DASHBOARD].[dbo].['+@table+'_transpose_step1]
			select mnc,entidad,Meas_Date
					,'+@aggr+' as Aggr
					,'+convert(varchar,@i)+' as id
					,'+convert(varchar,@ini_range+@step*@i)+' as range_inf
			from '+ @database + '.[dbo].['+@table+']
			group by mnc,Meas_Date,entidad
			order by id'
	set @i=@i+1
	EXECUTE sp_executesql @SQLString
end

-- Se añade el último rango
if @last_range= 1
begin
	if @Code in ('Mbps')
		set @field=' >' + convert(varchar,@step*(@N_ranges-1))
	else set @field=' >' + convert(varchar,@step*(@N_ranges-1))+' '
	set @SQLString= N'
					insert into [DASHBOARD].[dbo].['+@table+'_transpose_step1]
					select mnc,entidad,Meas_Date
							,sum(['+@field+@Code+']) as Aggr
							,'+convert(varchar,@N_ranges-1)+' as id
							,'+convert(varchar,@ini_range+@step*(@N_ranges-1))+' as range_inf
					from '+ @database + '.[dbo].['+@table+']
					group by mnc,Meas_Date,entidad
					order by entidad,id'
	EXECUTE sp_executesql @SQLString
end
else
begin
	set @field= convert(varchar,@step*(@N_ranges-1)+@ini_range) + '-' + convert(varchar,@step*(@N_ranges)+@ini_range)
	if @Code in ('NB','WB')
		set @field=@field + ' '
	else if @Code in ('Mbps','Ms')
		set @field= ' '+@field
	else if @Code in ('overall')
		set @field= @field+' '
	else set @field= ' '+@field + ' '

	-- Para el caso de voz Aggr_overall hay que sumar dos campos
	if @Code <> 'overall'
		set @aggr ='sum(['+@field+@Code+'])'
	else 
		set @aggr ='sum(['+@field+'WB]) + sum(['+@field+'NB])'

	set @SQLString= N'
			insert into [DASHBOARD].[dbo].['+@table+'_transpose_step1]
			select mnc,entidad,Meas_Date
					,'+@aggr+' as Aggr
					,'+convert(varchar,@N_ranges-1)+' as id
					,'+convert(varchar,@ini_range+@step*(@N_ranges-1))+' as range_inf
			from '+ @database + '.[dbo].['+@table+']
			group by mnc,Meas_Date,entidad
			order by id'
	EXECUTE sp_executesql @SQLString
end

--set @SQLString= N'
--			select * from  [DASHBOARD].[dbo].['+@table+'_transpose_step1]'
--EXECUTE sp_executesql @SQLString


---------------------------------------------------------------------------------
-- Cálculo de percentiles
-- Se añaden los campos calculados CDF y total
set @SQLString= N'			
				exec dashboard.dbo.sp_lcc_dropifexists '''+@table+'_transpose''
				select a.entidad,a.mnc,a.Meas_Date,a.id,a.range_inf, a.aggr,
					1.0*(select sum(b.aggr) 
						from [DASHBOARD].[dbo].['+@table+'_transpose_step1] b
						where b.entidad=a.entidad and b.mnc=a.mnc and b.Meas_Date=a.Meas_Date and b.id<=a.id) as CDF,
					nullif((select sum(b.aggr) 
						from [DASHBOARD].[dbo].['+@table+'_transpose_step1] b
						where b.entidad=a.entidad and b.mnc=a.mnc and b.Meas_Date=a.Meas_Date),0) as total
				into [DASHBOARD].[dbo].['+@table+'_transpose]
				from [DASHBOARD].[dbo].['+@table+'_transpose_step1] a
				group by a.mnc,a.entidad,a.Meas_Date,a.id,a.range_inf,a.aggr
				order by a.entidad,a.mnc,a.id'
EXECUTE sp_executesql @SQLString

-- Se identifica el percentil a calcular
if @Code in ('Mbps')
begin
	set @SQLString= N'		
					exec dashboard.dbo.sp_lcc_dropifexists ''lcc_PERCENTIL'+@sheetTech+'_step1''
					select a.entidad, a.mnc, a.Meas_Date,a.id
					into [DASHBOARD].[dbo].[lcc_PERCENTIL'+@sheetTech+'_step1]
					from [DASHBOARD].[dbo].['+@table+'_transpose] a,
						(select entidad,mnc,Meas_Date,id,range_inf,total*'+convert(varchar,@percentil)+' as SSum,CDF	
						from [DASHBOARD].[dbo].['+@table+'_transpose]
						where CDF>total*'+convert(varchar,@percentil)+') b
					where a.entidad=b.entidad and a.mnc=b.mnc and a.Meas_Date=b.Meas_Date
					group by a.entidad, a.mnc, a.Meas_Date,a.id  
					having a.id=min(b.id)'
end
else
begin
	set @SQLString= N'		
					exec dashboard.dbo.sp_lcc_dropifexists ''lcc_PERCENTIL'+@sheetTech+'_step1''
					select a.entidad, a.mnc, a.Meas_Date,a.id
					into [DASHBOARD].[dbo].[lcc_PERCENTIL'+@sheetTech+'_step1]
					from [DASHBOARD].[dbo].['+@table+'_transpose] a,
						(select entidad,mnc,Meas_Date,id,range_inf,total*'+convert(varchar,@percentil)+' as SSum,CDF	
						from [DASHBOARD].[dbo].['+@table+'_transpose]
						where CDF>=total*'+convert(varchar,@percentil)+') b
					where a.entidad=b.entidad and a.mnc=b.mnc and a.Meas_Date=b.Meas_Date
					group by a.entidad, a.mnc, a.Meas_Date,a.id  
					having a.id=min(b.id)'
end
EXECUTE sp_executesql @SQLString

-- Se calculan el percentil correspondiente
set @SQLString= N'
				exec dashboard.dbo.sp_lcc_dropifexists ''lcc_PERCENTIL' + @sheetTech +'''
				select a.entidad, a.mnc, a.Meas_Date
					,a.range_inf+((a.total*'+convert(varchar,@percentil)+')-(a.CDF-a.Aggr))*'+convert(varchar,@step*1)+'/a.Aggr as Percentil
				into [DASHBOARD].[dbo].[lcc_PERCENTIL' + @sheetTech +']
				from [DASHBOARD].[dbo].['+@table+'_transpose] a,
					[DASHBOARD].[dbo].[lcc_PERCENTIL'+@sheetTech+'_step1] b
					where a.entidad=b.entidad and a.mnc=b.mnc and a.Meas_Date=b.Meas_Date and a.id=b.id'
EXECUTE sp_executesql @SQLString

---------------------------------------------------------------------------------
-- Limpieza de tablas temporales
set @SQLString= N'
				exec dashboard.dbo.sp_lcc_dropifexists '''+@table+'_transpose_step1''' +
				' exec dashboard.dbo.sp_lcc_dropifexists '''+@table+'_transpose'''	+
				' exec dashboard.dbo.sp_lcc_dropifexists ''lcc_PERCENTIL'+@sheetTech+'_step1'''
EXECUTE sp_executesql @SQLString

