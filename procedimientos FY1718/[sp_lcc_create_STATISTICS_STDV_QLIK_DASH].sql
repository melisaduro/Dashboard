USE [AddedValue]
GO
/****** Object:  StoredProcedure [dbo].[sp_lcc_create_STATISTICS_STDV_QLIK_DASH]    Script Date: 12/04/2018 10:21:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER procedure [dbo].[sp_lcc_create_STATISTICS_STDV_QLIK_DASH] 
	@table as varchar(256)
	,@step float
	,@N_ranges int
	,@ini_range as float
as

-------------------------------------------------------------------------------
-- Definición del cálculo de la desviación típica para una distribución (con la corrección de Bessel)

--            Desv= sqrt( (SUM (x_i - x_m)^2 * f_i) /(N-1) )

-- sqrt =  raíz cuadrada
-- SUM =  sumatorio desde i=1 hasta n (siendo n el número total de intervalos)

-- x_i = valor medio del intervalo 
-- f_i = frecuencia absoluta de la clase
-- N = total de muestras en todos los intervalos = suma de las frecuencias absolutas
-- x_m =  media de todas las clases = SUM(x_i*f_i)/N

-------------------------------------------------------------------------------
------ Declaración de variables
--declare @table as varchar(256) = '_Percentiles_O'
--declare @step float= 1
--declare @N_ranges int=33
--declare @ini_range as float=0


declare @i int =0
declare @field as varchar(256)
DECLARE @SQLString nvarchar(4000)

-------------------------------------------------------------------------------
-- Creación de la tabla transpuesta

-- Se crea la estructura de la tabla con los campos base
set @SQLString= N'
				exec sp_lcc_dropifexists '''+@table+'_transpose_step1''
				Create table ['+@table+'_transpose_step1](
						mnc varchar(256),
						entidad varchar(256),
						Date_Reporting varchar(256),
						Report_type varchar(256),
						Test_type [varchar](255),
						Meas_Tech [varchar](255),
						id int,
						x_i float,
						f_i float,
						xf float
						)'
--print @SQLString
EXECUTE sp_executesql @SQLString

-- Se insertan las filas por rangos con su correspondiente conteo (teniendo en cuenta el paso del histograma y el número total de rangos)
while @i<= @N_ranges-1
begin
	declare @aggr as int = @i+1
	set @SQLString= N'
					insert into ['+@table+'_transpose_step1]
					select mnc,
						   entidad,
						   Date_Reporting,
						   Report_type,
						   Test_type,
						   Meas_Tech,
						   '+convert(varchar,@i)+' as id,
						   '+convert(varchar,(@step*@i+@ini_range+@step/2))+' as x_i,
							sum(['+convert(varchar,(@aggr))+']) as f_i,
							'+convert(varchar,(@step*@i+@ini_range+@step/2))+' * (sum(['+convert(varchar,(@aggr))+'])) as xf
					from ['+@table+']
					group by mnc,Date_Reporting,entidad,Report_type,Test_type,Meas_Tech
					order by id'
	set @i=@i+1
	--print @SQLString
	EXECUTE sp_executesql @SQLString
end
--select * from _Desviaciones_Voice_transpose_step1
---------------------------------------------------------------------------------
---- Cálculo de la desviación típica
---- Se añaden los campos calculados necesarios para obtener la desviación típica
SET @SQLString= N'
				exec sp_lcc_dropifexists '''+@table+'_transpose''
				select	a.entidad,
						a.mnc,
						a.Date_Reporting,
						a.Report_type,
						a.Test_type,
						a.Meas_Tech,
						nullif((select sum(b.f_i) 
								from ['+@table+'_transpose_step1] b
								where b.entidad=a.entidad and b.mnc=a.mnc and b.Date_Reporting=a.Date_Reporting and b.Test_type=a.Test_type and b.Meas_Tech=a.Meas_Tech and b.Report_type=a.Report_type
								),0) as N,
						nullif((select sum(b.xf) 
								from ['+@table+'_transpose_step1] b
								where b.entidad=a.entidad and b.mnc=a.mnc and b.Date_Reporting=a.Date_Reporting and b.Test_type=a.Test_type and b.Meas_Tech=a.Meas_Tech and b.Report_type=a.Report_type
								),0) as xf_total,
						nullif((select sum(b.xf) 
								from ['+@table+'_transpose_step1] b
								where b.entidad=a.entidad and b.mnc=a.mnc and b.Date_Reporting=a.Date_Reporting and b.Test_type=a.Test_type and b.Meas_Tech=a.Meas_Tech and b.Report_type=a.Report_type
								),0)
								/
								nullif((select sum(b.f_i) 
								from ['+@table+'_transpose_step1] b
								where b.entidad=a.entidad and b.mnc=a.mnc and b.Date_Reporting=a.Date_Reporting and b.Test_type=a.Test_type and b.Meas_Tech=a.Meas_Tech and b.Report_type=a.Report_type
								),0) as x_m
				into ['+@table+'_transpose]
				from ['+@table+'_transpose_step1] a 
				group by a.mnc,a.entidad,a.Date_Reporting,a.Test_type,a.Meas_Tech,a.Report_type
				'
--print @SQLString
EXECUTE sp_executesql @SQLString

--select * from _Desviaciones_Voice_transpose


SET @SQLString= N'	exec sp_lcc_dropifexists ''_Resultados_STDV_step1''
					select	b.entidad,
							b.mnc,
							b.Date_Reporting,
							b.Report_type,
							b.Test_type,
							b.Meas_Tech,
							sum(power(b.x_i-a.x_m,2)*b.f_i) as desv_step1_num,
							case when a.N=1 then a.N else a.N-1 end as desv_step1_den
					into _Resultados_STDV_step1
					from ['+@table+'_transpose_step1] b,
					['+@table+'_transpose] a 
					where a.mnc=b.mnc and a.entidad=b.entidad and a.Date_Reporting=b.Date_Reporting and a.Test_type=b.Test_type and a.Meas_Tech=b.Meas_Tech and b.Report_type=a.Report_type
					group by b.entidad,b.mnc,b.Date_Reporting,b.Report_type,b.Test_type,b.Meas_Tech,a.N'

--print @SQLString
EXECUTE sp_executesql @SQLString

--select * from _Resultados_STDV_step1


SET @SQLString= N'
				insert into _Resultados_STDV
				select	b.entidad,
						b.mnc, 
						b.Date_Reporting,
						b.Report_type,
						b.Test_type,
						b.Meas_Tech,
						(sqrt((b.desv_step1_num)/nullif((b.desv_step1_den),0))) as Resultado_desviacion
				from   ['+@table+'_transpose] a,
					_Resultados_STDV_step1 b
				where a.mnc=b.mnc and a.entidad=b.entidad and a.Date_Reporting=b.Date_Reporting and a.Test_type=b.Test_type and a.Meas_Tech=b.Meas_Tech and b.Report_type=a.Report_type
				group by b.entidad,
						b.mnc, 
						b.Date_Reporting,
						b.Test_type,
						b.Report_type,
						b.Meas_Tech,
						b.desv_step1_num,
						b.desv_step1_den'

--print @SQLString
EXECUTE sp_executesql @SQLString

--select * from _Resultados_STDV order by 1,2
-----------------------------------------------------------------------------------
------ Limpieza de tablas temporales
SET @SQLString= N'
				 exec sp_lcc_dropifexists '''+@table+'_transpose''' +
			    'exec sp_lcc_dropifexists '''+@table+'_transpose_step1''' + 
				'exec sp_lcc_dropifexists ''_Resultados_STDV_step1'''

EXECUTE sp_executesql @SQLString
